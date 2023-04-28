global class DPM_EmployeesTerminationBatch implements Database.Batchable<sObject>,Database.AllowsCallouts,Database.Stateful{    
    public Set<Id> setAccountIds;
    public set<Id> lstUserIdsToDeactivateAll;
    public list<string> listOfErrors;
    public list<RE_Person_Role__c> updatedPersonRole=new List<RE_Person_Role__c>();
    public list<DPM_EmployeeJobPosition__c> lstJPsToTerminate;
    public static final string strVolvoCorporateAccountName = 'Volvo Car USA LLC';
    public static final List<String> lstNamesToIgnore = new List<String>{'Blueprism'};
    
    public DPM_EmployeesTerminationBatch(Set<Id> setAccountIds) {      
        this.setAccountIds = setAccountIds;
        lstUserIdsToDeactivateAll = new set<Id>();
        listOfErrors = new list<string>();
        //updatedPersonRole = new list<RE_Person_Role__c>();
        lstJPsToTerminate = new list<DPM_EmployeeJobPosition__c>();
    }
    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id,RE_Account__c,RE_Account__r.Org_non_activated__c,RE_Contact__c,RE_Contact__r.Name,RE_Psn_NonActive_Date__c,DPM_CDS_Id__c,'
            +' (SELECT Id, DPM_Position_End_Date__c,DPM_Account__r.Org_non_activated__c,DPM_Contact__r.Name FROM DPM_Job_Positions__r WHERE DPM_Position_End_Date__c = NULL) FROM RE_Person_Role__c WHERE RE_Account__c IN: setAccountIds AND RE_Psn_NonActive_Date__c = NULL AND RE_Contact__r.FirstName NOT IN :lstNamesToIgnore AND RE_Contact__r.Account.Name!=:strVolvoCorporateAccountName';
        return Database.getquerylocator(query);
    }
    global void execute(Database.BatchableContext BC, List<RE_Person_Role__c> lstExistingPRs){
        Set<Id> setContactIdsToConsider = new Set<Id>();
        Set<Id> setContactIdsForUserDeactivation = new Set<Id>();
        Set<String> setCDSIDsToBeDeactivated = new Set<String>();
        for(RE_Person_Role__c personRoleToBeTerminated : lstExistingPRs) {
            personRoleToBeTerminated.RE_Psn_NonActive_Date__c = personRoleToBeTerminated.RE_Account__r.Org_non_activated__c; 
            lstJPsToTerminate.addAll(personRoleToBeTerminated.DPM_Job_Positions__r);
            setContactIdsToConsider.add(personRoleToBeTerminated.RE_Contact__c);
            setCDSIDsToBeDeactivated.add(personRoleToBeTerminated.DPM_CDS_Id__c);
        }
        for(DPM_EmployeeJobPosition__c jobPositionsToBeEnded : lstJPsToTerminate) {
            jobPositionsToBeEnded.DPM_Position_End_Date__c = jobPositionsToBeEnded.DPM_Account__r.Org_non_activated__c;
        }
        //Check if contact has any active Person Roles
        List<RE_Person_Role__c>  lstPersonRolesToUpdate = new List<RE_Person_Role__c>();
        for(Contact c : [SELECT Id,Cds_Id__c,(SELECT Id,DPM_CDS_Id__c,RE_Psn_Active_Date__c FROM Person_Roles__r WHERE RE_Psn_Active__c = TRUE AND DPM_CDS_Id__c NOT IN :setCDSIDsToBeDeactivated ORDER BY RE_Psn_Active_Date__c LIMIT 1) FROM Contact WHERE Id IN :setContactIdsToConsider]) {
            if(c.Person_Roles__r.isEmpty()) {
                //no active Person Roles
                setContactIdsForUserDeactivation.add(c.Id);                
            } else {
                //Primary CDSID Switch
                if(c.Cds_Id__c != null){
                    if(setCDSIDsToBeDeactivated.contains(c.Cds_Id__c)) {
                        DPM_PersonnelMasterServices.DPM_LogData logData = DPM_PersonnelMasterServices.callIDMToUpdateEmployeeData(c.Cds_Id__c,c.Person_Roles__r[0].DPM_CDS_Id__c,c.Cds_Id__c,'CDSIDSwitch','');
                        if(logData.intResponseCode!=NULL && !DPM_PersonnelMasterServices.lstValidResponseCodes.contains(logData.intResponseCode)) {
                            listOfErrors.add('Integration Failure (IDM): Endpoint: '+logData.objDPMLog.DPM_Callout_Endpoint__c+' Request: '+logData.objDPMLog.DPM_Request_Body__c+' Response: '+logData.objDPMLog.DPM_Response_Body__c);
                        }
                        //Remove CDSIDs that are part of CDSID switch
                        setCDSIDsToBeDeactivated.remove(c.Cds_Id__c);
                    } 
                }
            }
        }
        //Send request to deactivate CDSIDs that were not part of CDSID switch
        if(!setCDSIDsToBeDeactivated.isEmpty()) {
            for(String strCDSID : setCDSIDsToBeDeactivated) {
                DPM_PersonnelMasterServices.DPM_LogData logData = DPM_PersonnelMasterServices.callIDMToUpdateEmployeeData(strCDSID,'false','true','cdsstatus','');
                if(logData.intResponseCode!=NULL && !DPM_PersonnelMasterServices.lstValidResponseCodes.contains(logData.intResponseCode)) {
                    listOfErrors.add('Integration Failure (IDM): Endpoint: '+logData.objDPMLog.DPM_Callout_Endpoint__c+' Request: '+logData.objDPMLog.DPM_Request_Body__c+' Response: '+logData.objDPMLog.DPM_Response_Body__c);
                }
            }
        }
        if(!setContactIdsForUserDeactivation.isEmpty()) {
            Map<Id,User> mapUserIdToUser = new Map<Id,User>([SELECT Id FROM User WHERE ContactId IN :setContactIdsForUserDeactivation]);
            lstUserIdsToDeactivateAll.addAll(mapUserIdToUser.keySet());
        }
        if(!lstExistingPRs.isEmpty()) {
            updatedPersonRole.addAll(lstExistingPRs);
        }
    }
    global void finish(Database.BatchableContext BC){
        //if(!lstUserIdsToDeactivateAll.isEmpty()) {
            System.enqueueJob(new QueueUserDeactivationClass(lstUserIdsToDeactivateAll,updatedPersonRole,lstJPsToTerminate,listOfErrors,setAccountIds));
        //}   
    }
    public class QueueUserDeactivationClass implements Queueable {
        set<Id> userIds;
        list<String> listOfErrors;
        list<RE_Person_Role__c> lstExistingPRs;
        list<DPM_EmployeeJobPosition__c> lstJPsToTerminate;
        Set<Id> setAccountIds;
        public QueueUserDeactivationClass(set<Id> userIds,list<RE_Person_Role__c> lstExistingPRs,list<DPM_EmployeeJobPosition__c> lstJPsToTerminate,list<String> listOfErrors,Set<Id> setAccountIds) {
            this.userIds = userIds;
            this.lstExistingPRs = lstExistingPRs;
            this.lstJPsToTerminate = lstJPsToTerminate;
            this.setAccountIds = setAccountIds;
            this.listOfErrors = listOfErrors;
        }
        public void execute(QueueableContext context) {
            if(!userIds.isEmpty()) {
            	DPM_PersonnelMasterServicesExt.deactivatePortalBuysellUser(userIds);
            }
            if(!lstExistingPRs.isEmpty()) {
                Database.SaveResult[] srListOfTermPrs = Database.update(lstExistingPRs, false);
                for (Integer i = 0; i < srListOfTermPrs.size(); i++) {
                    if ( !srListOfTermPrs.get(i).isSuccess() ) {
                        String errorMessagePRs = lstExistingPRs[i].RE_Contact__r.Name+'('+lstExistingPRs[i].Id+')'+'-';
                        for(Database.Error theError : srListOfTermPrs[i].getErrors() ) {
                            errorMessagePRs += theError.getMessage();
                        }
                        if(errorMessagePRs != ''){
                            listOfErrors.add(errorMessagePRs);
                        }
                    }                    
                }
            }
            if(!lstJPsToTerminate.isEmpty()) {
                Database.SaveResult[] srListOfTermJPs = Database.update(lstJPsToTerminate, false);
                for (Integer i = 0; i < srListOfTermJPs.size(); i++) {
                    if ( !srListOfTermJPs.get(i).isSuccess() ) {
                        String errorMessagePRs = lstJPsToTerminate[i].DPM_Contact__r.Name+'('+lstJPsToTerminate[i].Id+')'+'-';
                        for(Database.Error theError : srListOfTermJPs[i].getErrors() ) {
                            errorMessagePRs += theError.getMessage();
                        }
                        if(errorMessagePRs != ''){
                            listOfErrors.add(errorMessagePRs);
                        }
                    }                    
                }
            }  
            map<id,account> mapOfAccount = new map<id,account>([select id,Retailer__c ,  name from account where id IN:setAccountIds]);
            String descriptionStr = '';
            Integer intCount=0;
            if(!listOfErrors.isEmpty()) {
                Integer maxSize = 32000;
                Boolean blnCreateSecondCase = false;
                for(String strError : listOfErrors) {
                    intCount++;
                    descriptionStr += intCount+'. '+strError+'\r\n';
                    if(descriptionStr.length() > maxSize) {
                        blnCreateSecondCase = true;
                        break;
                    }
                }
                if(blnCreateSecondCase) {
                    String descriptionStrNew = '';
                    for(integer i=intCount;i<listOfErrors.size();i++) {
                        descriptionStrNew += (i+1)+'. '+listOfErrors[i]+'\r\n';                    
                    }
                    
                    DPM_PersonnelMasterServicesExt.caseCreationBuySell('Termination Request - 1',descriptionStr,mapOfAccount.values()[0].id,NULL,mapOfAccount);
                    DPM_PersonnelMasterServicesExt.caseCreationBuySell('Termination Request - 2',descriptionStrNew,mapOfAccount.values()[0].id,NULL,mapOfAccount);
                } else {
                    DPM_PersonnelMasterServicesExt.caseCreationBuySell('Termination Request - 1',descriptionStr,mapOfAccount.values()[0].id,NULL,mapOfAccount);
                }           
            } else {
                DPM_PersonnelMasterServicesExt.sendSuccessErrorBuySellMailTermination('Success',mapOfAccount.values()[0].id,NULL,NULL,mapOfAccount,'');
            }
        }
    }
}