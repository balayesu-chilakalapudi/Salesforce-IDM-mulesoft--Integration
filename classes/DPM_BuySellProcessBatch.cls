global class DPM_BuySellProcessBatch implements Database.Batchable<sObject>,Database.AllowsCallouts,Database.Stateful{    
    public List<Id> lstPersonRoleIds;
    public String strSellerId;
    public String strBuyerId;
    public Date dtOriginalAppointmentDate;
    public list<string> listOfErrors;
    public List<RE_Person_Role__c> lstExistingPRsQ;
    public List<RE_Person_Role__c> lstPRsToBeInserted;
    public List<DPM_EmployeeJobPosition__c> lstOldJobPositions;
    public static final string strVolvoCorporateAccountName = 'Volvo Car USA LLC';
    public static final List<String> lstNamesToIgnore = new List<String>{'Blueprism'};
    
    public DPM_BuySellProcessBatch(List<Id> lstPersonRoleIds,String strBuyerId,String strSellerId,Date dtOriginalAppointmentDate) {      
        this.lstPersonRoleIds = lstPersonRoleIds;
        this.strBuyerId = strBuyerId;
        this.strSellerId = strSellerId;
        this.dtOriginalAppointmentDate = dtOriginalAppointmentDate;
        listOfErrors = new list<string>();
        lstExistingPRsQ = new List<RE_Person_Role__c>();
        lstPRsToBeInserted = new List<RE_Person_Role__c>();
        lstOldJobPositions = new List<DPM_EmployeeJobPosition__c>(); 
    }
    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id,RE_Contact__r.FirstName,RE_Contact__r.LastName,RE_Account__r.Name,DPM_Work_Email__c,DPM_DMS_Id__c,DPM_Work_Phone__c,RE_Account__c,RE_Contact__c,RE_Contact__r.Name,RE_Contact__r.Cds_Id__c,DPM_CDS_Id__c,RE_Contact__r.email,RE_IsAdmin__c, DPM_Owner__c, DPM_Owner_Title__c, RE_Pos_Active_Date__c, RE_Pos_NonActive_Date__c,'
            +' RE_Position_Active__c, DPM_Primary__c,RE_Contact__r.Account_Country__c, RE_Psn_Active__c, RE_Psn_Active_Date__c, RE_PsnId__c, RE_Psn_NonActive_Date__c, RE_Psn_Pos_Abbr__c, RE_User__c,'
            +' (SELECT Id, DPM_Account__c, DPM_Contact__c, DPM_Person_Role__c, DPM_Position_End_Date__c, DPM_Position_Start_Date__c, DPM_Position_Title__c, DPM_Primary_Position__c FROM DPM_Job_Positions__r WHERE DPM_Position_End_Date__c = NULL) FROM RE_Person_Role__c WHERE Id IN: lstPersonRoleIds AND RE_Psn_Active__c = TRUE AND RE_Contact__r.FirstName NOT IN :lstNamesToIgnore AND RE_Contact__r.Account.Name!=:strVolvoCorporateAccountName';
        return Database.getquerylocator(query);
    }
    global void execute(Database.BatchableContext BC, List<RE_Person_Role__c> lstExistingPRs){
        Set<String> contactCDSIds = new Set<String>();        
        Set<Id> buysellaccountIds = new Set<Id>{strSellerId,strBuyerId};
            Map<Id,Account> accountMap = new Map<Id,Account>([Select Id,DPM_Global_Retailer_Code__c,ShippingStreet,ShippingCity,ShippingState,ShippingCountry,ShippingPostalCode FROM Account where Id IN :buysellaccountIds]);
        for(RE_Person_Role__c personRole : lstExistingPRs) {
            //personRole.RE_Persona__c ='testforError';// for test purpose only
            lstPRsToBeInserted.add(new RE_Person_Role__c(
                RE_Account__c = strBuyerId,
                RE_Contact__c = personRole.RE_Contact__c,
                DPM_DMS_Id__c = personRole.RE_Contact__r.Account_Country__c !='Mex'?personRole.DPM_DMS_Id__c:'',  
                RE_User__c = personRole.RE_User__c,
                RE_Psn_Active_Date__c = dtOriginalAppointmentDate,
                RE_IsAdmin__c = personRole.RE_IsAdmin__c,
                RE_Psn_Active__c = TRUE,
                DPM_CDS_Id__c = personRole.DPM_CDS_Id__c,
                DPM_Primary__c = personRole.DPM_Primary__c,
                DPM_Work_Email__c = personRole.DPM_Work_Email__c,
                DPM_Work_Phone__c = personRole.DPM_Work_Phone__c,
                DPM_Work_Address_Street__c = accountMap.get(strBuyerId).ShippingStreet,
                DPM_Work_Address_City__c = accountMap.get(strBuyerId).ShippingCity,
                DPM_Work_Address_State__c = accountMap.get(strBuyerId).ShippingState,
                DPM_Work_Address_Country__c = accountMap.get(strBuyerId).ShippingCountry,
                DPM_Work_Address_Zip_Postal_Code__c = accountMap.get(strBuyerId).ShippingPostalCode,
                DPM_BuySell__c = TRUE
            ));
            contactCDSIds.add(personRole.DPM_CDS_Id__c);
            for(DPM_EmployeeJobPosition__c jobObj :personRole.DPM_Job_Positions__r){
                lstOldJobPositions.add(jobObj);
            }
            
            
            //make work email invalid for selling store
            if(personRole.DPM_Work_Email__c != null){
                personRole.DPM_Work_Email__c = personRole.DPM_Work_Email__c+'.invalid';
            }
            personRole.DPM_CDS_Id__c = NULL;
            personRole.DPM_Primary__c = FALSE;
            personRole.RE_Psn_NonActive_Date__c = dtOriginalAppointmentDate;
        }
        lstExistingPRsQ.addAll(lstExistingPRs);
        if(!contactCDSIds.IsEmpty()){
            for(String cdsId : contactCDSIds) {
                if(cdsId != null){
                    DPM_PersonnelMasterServices.DPM_LogData logData = DPM_PersonnelMasterServices.callIDMToUpdateEmployeeData(cdsId,
                                                                                                                              accountMap.get(strBuyerId).DPM_Global_Retailer_Code__c,
                                                                                                                              accountMap.get(strSellerId).DPM_Global_Retailer_Code__c,
                                                                                                                              'buySell',''); 
                    if(logData!= null && logData.intResponseCode  != 204 && logData.intResponseCode  !=200 && !logData.strResponse.contains('Success') && logData.objDPMLog == null){
                        listOfErrors.add('Integration Failure (IDM): Endpoint: '+logData.objDPMLog.DPM_Callout_Endpoint__c+' Request: '+logData.objDPMLog.DPM_Request_Body__c+' Response: '+logData.objDPMLog.DPM_Response_Body__c); 
                    } 
                }
            }
        }
    }
    global void finish(Database.BatchableContext BC){
        if(!lstExistingPRsQ.isEmpty() && !lstPRsToBeInserted.isEmpty() && !lstOldJobPositions.isEmpty()) {
            System.enqueueJob(new QueuePersonRoleupdationClass(lstExistingPRsQ,lstPRsToBeInserted,lstOldJobPositions,listOfErrors,strSellerId,strBuyerId,dtOriginalAppointmentDate));
        }  
    }
    public class QueuePersonRoleupdationClass implements Queueable {
        List<RE_Person_Role__c> lstExistingPRsQ;
        List<RE_Person_Role__c> lstPRsToBeInserted;
        List<DPM_EmployeeJobPosition__c> lstOldJobPositions;
        list<string>listOfErrors;
        string strSellerId;
        string strBuyerId;
        date dtOriginalAppointmentDate;
        public QueuePersonRoleupdationClass(List<RE_Person_Role__c> prOld,List<RE_Person_Role__c> prNew,List<DPM_EmployeeJobPosition__c> jbOld,list<string>listOfErrors,string strSellerId,string strBuyerId,date dtOriginalAppointmentDate) {
            this.lstExistingPRsQ = prOld;
            this.lstPRsToBeInserted = prNew;
            this.lstOldJobPositions = jbOld;
            this.listOfErrors = listOfErrors;
            this.strSellerId = strSellerId;
            this.strBuyerId = strBuyerId;
            this.dtOriginalAppointmentDate = dtOriginalAppointmentDate;
        }
        public void execute(QueueableContext context) {
            Savepoint sp = Database.setSavepoint();
            try {
                if(listOfErrors.isEmpty()){
                    List<DPM_EmployeeJobPosition__c> lstJPsToBeInserted = new List<DPM_EmployeeJobPosition__c>();
                    set<id> setIdOfInsertedPRs = new set<id>();
                    if(!lstPRsToBeInserted.isEmpty()){
                        Database.SaveResult[] srListOfTermPrs = Database.insert(lstPRsToBeInserted, false);
                        for (Integer i = 0; i < srListOfTermPrs.size(); i++) {
                            if ( !srListOfTermPrs.get(i).isSuccess() ) {
                                String errorMessagePRs = lstPRsToBeInserted[i].RE_Contact__r.Name+'('+lstPRsToBeInserted[i].Id+')'+'-';
                                for(Database.Error theError : srListOfTermPrs[i].getErrors() ) {
                                    errorMessagePRs += theError.getMessage();
                                }
                                if(errorMessagePRs != ''){
                                    listOfErrors.add(errorMessagePRs);
                                }
                            }
                            else{
                                setIdOfInsertedPRs.add(srListOfTermPrs[i].getId());
                            }
                        } 
                        
                        //In this case, one person role per contact will be applicable as there can be one active tenure of an employee on the same store
                        Map<Id,Id> mapContactIdToPR = new Map<Id,Id>();
                        for(RE_Person_Role__c personRoleNew : lstPRsToBeInserted) {
                            mapContactIdToPR.put(personRoleNew.RE_Contact__c,personRoleNew.Id);
                        }
                        for(DPM_EmployeeJobPosition__c oldJobPosition : lstOldJobPositions) {
                            lstJPsToBeInserted.add(new DPM_EmployeeJobPosition__c(
                                DPM_Contact__c = oldJobPosition.DPM_Contact__c,
                                DPM_Account__c = strBuyerId,
                                DPM_Primary_Position__c = oldJobPosition.DPM_Primary_Position__c,
                                DPM_Position_Start_Date__c = dtOriginalAppointmentDate,
                                DPM_Position_Title__c = oldJobPosition.DPM_Position_Title__c,
                                DPM_Person_Role__c = mapContactIdToPR.get(oldJobPosition.DPM_Contact__c)
                            ));
                            oldJobPosition.DPM_Position_End_Date__c = dtOriginalAppointmentDate;
                        }
                        Database.SaveResult[] srListOfJPs = Database.insert(lstJPsToBeInserted, false);
                        system.debug('lstJPsToBeInserted-=-=>'+lstJPsToBeInserted);
                        for (Integer i = 0; i < srListOfJPs.size(); i++) {
                            if ( !srListOfJPs.get(i).isSuccess() ) {
                                String errorMessagePRs = lstJPsToBeInserted[i].DPM_Contact__r.Name+'('+lstJPsToBeInserted[i].Id+')'+'-';
                                for(Database.Error theError : srListOfJPs[i].getErrors() ) {
                                    errorMessagePRs += theError.getMessage();
                                }
                                if(errorMessagePRs != ''){
                                    listOfErrors.add(errorMessagePRs);
                                }
                            }                    
                        }
                        //3. Update old Person Roles - terminate them
                        Database.SaveResult[] srListOfOldPRs = Database.update(lstExistingPRsQ, false);
                        String errorMessagePrs = '';
                        for ( Integer i = 0; i < srListOfOldPRs.size(); i++ ) {
                            if ( !srListOfOldPRs.get(i).isSuccess() ) {
                                errorMessagePrs += lstExistingPRsQ[i].RE_Contact__r.Name+'('+lstExistingPRsQ[i].Id+')'+'-';
                                for(Database.Error theError : srListOfOldPRs[i].getErrors() ) {
                                    errorMessagePrs += theError.getMessage();
                                }
                            }
                            if(errorMessagePrs != ''){
                                listOfErrors.add(errorMessagePrs);
                            }
                        }
                        //4. Update old Job Positions - end them  
                        Database.SaveResult[] srListOfOldJPs = Database.update(lstOldJobPositions, false);
                        String errorMessageJps = '';
                        for ( Integer i = 0; i < srListOfOldJPs.size(); i++ ) {
                            if ( !srListOfOldJPs.get(i).isSuccess() ) {
                                errorMessageJps += lstOldJobPositions[i].DPM_Contact__r.Name+'('+lstOldJobPositions[i].Id+')'+'-';
                                for(Database.Error theError : srListOfOldJPs[i].getErrors() ) {
                                    errorMessageJps += theError.getMessage();
                                }
                            }
                            if(errorMessageJps != ''){
                                listOfErrors.add(errorMessageJps);
                            }
                        }
                    }
                }
                system.debug('lstOldJobPositions-=-=>'+lstOldJobPositions);
            } catch(Exception e) {
                System.debug(e+'\n'+e.getStackTraceString()+' line no.--> '+ e.getLineNumber());
                Database.rollback(sp);
            }
            set<string> setOfIds = new set<String>{strSellerId,strBuyerId};
                map<id,account> mapOfAccount = new map<id,account>([select id,ShippingStreet,ShippingCity,ShippingState,ShippingPostalCode,ShippingCountry,Retailer__c,name from account where id IN:setOfIds]);
            String descriptionStr = '';
            Integer intCount=0;
            system.debug('listOfErrors-=-=>'+listOfErrors.size());
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
                    
                    DPM_PersonnelMasterServicesExt.caseCreationBuySell('Transfer Request - 1',descriptionStr,strSellerId,strBuyerId,mapOfAccount);
                    DPM_PersonnelMasterServicesExt.caseCreationBuySell('Transfer Request - 2',descriptionStrNew,strSellerId,strBuyerId,mapOfAccount);
                } else {
                    DPM_PersonnelMasterServicesExt.caseCreationBuySell('Transfer Request - 1',descriptionStr,strSellerId,strBuyerId,mapOfAccount);
                }           
            } else {
                DPM_PersonnelMasterServicesExt.sendSuccessErrorBuySellMail('Success',strSellerId,strBuyerId,NULL,mapOfAccount,'',lstExistingPRsQ);
            }
        }
    } 
}