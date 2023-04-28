public class DPM_PersonnelMasterServices { 
    /*
* Name      : DPM_PersonnelMasterServices
* Purpose   : Common services class for DPM.  
* Author    : Krishna Singh
* Date      : 17-Aug-2020
* 
* */
    public static final String strEmailToRetEmpTemplate = 'DPM_Notification_Retailer_Employee_Self_Reg';
    public static final String strSiteNameRetEmpForm = 'RetailerEmployeeForm';
    public static final String strDPMCustomMetadataName = 'DPM_Employee';
    public static final Id retailerEmployeeRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Retailer Employee').getRecordTypeId();
    public static final Id supplierEmployeeRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Supplier Employee').getRecordTypeId();
    private static final Integer intTimeout = 120000;
    private static final string strIntegrationType = 'DPM IDM POST';    
    private static final string strEncryptionEndPointType = 'DPM Encryption';
    private static final string strDecryptionEndPointType = 'DPM Decryption';
    private static final string strVolvoCorporateAccountName = 'Volvo Car USA LLC';
    private static final List<String> lstNamesToIgnore = new List<String>{'Blueprism'};
        public static boolean contexec = true;
    public static boolean blnTypeConversion = false;
    public static final List<Integer> lstValidResponseCodes = new List<Integer>{200,201,202,203,204};
        public static List<String> getPicklistValuesFromObject(String strFieldName, String strObjectName, Boolean blnAddBlank) {
            List<String> options = new List<String>();
            Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
            Map<String,Schema.SObjectField> field_map = gd.get(strObjectName.toLowerCase()).getDescribe().fields.getMap();        
            List<Schema.PicklistEntry> picklistValues = field_map.get(strFieldName).getDescribe().getPickListValues();       
            if(blnAddBlank == true){
                options.add('--None--');
            }       
            for (Schema.PicklistEntry pv : picklistValues) {
                options.add(pv.getValue());            
            }        
            return options;
        }
    public static Account getDefaultAccount() {
        RE_Community_User_Settings__c currentSettings = RE_CurrentUser.userSettings;
        if(currentSettings != NULL && currentSettings.RE_Default_Account_Id__c != NULL) {
            return [SELECT Id,Name,Retailer__c,Country__r.Name,Org_activated__c FROM Account WHERE Id = :currentSettings.RE_Default_Account_Id__c];
        }
        return NULL;
    }
    public static void sendEmailToRetEmp(Id idDPMEmployee) {        
        EmailTemplate emailTemplate_NotifyRetEmp = [select Id, Body, DeveloperName, Subject, HTMLValue from EmailTemplate where DeveloperName = :strEmailToRetEmpTemplate];
        DPM_Employee__c dpmEmployee = [SELECT Id, CreatedById, DPM_Record_Origin__c, DPM_Account__c,DPM_Account__r.Name,DPM_Account__r.Org_activated__c, DPM_Account__r.ShippingStreet, DPM_Account__r.ShippingCity, 
                                       DPM_Account__r.ShippingCountry, DPM_Account__r.ShippingPostalCode, DPM_Email__c, DPM_Legal_First_Name__c, 
                                       DPM_Last_Name__c, CreatedBy.Email, DPM_Account__r.ShippingState FROM DPM_Employee__c WHERE Id = :idDPMEmployee];
        
        OrgWideEmailAddress owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'sfdc@volvocars.com' LIMIT 1];
        String strEmailBody = emailTemplate_NotifyRetEmp.HTMLValue;   
        strEmailBody = strEmailBody.replace('{Link}',encryptRecordIdAndGenerateLink(dpmEmployee.Id));
        strEmailBody = strEmailBody.replace('{Link}',encryptRecordIdAndGenerateLink(dpmEmployee.Id));
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<String> strSendTo = new List<String>();
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        strSendTo.add(String.valueOf(dpmEmployee.DPM_Email__c));
        mail.setWhatId(dpmEmployee.Id); 
        mail.setToAddresses(strSendTo);
        mail.setSaveAsActivity(false);    
        mail.setHtmlBody(resolveFields(strEmailBody,dpmEmployee));
        mail.setSubject(emailTemplate_NotifyRetEmp.Subject.replace('{AccountName}',dpmEmployee.DPM_Account__r.Name));
        mail.setOrgWideEmailAddressId(owea.Id);
        mails.add(mail);
        if(!mails.isEmpty()){
            Messaging.SendEmail(mails);
        }
    }
    private static string resolveFields(String strEmailBody,DPM_Employee__c dpmEmployee) {        
        strEmailBody = strEmailBody.replace('{Name}',dpmEmployee.DPM_Legal_First_Name__c+' '+dpmEmployee.DPM_Last_Name__c);
        strEmailBody = strEmailBody.replace('{AccountName}',dpmEmployee.DPM_Account__r.Name).replace('{AccountName}',dpmEmployee.DPM_Account__r.Name);
        String strAddress = (dpmEmployee.DPM_Account__r.ShippingStreet!=NULL?dpmEmployee.DPM_Account__r.ShippingStreet+'<br/>':'')
            +(dpmEmployee.DPM_Account__r.ShippingCity!=NULL?dpmEmployee.DPM_Account__r.ShippingCity+',&nbsp;':'')
            +(dpmEmployee.DPM_Account__r.ShippingState!=NULL?dpmEmployee.DPM_Account__r.ShippingState+'&nbsp;':'')
            +(dpmEmployee.DPM_Account__r.ShippingPostalCode!=NULL?dpmEmployee.DPM_Account__r.ShippingPostalCode+'&nbsp;'+'<br/>':'')
            +(dpmEmployee.DPM_Account__r.ShippingCountry!=NULL?dpmEmployee.DPM_Account__r.ShippingCountry+'<br/>':'');
        strEmailBody = strEmailBody.replace('{AccountAddress}',strAddress);
        strEmailBody = strEmailBody.replace('{Logo}',Label.DMT_VolvoLogoURL); 
        return strEmailBody;
    }
    public static string encryptRecordIdAndGenerateLink(Id recordId) { 
        DPM_Configuration__mdt DPMConfig = getDPMConfigCustomMetadata();
        Blob blbIV = Blob.valueOf(DPMConfig.DPM_Initialization_Vector__c);
        Blob blbKey = Blob.valueOf(DPMConfig.DPM_Encryption_Key__c);
        Blob blbRecordId = Blob.valueOf(String.valueOf(recordId));
        Blob encryptedRecId = Crypto.encrypt('AES128', blbKey, blbIV, blbRecordId);        
        return DPMConfig.DPM_Site_URL__c+'?id='+EncodingUtil.urlEncode(EncodingUtil.base64Encode(encryptedRecId), 'UTF-8');
    }
    public static DPM_Employee__c decryptRecordIdAndCheckAccess(String strEncryptedId) {
        DPM_Configuration__mdt DPMConfig = getDPMConfigCustomMetadata();
        Blob blbIV = Blob.valueOf(DPMConfig.DPM_Initialization_Vector__c);
        Blob blbKey = Blob.valueOf(DPMConfig.DPM_Encryption_Key__c);
        Blob decryptedId = Crypto.decrypt('AES128', blbKey, blbIV, EncodingUtil.base64Decode(EncodingUtil.urlDecode(strEncryptedId ,'UTF-8')));
        //system.debug('decrypted id: '+decryptedId.toString());
        //check expiry - TODO
        String strRecordId = decryptedId.toString();
        List<DPM_Employee__c> lstDPMEmployee = new List<DPM_Employee__c>();
        lstDPMEmployee = [SELECT Id, DPM_Contact__r.MailingCity,DPM_Proficiency_1__c, DPM_Proficiency_2__c, DPM_Proficiency_3__c, DPM_Language_1__c, DPM_Language_2__c, DPM_Language_3__c,
                          CreatedById, DPM_Account__r.Name,DPM_Account__r.Org_activated__c, DPM_Account__r.Retailer__c, DPM_Email__c, DPM_Legal_First_Name__c, DPM_Status__c,
                          DPM_Gender__c,DPM_Other_Gender__c, DPM_SSN_SIN__c, DPM_Prefix__c, DPM_Middle_Name__c, DPM_Last_Name__c, DPM_Suffix__c, DPM_Preferred_First_Name__c,
                          DPM_Hire_Date__c, DPM_Race__c, DPM_Ethnicity__c, DPM_Owner__c,DPM_Contact__c,DPM_Contact__r.DPM_SSN__c,DPM_Owner_Title__c,DPM_Canadian_State__c,DPM_Mexican_State__c,DPM_Cell_Phone__c,DPM_City__c,DPM_Country__c,DPM_Home_Address_Street__c,
                          DPM_Home_Phone__c,DPM_US_State__c,DPM_Zipcode__c,DPM_Home_Address_Street_2__c,DPM_Retailer_Admin__c,DPM_Request_Type__c,DPM_Personal_Email__c,DPM_Employee_Type__c,
                          
                          (SELECT Id, DPM_End_Date__c, DPM_Primary__c, Name, DPM_Start_Date__c FROM DPM_Job_Positions__r),DPM_US_Military__c 
                          FROM DPM_Employee__c WHERE Id = :strRecordId];
        if(lstDPMEmployee.isEmpty()) {
            throw new AuraHandledException('This link has expired. Please contact your Admin.');
        } else {
            if(lstDPMEmployee[0].DPM_Status__c != 'Initiated') {
                throw new AuraHandledException('The employee registration form is not available.');
            }
        }
        return lstDPMEmployee[0];
    }
    public static DPM_Configuration__mdt getDPMConfigCustomMetadata() {
        DPM_Configuration__mdt DPMConfig =  [SELECT Id, DPM_Retailer_Codes_for_Access__c, DPM_Oracle_Decommission__c, DPM_Encryption_Key__c, DPM_Initialization_Vector__c, DPM_Site_URL__c,DPM_Additional_Accounts_for_Search__c FROM DPM_Configuration__mdt WHERE DeveloperName=:strDPMCustomMetadataName];
        return DPMConfig;
    }
    public static list<RE_Person_Role__c> getExistingEmployees(String strSessionSettings) {
        DPM_SessionSettings objsessionSettings = (DPM_SessionSettings) JSON.deserialize(strSessionSettings, DPM_SessionSettings.class);
        Account defaultAccount = getDefaultAccount();
        Id defaultAccountId = defaultAccount.Id;
        String strOrderBy = '';
        switch on objsessionSettings.sortBy {
            when 'Name' {
                strOrderBy = 'RE_Contact__r.LastName '+objsessionSettings.sortDirection+
                    ',RE_Contact__r.DPM_Preferred_First_Name__c '+objsessionSettings.sortDirection+
                    ',RE_Contact__r.FirstName';
            }
            when 'CDSID' {
                strOrderBy = 'RE_Contact__r.Cds_Id__c';
            }
            when 'Job_Position' {
                strOrderBy = 'RE_Employee_Position__c';
            }
            when 'Email' {
                strOrderBy = 'RE_Contact__r.Email';
            }
            when 'Hire_Date' {
                strOrderBy = 'RE_Psn_Active_Date__c';
            }
            when 'Admin' {
                strOrderBy = 'RE_IsAdmin__c';
            }
            when 'Owner' {
                strOrderBy = 'DPM_Owner__c';
            }
            when 'Owner_Title' {
                strOrderBy = 'DPM_Owner_Title__c';
            }
            when else {
                //Do Nothing
            }
        }        
        String strQuery = 'SELECT '+
            getEmployeeProfileFields()+
            ' FROM RE_Person_Role__c';
        String strWhereClause = ' WHERE RE_Account__c = :defaultAccountId AND RE_Psn_Active__c =true AND RE_Position_Active__c =true AND RE_Contact__r.FirstName NOT IN :lstNamesToIgnore AND RE_Contact__r.Account.Name!=:strVolvoCorporateAccountName';
        String strOrderClause = ' ORDER BY '+strOrderBy+' '+objsessionSettings.sortDirection+' NULLS LAST';
        String strLimitClause='';
        if(objsessionSettings.showViewMore) {
            strLimitClause = ' Limit '+objsessionSettings.intLimit+' OFFSET '+objsessionSettings.intOffset;
        }
        if(objsessionSettings.filterBy == 'Job_Position' && objsessionSettings.filterString != '') {
            strWhereClause+=' AND RE_Employee_Position__c LIKE \'%'+objsessionSettings.filterString+'%\'';
        }
        list<RE_Person_Role__c> lstPersonRolesToReturn = new list<RE_Person_Role__c>();
        List<DPM_Employee__c> lstDPMEmployees = new List<DPM_Employee__c>();
        List<Id> lstDPMEmployeeContactIds = new List<Id>();
        lstDPMEmployees = [SELECT Id,DPM_Contact__c FROM DPM_Employee__c WHERE DPM_Account__c = :defaultAccountId AND DPM_Employee_Type__c = 'Retailer' AND DPM_Status__c != 'Completed' AND DPM_Contact__c <> NULL];
        if(!lstDPMEmployees.isEmpty()) {
            for(DPM_Employee__c dpmEmployee : lstDPMEmployees) {
                lstDPMEmployeeContactIds.add(dpmEmployee.DPM_Contact__c);
            }            
        }
        system.debug('full Query-->'+strQuery+strWhereClause+strOrderClause+strLimitClause);
        for(RE_Person_Role__c personRole : database.query(strQuery+strWhereClause+strOrderClause+strLimitClause)) {
            if(lstDPMEmployeeContactIds.isEmpty() || !lstDPMEmployeeContactIds.contains(personRole.RE_Contact__c)) {
                lstPersonRolesToReturn.add(personRole);
            }
        }
        return lstPersonRolesToReturn;
    }
    public static DPM_SearchResults searchEmployees(String strSessionSettings, String strSearchFields) {
        System.debug('strSearchFields::'+strSearchFields);
        DPM_SessionSettings objsessionSettings = (DPM_SessionSettings) JSON.deserialize(strSessionSettings, DPM_SessionSettings.class);
        DPM_SearchEmployee objsearchFields = (DPM_SearchEmployee) JSON.deserialize(strSearchFields, DPM_SearchEmployee.class);
        DPM_SearchResults dpmSearchResults = new DPM_SearchResults();
        system.debug('objsearchFields-=-'+objsearchFields);
        system.debug('objsessionSettings-=-'+objsessionSettings);
        system.debug('objsessionSettings.sortBy-----'+objsessionSettings.sortBy);
        String strOrderBy = '';
        String strChildOrderBy='';
        switch on objsessionSettings.sortBy {
            when 'Name' {
                strOrderBy = 'RE_Contact__r.LastName '+objsessionSettings.sortDirection+
                    ',RE_Contact__r.DPM_Preferred_First_Name__c '+objsessionSettings.sortDirection+
                    ',RE_Contact__r.FirstName';
                strChildOrderBy = 'DPM_Person_Role__r.RE_Contact__r.LastName '+objsessionSettings.sortDirection+
                    ',DPM_Person_Role__r.RE_Contact__r.DPM_Preferred_First_Name__c '+objsessionSettings.sortDirection+
                    ',DPM_Person_Role__r.RE_Contact__r.FirstName';
            }
            when 'Store' {
                strOrderBy = 'RE_Account__r.Name';
                strChildOrderBy='DPM_Person_Role__r.RE_Account__r.Name';
            }
            when 'Job_Position'{
                strChildOrderBy = 'DPM_Position_Title__c';
            }
            when 'RE_Psn_Active__c'{
                strOrderBy='RE_Psn_Active__c';
                strChildOrderBy='DPM_Person_Role__r.RE_Psn_Active__c';
            }
            when 'Position_Start_Date'{
                strChildOrderBy='DPM_Position_Start_Date__c';
            }
            when 'Work_Email'{
                strOrderBy='RE_Contact__r.Cds_Id__c';
                strChildOrderBy='DPM_Person_Role__r.RE_Contact__r.Email';
            }
            when 'Retailer_Admin'{
                strOrderBy='RE_IsAdmin__c';
            }
            when 'Owner'{
                strOrderBy='DPM_Owner__c';
            }
            when 'country'{
                strOrderBy='RE_Contact__r.MailingCountry';
                strChildOrderBy='DPM_Person_Role__r.RE_Contact__r.MailingCountry';
            }
            when else {
                //Do Nothing
            }
        }        
        String strQuery = 'SELECT ';
        String strLimitClause='';     
        
        if(!objsearchFields.fromPortal){
            system.debug('i am in--='+objsearchFields.jobPosition);
            if(!objsessionSettings.skipOffset && 
               objsessionSettings.showViewMore) {
                   strLimitClause = ' Limit '+objsessionSettings.intLimit+' OFFSET '+objsessionSettings.intOffset;
               }
            strQuery+=getEmployeeProfileFields();
            strQuery+=' FROM RE_Person_Role__c';
            String strWhereClause = ' WHERE ',strWhereClauseInitial = ' WHERE ';
            List<String> lstWhereClauses = new List<String>();
            String strFirstNameWhereClause,strLastNameWhereClause;
            if(!String.isEmpty(objsearchFields.firstName)) {
                strFirstNameWhereClause = '((RE_Contact__r.DPM_Firstname_Soundex__c = \''+DPM_Soundex.toSoundex(objsearchFields.firstName)+'\')';
                strFirstNameWhereClause += ' OR (RE_Contact__r.FirstName = \''+String.escapeSingleQuotes(objsearchFields.firstName)+'\'))';
            }
            if(!String.isEmpty(objsearchFields.lastName)) {
                strLastNameWhereClause = '((RE_Contact__r.DPM_Lastname_Soundex__c = \''+DPM_Soundex.toSoundex(objsearchFields.lastName)+'\')';
                strLastNameWhereClause += ' OR (RE_Contact__r.LastName = \''+String.escapeSingleQuotes(objsearchFields.lastName)+'\'))';
            }
            list<string> jobList = new list<String>();
            if(objsearchFields.jobPosition!=null){
                String positions=objsearchFields.jobPosition;
                if(positions.contains('[')){
                    positions=positions.replace('[','');
                }
                if(positions.contains(']')){
                    positions=positions.replace(']','');
                }
                 if(positions.contains('\"')){
                    positions=positions.replace('\"','');
                }
               objsearchFields.jobPosition=positions;
                jobList=objsearchFields.jobPosition.split(',');
            }
            system.debug('objsearchFields.jobPosition-='+objsearchFields.jobPosition);
            system.debug('jobList-='+jobList);
            lstWhereClauses.add((!String.isEmpty(strFirstNameWhereClause)?strFirstNameWhereClause:''));
            lstWhereClauses.add((!String.isEmpty(strLastNameWhereClause)?strLastNameWhereClause:''));
            lstWhereClauses.add((!String.isEmpty(objsearchFields.suffix)?'RE_Contact__r.Suffix = \''+objsearchFields.suffix+'\'':''));
            lstWhereClauses.add((!String.isEmpty(objsearchFields.VPID)?'RE_Contact__r.PsnId__c =\''+objsearchFields.VPID+'\'':''));
            lstWhereClauses.add((!String.isEmpty(objsearchFields.SSN)?'RE_Contact__r.DPM_SSN__c =\''+objsearchFields.SSN+'\'':''));
            lstWhereClauses.add((!String.isEmpty(objsearchFields.email)?'(RE_Contact__r.Email = \''+objsearchFields.email+'\' OR DPM_Work_Email__c = \''+objsearchFields.email+'\')':''));
            lstWhereClauses.add((!String.isEmpty(objsearchFields.store_SFId)?'RE_Account__c = \''+objsearchFields.store_SFId+'\'':''));
            lstWhereClauses.add((!String.isEmpty(objsearchFields.country)?'RE_Contact__r.MailingCountry = \''+objsearchFields.country+'\'':''));
            if(objsearchFields.primaryJobOnly){
                lstWhereClauses.add((!String.isEmpty(objsearchFields.jobPosition) ?'RE_Employee_Position__c IN:jobList' :''));
            }
            lstWhereClauses.add(!objsearchFields.showInactiveEmployees?'RE_Psn_Active__c = TRUE ':'');
            lstWhereClauses.add(objsearchFields.retailerAdmin?'RE_IsAdmin__c = TRUE ':'');
            //lstWhereClauses.add(objsearchFields.owner?'DPM_Owner__c = TRUE ':'');
            // 5/17/2021, filtering corp employees
            lstWhereClauses.add('RE_Contact__r.FirstName NOT IN :lstNamesToIgnore AND RE_Contact__r.Account.Name!=:strVolvoCorporateAccountName AND RE_Account__r.Name!=:strVolvoCorporateAccountName');
            DPM_Configuration__mdt dpmConfig = getDPMConfigCustomMetadata();
            List<String> lstRetailerCodes = new List<String>();
            //Includes Supplier Account Retailer Codes, 25/March/2022
            String strAllCodes=dpmConfig.DPM_Retailer_Codes_for_Access__c+';'+dpmConfig.DPM_Additional_Accounts_for_Search__c;
            lstRetailerCodes = strAllCodes.split(';');
            system.debug('lstRetailerCodes123$ '+lstRetailerCodes);
            lstWhereClauses.add('RE_Account__r.Retailer__c IN :lstRetailerCodes');
            for(Integer i = 0; i < lstWhereClauses.size(); i++) {
                //system.debug('where1$ '+lstWhereClauses[i]);
                if(String.isNotBlank(lstWhereClauses[i])) {
                    if(strWhereClause == strWhereClauseInitial) {
                        strWhereClause += lstWhereClauses[i];
                    } else {
                        strWhereClause += ' AND '+lstWhereClauses[i];
                    }
                }   
                //system.debug('where1$ '+strWhereClause);
            }
            
            List<String> lstPermSets = new List<String>();
            for(PermissionSetAssignment psa : [SELECT Id,PermissionSetId,PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSet.Name IN ('DPM_Corp_Incentive','DPM_Corp_Firefighter')]) {
                lstPermSets.add(psa.PermissionSet.Name);
            }
            String supplierRecordType = 'Supplier_Employee';
            String suppliercodes=dpmConfig.DPM_Additional_Accounts_for_Search__c;
            List<String> lstSupplierCodes=suppliercodes.split(';');
            if(!lstPermSets.isEmpty()){
                if(lstPermSets.contains('DPM_Corp_Incentive')){
                    strWhereClause += ' AND RE_Contact__r.RecordType.DeveloperName != :supplierRecordType';
                   // if(objsearchFields.SSN!=null){
                        dpmSearchResults.blnIsIncentiveProfile=true;
                    //}
                }
                if((lstPermSets.contains('DPM_Corp_Firefighter') || lstPermSets.contains('DPM_Corp_Incentive')) && objsearchFields.store_SFId != Null){
                    Set<String> countries=new Set<String>{'MEX','CAN'};
                     Account store=[select Id,country__c,country__r.Name,retailer__c from Account where Id=:objsearchFields.store_SFId limit 1];
                    String storecountry='';
                    if(store.country__c!=null){
                        storecountry=store.country__r.Name;
                    }
                    String retailercode='';
                    if(store.retailer__c!=null){
                        retailercode=store.retailer__c;
                    }
                    if(!countries.contains(storecountry) && !lstSupplierCodes.contains(retailercode)){
                        dpmSearchResults.blnIsIncentiveProfile=true; //2713175, W9#4: Incentive Search results & download
                    }                   
                }
                if(lstPermSets.contains('DPM_Corp_Firefighter') &&
                   !lstPermSets.contains('DPM_Corp_Incentive')
                  ){
                    dpmSearchResults.blnIsIncentiveProfile=false;
                }
            }else{
                dpmSearchResults.blnIsIncentiveProfile=false;
            }
            //String strOrderClause = '';
            //String strWhereClause = ' WHERE RE_Account__c = :defaultAccountId AND RE_Psn_Active__c =true AND RE_Position_Active__c =true';
            String strOrderClause ='';
            if(strOrderBy!=null && strOrderBy!=''){
                strOrderClause= ' ORDER BY '+strOrderBy+' '+objsessionSettings.sortDirection+' NULLS LAST';
            }  
            system.debug(strQuery+strWhereClause+strOrderClause+strLimitClause);   
            if(objsearchFields.primaryJobOnly){  
                dpmSearchResults.lstPersonRole = database.query(strQuery+strWhereClause+strOrderClause+strLimitClause);
                dpmSearchResults.intTotalResults = database.countQuery('SELECT count() FROM RE_Person_Role__c '+strWhereClause);
            }else{
            //dpmSearchResults.lstPersonRole = new list<RE_Person_Role__c>();
                system.debug('jobList:'+jobList);
                for(RE_Person_Role__c personRole:database.query(strQuery+strWhereClause+strOrderClause/*+strLimitClause*/)){
                    //add primary position first
                    if(!String.isEmpty(objsearchFields.jobPosition)){ 
                    if(jobList.contains(personRole.RE_Employee_Position__c)){
                        //if(dpmSearchResults.lstPersonRole != null && personRole != null ){
                            dpmSearchResults.lstPersonRole.add(personRole);
                        //}
                    }
                    }else{
                        dpmSearchResults.lstPersonRole.add(personRole);
                    }
                    system.debug('jobListttttt:'+personRole.DPM_Job_Positions__r);
                    //now add secondary positions
                    if(!personRole.DPM_Job_Positions__r.isEmpty()){
                        for(DPM_EmployeeJobPosition__c job:personRole.DPM_Job_Positions__r){                            
                            system.debug('jobpositionempty?'+(!String.isEmpty(objsearchFields.jobPosition)));
                            if(!String.isEmpty(objsearchFields.jobPosition)){  
                                if(job.DPM_Position_Title__c!=null &&
                                personRole.RE_Employee_Position__c!=job.DPM_Position_Title__c &&
                                    jobList.contains(job.DPM_Position_Title__c)){
                                        //add only secondary positions
                                        RE_Person_Role__c secondary=personRole.clone(false, false, false, false);
                                        secondary.RE_Employee_Position__c=job.DPM_Position_Title__c;
                                        dpmSearchResults.lstPersonRole.add(secondary);
                                        //break;
                                }
                            }else{                                
                            //determine the secondary position or not
                            if(personRole.RE_Employee_Position__c!=job.DPM_Position_Title__c){
                                //secondary position confirmed
                                RE_Person_Role__c secondary=personRole.clone(false, false, false, false);
                                secondary.RE_Employee_Position__c=job.DPM_Position_Title__c;
                                dpmSearchResults.lstPersonRole.add(secondary);
                                //break;
                            }                            
                            }
                        }
                    }
                }
                //if(dpmSearchResults.lstPersonRole != null){
                    dpmSearchResults.intTotalResults=dpmSearchResults.lstPersonRole.size();
                //}
                
            }        
        }else{
            system.debug('i am in else--=');
            dpmSearchResults=getEmployeeJobPositionQuery(objsearchFields,objsessionSettings,strChildOrderBy);
        }
        system.debug('dpmSearchResults:'+dpmSearchResults);
        return dpmSearchResults;
    }
    
    @Testvisible
    private static DPM_SearchResults getEmployeeJobPositionQuery(DPM_SearchEmployee objsearchFields, DPM_SessionSettings objsessionSettings,String strChildOrderBy) {        
        DPM_SearchResults dpmSearchResults = new DPM_SearchResults();
        String strQuery='SELECT DPM_Name__c,DPM_Store_Name_ID__c,DPM_Position_Title__c,DPM_Active_Terminated__c,DPM_Position_Start_Date__c,DPM_Work_Email__c,DPM_Country__c,DPM_Person_Role__r.RE_Contact__r.LastName, DPM_Person_Role__r.RE_Contact__r.DPM_Preferred_First_Name__c,DPM_Person_Role__r.RE_Contact__r.FirstName,DPM_Person_Role__r.RE_Contact__r.Suffix,DPM_Person_Role__r.RE_Account__r.Name,DPM_Person_Role__r.RE_Account__r.Retailer__c,DPM_Person_Role__r.RE_Psn_Active__c,DPM_Person_Role__r.RE_Contact__r.Email,DPM_Person_Role__r.RE_Contact__r.Cds_Id__c,DPM_Person_Role__r.RE_Contact__r.MailingCountry FROM DPM_EmployeeJobPosition__c';       
        String strWhereClause='';
        String strfilterByJob=''; 
        if(objsessionSettings.filterBy == 'Job_Position' && objsessionSettings.filterString != '') {
            strfilterByJob=objsessionSettings.filterString;                   
        }
        /*else if(objsearchFields.jobPosition!=''){
            strfilterByJob=objsearchFields.jobPosition;
        }*/
        strWhereClause+=' WHERE DPM_Position_End_Date__c=NULL';
        //show primary job only else show all records
        if(objsearchFields.primaryJobOnly){
            strWhereClause+=' AND DPM_Primary_Position__c='+objsearchFields.primaryJobOnly;
        } 
        list<string> jobList = new list<String>();
            if(objsearchFields.jobPosition != '' && objsearchFields.jobPosition != null){
                String positions=objsearchFields.jobPosition;
                if(positions.contains('[')){
                    positions=positions.replace('[','');
                }
                if(positions.contains(']')){
                    positions=positions.replace(']','');
                }
                 if(positions.contains('\"')){
                    positions=positions.replace('\"','');
                }
               objsearchFields.jobPosition=positions;
                jobList=objsearchFields.jobPosition.split(',');
            }
        if(jobList.size() > 0 && !jobList.isEmpty()){
            strWhereClause+=' AND DPM_Position_Title__c IN:jobList'; 
        } 
        system.debug('jobList..'+jobList);
        List<String> lstWhereClauses = new List<String>();
        String strFirstNameWhereClause,strLastNameWhereClause;
        if(!String.isEmpty(objsearchFields.firstName)) {
            strFirstNameWhereClause = '((DPM_Person_Role__r.RE_Contact__r.DPM_Firstname_Soundex__c = \''+DPM_Soundex.toSoundex(objsearchFields.firstName)+'\')';
            strFirstNameWhereClause += ' OR (DPM_Person_Role__r.RE_Contact__r.FirstName = \''+String.escapeSingleQuotes(objsearchFields.firstName)+'\'))';
        }
        if(!String.isEmpty(objsearchFields.lastName)) {
            strLastNameWhereClause = '((DPM_Person_Role__r.RE_Contact__r.DPM_Lastname_Soundex__c = \''+DPM_Soundex.toSoundex(objsearchFields.lastName)+'\')';
            strLastNameWhereClause += ' OR (DPM_Person_Role__r.RE_Contact__r.LastName = \''+String.escapeSingleQuotes(objsearchFields.lastName)+'\'))';
        }
        lstWhereClauses.add((!String.isEmpty(strFirstNameWhereClause)?strFirstNameWhereClause:''));
        lstWhereClauses.add((!String.isEmpty(strLastNameWhereClause)?strLastNameWhereClause:''));
        lstWhereClauses.add((!String.isEmpty(objsearchFields.suffix)?'DPM_Person_Role__r.RE_Contact__r.Suffix = \''+objsearchFields.suffix+'\'':''));
        lstWhereClauses.add((!String.isEmpty(objsearchFields.email)?'DPM_Person_Role__r.RE_Contact__r.Email = \''+objsearchFields.email+'\'':''));
        //retailer portal, from default account
        Account defaultAccount = getDefaultAccount();
        Id defaultAccountId = defaultAccount.Id;
        lstWhereClauses.add((!String.isEmpty(defaultAccountId)?'DPM_Person_Role__r.RE_Account__c = \''+defaultAccountId+'\'':''));
        lstWhereClauses.add((!String.isEmpty(objsearchFields.country)?'DPM_Person_Role__r.RE_Contact__r.MailingCountry = \''+objsearchFields.country+'\'':''));
        lstWhereClauses.add(!objsearchFields.showInactiveEmployees?'DPM_Person_Role__r.RE_Psn_Active__c = TRUE ':'');
        // 5/17/2021, filtering corp employees
        lstWhereClauses.add('DPM_Person_Role__c!=NULL AND DPM_Person_Role__r.RE_Contact__c!=null AND DPM_Person_Role__r.RE_Contact__r.FirstName NOT IN :lstNamesToIgnore AND DPM_Person_Role__r.RE_Contact__r.AccountId!=null AND DPM_Person_Role__r.RE_Contact__r.Account.Name!=:strVolvoCorporateAccountName AND DPM_Person_Role__r.RE_Account__c!=NULL AND DPM_Person_Role__r.RE_Account__r.Name!=:strVolvoCorporateAccountName');
        DPM_Configuration__mdt dpmConfig = getDPMConfigCustomMetadata();
        List<String> lstRetailerCodes = new List<String>();
        lstRetailerCodes = dpmConfig.DPM_Retailer_Codes_for_Access__c.split(';');
        system.debug('lstRetailerCodes123$ '+lstRetailerCodes);  
        if(lstRetailerCodes!=null){      
            lstWhereClauses.add('DPM_Retailer_Code__c IN :lstRetailerCodes');
        }
        for(Integer i = 0; i < lstWhereClauses.size(); i++) {
            //system.debug('where1$ '+lstWhereClauses[i]);
            if(String.isNotBlank(lstWhereClauses[i])) {               
                strWhereClause += ' AND '+lstWhereClauses[i];                
            }
        }      
        String strOrderClause=''; 
        if(strChildOrderBy!=null && strChildOrderBy!=''){
            strOrderClause+= ' ORDER BY '+strChildOrderBy+' '+objsessionSettings.sortDirection+'';
        }    
        if(!objsessionSettings.skipOffset &&
           objsessionSettings.showViewMore) {
               strOrderClause+= ' LIMIT '+objsessionSettings.intLimit+' OFFSET '+objsessionSettings.intOffset;
           } 
        system.debug(strQuery+strWhereClause+strOrderClause);
        dpmSearchResults.lstJobPositions = database.query(strQuery+strWhereClause+strOrderClause);
        dpmSearchResults.intTotalResults = database.countQuery('SELECT count() FROM DPM_EmployeeJobPosition__c '+strWhereClause);        
        return dpmSearchResults;
    }
    public static CorporatePermissions getCorporatePermissions() {
        //Map<String,Map<String,FieldPermissions>> mapPermSetToPermissions = new Map<String,Map<String,FieldPermissions>>();
        Map<String,List<String>> mapPermissionToFields = new Map<String,List<String>>();
        List<String> lstPermSets = new List<String>();
        CorporatePermissions corpPermissions = new CorporatePermissions(); 
        for(PermissionSetAssignment psa : [SELECT Id,PermissionSetId,PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSet.Name IN ('DPM_Corp_Digital_Admin','DPM_Corp_Incentive','DPM_Corp_Helpdesk','DPM_Corp_Firefighter','DPM_Corp_Business_Admin')]) {
            lstPermSets.add(psa.PermissionSet.Name);
        }
        if(!lstPermSets.isEmpty()) {            
            if(lstPermSets.contains('DPM_Corp_Business_Admin')) {
                corpPermissions.editJobPositions = true;
                corpPermissions.viewSSNLastFour = true;
                corpPermissions.viewPersonalData = true;
                corpPermissions.accessBuySell = true;
                corpPermissions.editSuppliers=true;
            }
            if(lstPermSets.contains('DPM_Corp_Incentive')) {
                corpPermissions.viewSSN = true;
                corpPermissions.editSSN = true;                
                corpPermissions.searchSSN = true;
                corpPermissions.editPersonalData = true;
                corpPermissions.viewPersonalData = true;
                corpPermissions.hideCreateEmployee=true;
                corpPermissions.hideReactivateEmployee=true;
                corpPermissions.hideInitiatedRequestsTab=true;
                corpPermissions.hideSubmitedRequestsTab=true;
                corpPermissions.showUserGuideToIncentive = true;
                corpPermissions.viewW9 = true;
                corpPermissions.isIncentiveProfile=true;
            }
            if(lstPermSets.contains('DPM_Corp_Helpdesk')) {
                corpPermissions.editPermission = false;
                corpPermissions.viewSSNLastFour = true;
                corpPermissions.editStoreData = false;
                corpPermissions.viewPersonalData = true;  
                corpPermissions.editSuppliers=true;              
            }
            if(lstPermSets.contains('DPM_Corp_Digital_Admin')) {
                corpPermissions.viewSSNLastFour = true;
                corpPermissions.viewPersonalData = true;
                corpPermissions.viewCDSIDMonitor=true;
                corpPermissions.editSuppliers=true;
            }
            if(lstPermSets.contains('DPM_Corp_Firefighter')) {
                corpPermissions.viewSSN = true;
                corpPermissions.editSSN = true;
                corpPermissions.editJobPositions = true;
                corpPermissions.viewPersonalData = true;
                corpPermissions.editPersonalData = true;
                corpPermissions.accessBuySell = true;
                corpPermissions.viewDiversityData = true;
                corpPermissions.editLanguage = true;
                corpPermissions.editSuppliers=true;
                corpPermissions.viewW9ForFireFighter = true;
                corpPermissions.editDMSId=true;
                corpPermissions.editEmail=true;
            }
        }
        // query on groupmember object to check if the logged in user is a member of this group.. ,14/March/2022
        List<String> lstGroupUsers = new List<String>();
        for(GroupMember groupMemberObj:[SELECT Id, GroupId,group.name, UserOrGroupId 
                                        FROM GroupMember 
                                        where group.name='DPM Supplier Admins']){
                                            lstGroupUsers.add(groupMemberObj.UserOrGroupId);
                                        }
        if(!lstGroupUsers.isEmpty()){
            String loginUserId=UserInfo.getUserId();
            if(lstGroupUsers.contains(loginUserId)){                
                corpPermissions.manageSuppliers = true;
            }
        }
        return corpPermissions;
    }
    public static Integer getExistingEmployeesTotal() {
        Account defaultAccount = getDefaultAccount();
        Id defaultAccountId = defaultAccount.Id;
        String strQuery = 'SELECT '+
            'count()'+
            ' FROM RE_Person_Role__c'+
            ' WHERE RE_Account__c = :defaultAccountId AND RE_Psn_Active__c =true AND RE_Position_Active__c =true AND RE_Contact__r.Cds_Id__c!=NULL';
        return database.countQuery(strQuery);
    }
    public static list<DPM_Employee__c> getDPMEmployees() {
        List<DPM_Employee__c> lstDPMEmployees = new List<DPM_Employee__c>();
        Account defaultAccount = getDefaultAccount();
        if(defaultAccount != NULL) {
            lstDPMEmployees=[SELECT Id, CreatedById, LastModifiedById, DPM_Account__r.Name,DPM_Account__r.Org_activated__c, DPM_Account__r.Retailer__c, DPM_Email__c, DPM_Legal_First_Name__c, DPM_Status__c,
                             DPM_Gender__c,DPM_Other_Gender__c, DPM_Prefix__c, DPM_Middle_Name__c, DPM_Last_Name__c, DPM_Suffix__c, DPM_Preferred_First_Name__c,DPM_Personal_Email__c,
                             DPM_Hire_Date__c,DPM_SSN_SIN__c,DPM_Owner__c,DPM_Owner_Title__c,DPM_Canadian_State__c,DPM_Mexican_State__c,DPM_Cell_Phone__c,DPM_City__c,DPM_Country__c,DPM_Home_Address_Street__c,
                             DPM_Home_Phone__c,DPM_US_State__c,DPM_Contact__c,DPM_Zipcode__c,DPM_Home_Address_Street_2__c,DPM_Submitted_DateTime__c,DPM_Retailer_Admin__c,DPM_Request_Type__c,
                             DPM_Ethnicity__c,DPM_US_Military__c,DPM_Language_1__c,DPM_Language_2__c,DPM_Language_3__c,DPM_Proficiency_1__c,DPM_Proficiency_2__c,DPM_Proficiency_3__c,DPM_Race__c,
                             (SELECT Id, DPM_End_Date__c, DPM_Primary__c, Name, DPM_Start_Date__c FROM DPM_Job_Positions__r)  
                             FROM DPM_Employee__c WHERE DPM_Account__c = :defaultAccount.Id AND DPM_Record_Origin__c = 'Portal' 
                             AND DPM_Employee_Type__c = 'Retailer' AND DPM_Status__c != 'Completed' ORDER BY CreatedDate DESC];
            return lstDPMEmployees;
        }
        return NULL;
    }
    public static list<DPM_Employee__c> getDPMEmployeesCorp() {
        List<DPM_Employee__c> lstDPMEmployees = new List<DPM_Employee__c>();
        lstDPMEmployees=[SELECT Id, CreatedById, LastModifiedById, DPM_Account__r.Name, DPM_Account__r.Org_activated__c,DPM_Account__r.Retailer__c, DPM_Email__c, DPM_Legal_First_Name__c, DPM_Status__c,
                         DPM_Gender__c,DPM_Other_Gender__c, DPM_Prefix__c, DPM_Middle_Name__c, DPM_Last_Name__c, DPM_Suffix__c, DPM_Preferred_First_Name__c,DPM_Personal_Email__c,
                         DPM_Hire_Date__c,DPM_Owner__c,DPM_SSN_SIN__c,DPM_Owner_Title__c,DPM_Canadian_State__c,DPM_Cell_Phone__c,DPM_City__c,DPM_Country__c,DPM_Home_Address_Street__c,
                         DPM_Home_Phone__c,DPM_US_State__c,DPM_Mexican_State__c,DPM_Contact__c,DPM_Zipcode__c,DPM_Home_Address_Street_2__c,DPM_Submitted_DateTime__c,DPM_Retailer_Admin__c,DPM_Request_Type__c, 
                         DPM_Ethnicity__c,DPM_US_Military__c,DPM_Language_1__c,DPM_Language_2__c,DPM_Language_3__c,DPM_Proficiency_1__c,DPM_Proficiency_2__c,DPM_Proficiency_3__c,DPM_Race__c,DPM_Employee_Type__c,
                         (SELECT Id, DPM_End_Date__c, DPM_Primary__c, Name, DPM_Start_Date__c FROM DPM_Job_Positions__r)  
                         FROM DPM_Employee__c WHERE DPM_Record_Origin__c = 'Corporate'  
                         AND DPM_Status__c != 'Completed' ORDER BY CreatedDate DESC];
        return lstDPMEmployees;
    }
    public static List<RE_Job_to_Persona_map__mdt> getPositionsForDPMEmployee(Id accountId) {
        system.debug('accountId:'+accountId);
        String str_country_code='';
        try{
            str_country_code=[SELECT DPM_Country_Code__c FROM Account WHERE Id=:accountId].DPM_Country_Code__c;
        }catch(Exception ex){
            System.debug(ex);
        }
        system.debug('str_country_code:'+str_country_code);
        List<RE_Job_to_Persona_map__mdt> positionsList=new List<RE_Job_to_Persona_map__mdt>();
        for(RE_Job_to_Persona_map__mdt position:[SELECT Id,DPM_Available_for_Mexico__c,MasterLabel,DPM_Owner_Position__c,DPM_Primary_Position__c,DPM_Incentive_Eligible__c 
                                                 FROM RE_Job_to_Persona_map__mdt 
                                                 ORDER BY MasterLabel]){
                                                     if(str_country_code!=null && str_country_code!='' && str_country_code.equalsIgnoreCase(System.Label.DPM_Mexico_Country_Code)){
                                                         if(position.DPM_Available_for_Mexico__c){
                                                             positionsList.add(position);
                                                         }
                                                     }else{
                                                         positionsList.add(position);
                                                     }
                                                 }
        return positionsList;
    }
    /*public static List<Account> getValidDealershipsForDPM() {
return getValidDealershipsForDPM(false);
}*/
    public static List<Account> getValidDealershipsForDPM(boolean isSupplier) {
        List<Account> lstDealershipsWithoutActiveRetailers = new List<Account>();
        List<String> lstRetailerCodes = new List<String>();
        DPM_Configuration__mdt dpmConfig = getDPMConfigCustomMetadata();
        if(isSupplier != NULL && !isSupplier){
            lstRetailerCodes = dpmConfig.DPM_Retailer_Codes_for_Access__c.split(';');
            /*if(isAdditionalAccountSerch) {
lstRetailerCodes.addAll(dpmConfig.DPM_Additional_Accounts_for_Search__c.split(';'));
}*/
            if(!lstRetailerCodes.isEmpty()) {
                return [SELECT Id,Name,Retailer__c,Org_activated__c 
                        FROM Account WHERE Org_non_activated__c = NULL AND Org_activated__c <> NULL AND RecordType.Name='Retailer' AND Retailer__c IN :lstRetailerCodes
                        ORDER BY Name];
            }
            return [SELECT Id,Name,Retailer__c,Org_activated__c  
                    FROM Account WHERE Org_non_activated__c = NULL AND Org_activated__c <> NULL AND RecordType.Name='Retailer'
                    ORDER BY Name];
        }
        else{
            lstRetailerCodes = dpmConfig.DPM_Additional_Accounts_for_Search__c.split(';');
            if(!lstRetailerCodes.isEmpty()) {
                return [SELECT Id,Name,Retailer__c,Org_activated__c 
                        FROM Account WHERE Org_non_activated__c = NULL AND Org_activated__c <> NULL AND RecordType.Name='Partner' AND Retailer__c IN :lstRetailerCodes
                        ORDER BY Name];
            }
            return [SELECT Id,Name,Retailer__c,Org_activated__c  
                    FROM Account WHERE Org_non_activated__c = NULL AND Org_activated__c <> NULL AND RecordType.Name='Partner'
                    ORDER BY Name];
        }
    }    
    public static Id upsertContact(DPM_Employee__c dpmEmployeeReg) {
        Contact contact = convertDPMEmployeeToContact(dpmEmployeeReg);
        if(dpmEmployeeReg.DPM_Contact__c != NULL) {
            contact.Id = dpmEmployeeReg.DPM_Contact__c;        
        }
        upsert contact;
        if(dpmEmployeeReg.DPM_Request_Type__c == 'New') {
            dpmEmployeeReg.DPM_Contact__c = contact.Id;
            update dpmEmployeeReg;
        }
        return contact.Id;
    }
    public static RE_Person_Role__c insertPersonRole(Id idContact,DPM_Employee__c dpmEmployeeReg) {
        RE_Person_Role__c personRole = new RE_Person_Role__c(); 
        Contact contact = [SELECT Id,Cds_Id__c,Cnt_Id__c,PsnId__c,DPM_VPID__c,DPM_SF_VPID__c,Account.ShippingStreet,Account.ShippingCity,Account.ShippingCountry,Account.ShippingPostalCode,Account.ShippingState FROM Contact WHERE Id = :idContact];
        Account account = [SELECT Id,ShippingStreet,ShippingCity,ShippingCountry,ShippingPostalCode,ShippingState FROM Account WHERE Id = :dpmEmployeeReg.DPM_Account__c];
        personRole = createPersonRole(contact,dpmEmployeeReg,account);
        insert personRole;
        return personRole;
    }
    public static void insertJobPositions(RE_Person_Role__c personRole,DPM_Employee__c dpmEmployeeReg) {
        List<DPM_EmployeeJobPosition__c> lstJobPositions = new List<DPM_EmployeeJobPosition__c>();
        for(DPM_Job_Position__c dpmJobPosition : [SELECT Id,DPM_End_Date__c,DPM_Primary__c,DPM_Start_Date__c,Name FROM DPM_Job_Position__c WHERE DPM_Employee_Registration__c = :dpmEmployeeReg.Id]) {
            lstJobPositions.add(new DPM_EmployeeJobPosition__c(
                DPM_Contact__c = personRole.RE_Contact__c,
                DPM_Account__c = dpmEmployeeReg.DPM_Account__c,
                DPM_Position_End_Date__c = dpmJobPosition.DPM_End_Date__c,
                DPM_Primary_Position__c = dpmJobPosition.DPM_Primary__c,
                DPM_Position_Start_Date__c = dpmJobPosition.DPM_Start_Date__c,
                DPM_Position_Title__c = dpmJobPosition.Name,
                DPM_Person_Role__c = personRole.Id
            ));
        }
        if(!lstJobPositions.isEmpty()) {
            insert lstJobPositions;
        }
    }
    private static Contact convertDPMEmployeeToContact(DPM_Employee__c dpmEmployeeReg) {
        Boolean blnNeedsVPIDGeneration = false;
        if(dpmEmployeeReg.DPM_Contact__c != NULL) {
            Contact existingContact = [SELECT Id,DPM_VPID__c,RecordTypeId FROM Contact WHERE Id = :dpmEmployeeReg.DPM_Contact__c];
            if(existingContact.RecordTypeId != retailerEmployeeRecordTypeId) { 
                //If recordtype is not Retailer Employee, then this is a case for recordtype conversion
                blnTypeConversion = true;
            }        
            if(existingContact.DPM_VPID__c == NULL || existingContact.DPM_VPID__c == 0) {
                blnNeedsVPIDGeneration = true;
            }
        }
        
        Contact contact=new Contact();
        if( dpmEmployeeReg.DPM_Employee_Type__c == 'Supplier'){
            list<user> groupMemberList = [select id from user where id in (select userorgroupid from groupmember where group.developername ='DPM_Supplier_Admins')];
            contact.RecordTypeId = supplierEmployeeRecordTypeId;
            if(!groupMemberList.IsEmpty()){
                for(user userObj : groupMemberList){
                    if(userObj.id == UserInfo.getUserId()){
                        contact.OwnerId = userObj.id;
                        break;
                    }
                }
            }
        }else{
            contact.RecordTypeId=retailerEmployeeRecordTypeId;
        }
        contact.Salutation=dpmEmployeeReg.DPM_Prefix__c;
        contact.FirstName=dpmEmployeeReg.DPM_Legal_First_Name__c;
        contact.MiddleName=dpmEmployeeReg.DPM_Middle_Name__c;
        contact.LastName=dpmEmployeeReg.DPM_Last_Name__c;
        contact.Suffix=dpmEmployeeReg.DPM_Suffix__c;
        contact.DPM_Preferred_First_Name__c=dpmEmployeeReg.DPM_Preferred_First_Name__c;
        contact.DPM_Personal_Email__c=dpmEmployeeReg.DPM_Personal_Email__c;
        if(dpmEmployeeReg.DPM_Request_Type__c == 'New' || blnTypeConversion) {
            contact.AccountId=dpmEmployeeReg.DPM_Account__c;            
        }
        if(blnNeedsVPIDGeneration) {
            //generate SF VPID and cnt id for existing contact
            Contact conWithLastVPID = [SELECT DPM_VPID__c FROM Contact WHERE (CreatedDate = LAst_N_Months:2 or CreatedDate = THIS_MONTH) and recordtype.name IN ('Retailer Employee','Supplier Employee') and DPM_VPID__c <> null ORDER BY DPM_VPID__c DESC NULLS LAST LIMIT 1];
            Account a = [SELECT Id,Retailer__c FROM Account WHERE Id = :dpmEmployeeReg.DPM_Account__c];
            Integer intMaxVPID = Integer.valueOf(conWithLastVPID.DPM_VPID__c);
            contact.DPM_VPID__c = intMaxVPID+1;
            contact.Cnt_Id__c = a.Retailer__c+''+contact.DPM_VPID__c;
        }
        if(dpmEmployeeReg.DPM_Request_Type__c != 'Extension') {
            contact.DPM_Activated__c = FALSE;
            contact.Email=dpmEmployeeReg.DPM_Email__c;
        }
        contact.Phone=dpmEmployeeReg.DPM_Cell_Phone__c;
        contact.HomePhone=dpmEmployeeReg.DPM_Home_Phone__c;
        contact.DPM_Gender__c=dpmEmployeeReg.DPM_Gender__c;        
        contact.DPM_Other_Gender__c=dpmEmployeeReg.DPM_Other_Gender__c;        
        contact.MailingStreet=dpmEmployeeReg.DPM_Home_Address_Street__c;
        if(dpmEmployeeReg.DPM_Home_Address_Street_2__c != NULL && dpmEmployeeReg.DPM_Home_Address_Street_2__c != '') {
            contact.MailingStreet+='\r\n'+dpmEmployeeReg.DPM_Home_Address_Street_2__c;
        }
        contact.MailingCity=dpmEmployeeReg.DPM_City__c;   
        if(dpmEmployeeReg.DPM_Country__c == 'USA' || dpmEmployeeReg.DPM_Country__c == 'United States') {
            contact.MailingCountry='United States';
            contact.MailingState=dpmEmployeeReg.DPM_US_State__c;
        } else if(dpmEmployeeReg.DPM_Country__c == 'Canada') {
            contact.MailingCountry='Canada';
            contact.MailingState=dpmEmployeeReg.DPM_Canadian_State__c;   
        } 
        else if(dpmEmployeeReg.DPM_Country__c == 'Mexico') {
            contact.MailingCountry='Mexico';
            contact.MailingState=dpmEmployeeReg.DPM_Mexican_State__c;   
        }  
        contact.MailingPostalCode=dpmEmployeeReg.DPM_Zipcode__c;  
        if(dpmEmployeeReg.DPM_SSN_SIN__c != NULL && dpmEmployeeReg.DPM_SSN_SIN__c!='') {
            contact.DPM_SSN__c=dpmEmployeeReg.DPM_SSN_SIN__c.replaceAll('-','');
        }  
        //Diversity Data
        contact.DPM_US_Military__c=dpmEmployeeReg.DPM_US_Military__c;
        contact.DPM_Race__c=dpmEmployeeReg.DPM_Race__c;
        contact.DPM_Ethnicity__c=dpmEmployeeReg.DPM_Ethnicity__c;
        contact.DPM_Language_1__c=dpmEmployeeReg.DPM_Language_1__c;
        contact.DPM_Language_2__c=dpmEmployeeReg.DPM_Language_2__c;
        contact.DPM_Language_3__c=dpmEmployeeReg.DPM_Language_3__c;
        contact.DPM_Proficiency_1__c=dpmEmployeeReg.DPM_Proficiency_1__c;
        contact.DPM_Proficiency_2__c=dpmEmployeeReg.DPM_Proficiency_2__c;
        contact.DPM_Proficiency_3__c=dpmEmployeeReg.DPM_Proficiency_3__c;
        return contact;
    }
    private static RE_Person_Role__c createPersonRole(Contact contact,DPM_Employee__c dpmEmployeeReg,Account account) {
        RE_Person_Role__c personRole = new RE_Person_Role__c();
        personRole.RE_Account__c = dpmEmployeeReg.DPM_Account__c;
        personRole.RE_Contact__c = contact.Id;
        personRole.RE_Cnt_Id__c = contact.Cnt_Id__c;            
        personRole.RE_Psn_Active_Date__c = dpmEmployeeReg.DPM_Hire_Date__c; 
        personRole.RE_Psn_NonActive_Date__c = dpmEmployeeReg.DPM_Expiration_Date__c;
        personRole.DPM_Owner__c = dpmEmployeeReg.DPM_Owner__c;
        personRole.DPM_Owner_Title__c = dpmEmployeeReg.DPM_Owner_Title__c;
        personRole.DPM_Work_Email__c = dpmEmployeeReg.DPM_Email__c;
        List<User> lstUser = new List<User>();
        lstUser = getUsers(contact);
        if(lstUser != NULL && lstUser.size()>0) {
            User user = lstUser[0];
            personRole.RE_User__c = user.Id;
            if(blnTypeConversion) {
                Model_Contact.updateUsers(new List<Id>{user.Id});
            }
            //if(user.FederationIdentifier == dpmEmployeeReg.DPM_CDS_ID__c) {
            // personRole.DPM_Primary__c = True;
            //}
        }
        personRole.RE_PsnId__c = contact.PsnId__c;
        //personRole.DPM_CDS_Id__c = dpmEmployeeReg.DPM_CDS_ID__c;        
        personRole.RE_IsAdmin__c = dpmEmployeeReg.DPM_Retailer_Admin__c;
        if(personRole.RE_Psn_NonActive_Date__c == NULL) {
            personRole.RE_Psn_Active__c = True;
        }   
        personRole.DPM_Work_Address_Street__c = account.ShippingStreet;
        personRole.DPM_Work_Address_City__c = account.ShippingCity;
        personRole.DPM_Work_Address_State__c = account.ShippingState;
        personRole.DPM_Work_Address_Country__c = account.ShippingCountry;
        personRole.DPM_Work_Address_Zip_Postal_Code__c = account.ShippingPostalCode;
        if(dpmEmployeeReg.DPM_Request_Type__c != 'Extension' || blnTypeConversion) {
            personRole.DPM_Primary__c = True;
        }
        return personRole;
    }
    @testvisible
    private static RE_Job_to_Persona_map__mdt getPersonaMap(String strPosition) {
        return [SELECT Persona__c, Job_Abbr__c, Label FROM RE_Job_to_Persona_map__mdt WHERE Label = :strPosition Limit 1];
    }
    private static List<User> getUsers(Contact contact) {
        return [SELECT Id,FederationIdentifier FROM User WHERE ContactId = :contact.Id];
    }
    public static RE_Person_Role__c getUserProfile(Id idUser,Id idAccount) {
        User user = [SELECT ContactId FROM User WHERE Id = :idUser];
        
        Id idContact = user.ContactId;
        system.debug('idContact-=-'+idContact+' idUser-=-'+idUser+' idAccount'+idAccount);
        String strQuery = 'SELECT '+
            getEmployeeProfileFields()+
            ' FROM RE_Person_Role__c'+
            ' WHERE RE_Account__c = :idAccount AND RE_Contact__c = :idContact AND RE_User__c = :idUser AND RE_Psn_Active__c =true AND RE_Position_Active__c =true';
        system.debug('strQuery-=-'+strQuery);
        RE_Person_Role__c currentPersonRole = database.query(strQuery);
        system.debug('currentPersonRole-=-'+currentPersonRole);
        if(!checkDPMAccess(currentPersonRole)) {
            throw new AuraHandledException('You do not have access to Personnel Management.');
        }
        return currentPersonRole;
    }
    public static RE_Person_Role__c getUserProfile(String strPersonRoleId) {
        String strQuery = 'SELECT '+
            getEmployeeProfileFields()+
            ' FROM RE_Person_Role__c'+
            ' WHERE Id=:strPersonRoleId AND RE_Psn_Active__c =true AND RE_Position_Active__c =true';
        RE_Person_Role__c currentPersonRole = database.query(strQuery);
        if(!checkDPMAccess(currentPersonRole)) {
            throw new AuraHandledException('You do not have access to Personnel Management.');
        }
        return currentPersonRole;
    }
    public static Map<String,List<String>> getCountryStatesMap() {
        Map<String,List<String>> mapCountryToStates = new Map<String,List<String>>();
       /* DPM_Configuration__mdt dpmConfig = getDPMConfigCustomMetadata();
        List<String> lstPermSets = new List<String>();
        for(PermissionSetAssignment psa : [SELECT Id,PermissionSetId,PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSet.Name IN ('DPM_Corp_Incentive')]) {
            lstPermSets.add(psa.PermissionSet.Name);
        }        
        if(!lstPermSets.isEmpty() &&
           lstPermSets.contains('DPM_Corp_Incentive')
          ){
              mapCountryToStates.put('United States',getPicklistValuesFromObject('DPM_US_State__c','DPM_Employee__c',false));     
          }else{              
              mapCountryToStates.put('United States',getPicklistValuesFromObject('DPM_US_State__c','DPM_Employee__c',false));
              mapCountryToStates.put('Canada',getPicklistValuesFromObject('DPM_Canadian_State__c','DPM_Employee__c',false));
              mapCountryToStates.put('Mexico',getPicklistValuesFromObject('DPM_Mexican_State__c','DPM_Employee__c',false));
          }  */   
          mapCountryToStates.put('United States',getPicklistValuesFromObject('DPM_US_State__c','DPM_Employee__c',false));
          mapCountryToStates.put('Canada',getPicklistValuesFromObject('DPM_Canadian_State__c','DPM_Employee__c',false));
          mapCountryToStates.put('Mexico',getPicklistValuesFromObject('DPM_Mexican_State__c','DPM_Employee__c',false));
        
        return mapCountryToStates;
    }
    private static String getEmployeeProfileFields() {
        return 'Id,RE_Contact__r.DPM_VPID__c,RE_Contact__r.Account_Country__c,DPM_DMS_Id__c,DPM_Work_Address_Same_as_Store_Address__c,DPM_CDS_Id__c,RE_Contact__r.DPM_Proficiency_1__c,RE_Contact__r.DPM_Proficiency_2__c,RE_Account__r.Org_activated__c,RE_Contact__r.DPM_Proficiency_3__c, RE_Contact__r.DPM_Language_1__c,RE_Contact__r.DPM_Language_2__c,RE_Contact__r.DPM_Language_3__c,RE_Psn_Active__c,RE_Employee_Position__c,RE_IsAdmin__c,DPM_Owner__c,DPM_Owner_Title__c,RE_Psn_Active_Date__c,RE_PsnId__c,'+
            'RE_Psn_NonActive_Date__c,DPM_Work_Address_Country__c,DPM_Work_Address_City__c,DPM_Work_Address_State__c,DPM_Work_Address_Street__c,DPM_Work_Address_Zip_Postal_Code__c,DPM_Work_Email__c,DPM_Work_Phone__c,'+
            'RE_Contact__c,RE_Contact__r.Id,RE_Contact__r.Salutation,RE_Contact__r.FirstName,RE_Contact__r.DPM_Firstname_Soundex__c,RE_Contact__r.DPM_Lastname_Soundex__c,RE_Contact__r.MiddleName,RE_Contact__r.LastName,RE_Contact__r.DPM_SF_VPID__c,RE_Contact__r.PsnId__c,RE_Contact__r.DPM_Race__c,RE_Contact__r.DPM_Ethnicity__c,'+
            'RE_Contact__r.Suffix,RE_Contact__r.DPM_Gender__c,RE_Contact__r.DPM_Other_Gender__c,RE_Contact__r.DPM_US_Military__c,RE_Contact__r.DPM_SSN__c,RE_Contact__r.DPM_Preferred_First_Name__c,RE_Contact__r.Email,RE_Contact__r.Phone,RE_Contact__r.HomePhone,'+
            'RE_Contact__r.OtherPhone,RE_Contact__r.MailingStreet,RE_Contact__r.MailingCity,RE_Contact__r.MailingState,RE_Contact__r.MailingPostalCode,RE_Contact__r.MailingCountry, RE_Contact__r.RecordType.Name,'+
            'RE_Contact__r.DPM_Personal_Email__c,RE_Contact__r.DPM_Additional_Email_1__c,RE_Contact__r.DPM_Additional_Email_2__c,RE_Contact__r.Cds_Id__c,'+
            'RE_Account__c,RE_Account__r.Name,RE_Account__r.Retailer__c,RE_Account__r.Market__r.Name,RE_Account__r.Region__r.Name,'+
            'RE_Account__r.BillingCountry,RE_Account__r.BillingStreet, RE_Account__r.BillingCity, RE_Account__r.BillingPostalCode, RE_Account__r.BillingState,RE_Contact__r.DPM_W9_Date__c,RE_Contact__r.DPM_W9_Flag__c,RE_Contact__r.DPM_W9_Reason__c,'+
            '(SELECT Id,DPM_Position_Title__c,DPM_Primary_Position__c,DPM_Position_Start_Date__c,DPM_Position_End_Date__c FROM DPM_Job_Positions__r)';
    }
    
    //Duplicate Check for new Retailer Employee when Admin Initiates a request
    public static List<RE_Person_Role__c> retailerEmpDupCheck_RetailerAdmin(String strDPMEmployee) {
        DPM_Employee__c dpmEmployee = (DPM_Employee__c) JSON.deserialize(strDPMEmployee, DPM_Employee__c.class);
        List<RE_Person_Role__c> lstRetailerEmployees = new List<RE_Person_Role__c>();
        lstRetailerEmployees = [SELECT Id,DPM_Work_Email__c,RE_Psn_Active__c,RE_Contact__r.Email,RE_Contact__r.Lastname,RE_Contact__r.Firstname,RE_Contact__r.Suffix,RE_Contact__r.DPM_Preferred_First_Name__c
                                FROM RE_Person_Role__c
                                WHERE RE_Contact__r.RecordType.Name IN ('Retailer Employee','Supplier Employee')
                                AND ((RE_Contact__r.Email=:dpmEmployee.DPM_Email__c OR DPM_Work_Email__c=:dpmEmployee.DPM_Email__c)
                                     OR (
                                         (RE_Contact__r.LastName=:dpmEmployee.DPM_Last_Name__c OR RE_Contact__r.DPM_Lastname_Soundex__c=:DPM_Soundex.toSoundex(dpmEmployee.DPM_Last_Name__c))
                                         AND (RE_Contact__r.FirstName=:dpmEmployee.DPM_Legal_First_Name__c OR RE_Contact__r.DPM_FirstName_Soundex__c=:DPM_Soundex.toSoundex(dpmEmployee.DPM_Legal_First_Name__c))
                                         AND RE_Contact__r.Suffix=:dpmEmployee.DPM_Suffix__c
                                     ) 
                                     OR (
                                         (RE_Contact__r.LastName=:dpmEmployee.DPM_Last_Name__c OR RE_Contact__r.DPM_Lastname_Soundex__c=:DPM_Soundex.toSoundex(dpmEmployee.DPM_Last_Name__c)) 
                                         AND RE_Contact__r.DPM_Preferred_First_Name__c!= NULL 
                                         AND (RE_Contact__r.DPM_Preferred_First_Name__c=:dpmEmployee.DPM_Preferred_First_Name__c OR RE_Contact__r.DPM_Preferred_FirstName_Soundex__c=:DPM_Soundex.toSoundex(dpmEmployee.DPM_Preferred_First_Name__c)) 
                                         AND RE_Contact__r.Suffix=:dpmEmployee.DPM_Suffix__c
                                     )
                                    )];
        // 11/Jan/2021, returning matched records
        return lstRetailerEmployees;
    }
    //Duplicate Check for new Retailer Employee after Self registration
    public static DPM_DuplicateCheckResult retailerEmpDupCheck_SelfReg(String strDPMEmployee) {
        DPM_Employee__c dpmEmployee = (DPM_Employee__c) JSON.deserialize(strDPMEmployee, DPM_Employee__c.class);
        DPM_DuplicateCheckResult dpmDuplicateResult = new DPM_DuplicateCheckResult();
        dpmDuplicateResult.dpmDuplicates = new List<DPM_DuplicateRecord>();
        Set<Id> setAccountIds = new Set<Id>();
        String strStateForPlaceboStores = '';
        // Check for matching Contacts
        List<Contact> lstMatchingRetailerEmployees = new List<Contact>();
        if(dpmEmployee.DPM_SSN_SIN__c != NULL && dpmEmployee.DPM_SSN_SIN__c != '') {
            dpmEmployee.DPM_SSN_SIN__c = dpmEmployee.DPM_SSN_SIN__c.replaceAll('-','');
        }
        lstMatchingRetailerEmployees = [SELECT Id,Account.Name,Account.BillingState,Phone,HomePhone,OtherPhone,Email,FirstName,LastName,Suffix,DPM_Preferred_First_Name__c,DPM_SSN__c FROM Contact
                                        WHERE 
                                        RecordType.Name IN ('Retailer Employee','Supplier Employee')
                                        AND (
                                            (DPM_SSN__c!= NULL AND DPM_SSN__c = :dpmEmployee.DPM_SSN_SIN__c)
                                            OR (Phone!= NULL AND Phone=:dpmEmployee.DPM_Cell_Phone__c)
                                            OR (HomePhone!= NULL AND HomePhone=:dpmEmployee.DPM_Cell_Phone__c)
                                            OR (OtherPhone!= NULL AND OtherPhone=:dpmEmployee.DPM_Cell_Phone__c)
                                            OR Email=:dpmEmployee.DPM_Email__c
                                            OR (
                                                (LastName=:dpmEmployee.DPM_Last_Name__c OR DPM_Lastname_Soundex__c=:DPM_Soundex.toSoundex(dpmEmployee.DPM_Last_Name__c))
                                                AND (FirstName=:dpmEmployee.DPM_Legal_First_Name__c OR DPM_FirstName_Soundex__c=:DPM_Soundex.toSoundex(dpmEmployee.DPM_Legal_First_Name__c)) 
                                                AND Suffix=:dpmEmployee.DPM_Suffix__c
                                            ) 
                                            OR (
                                                (LastName=:dpmEmployee.DPM_Last_Name__c OR DPM_Lastname_Soundex__c=:DPM_Soundex.toSoundex(dpmEmployee.DPM_Last_Name__c)) 
                                                AND DPM_Preferred_First_Name__c!= NULL 
                                                AND (DPM_Preferred_First_Name__c=:dpmEmployee.DPM_Preferred_First_Name__c OR DPM_Preferred_FirstName_Soundex__c=:DPM_Soundex.toSoundex(dpmEmployee.DPM_Preferred_First_Name__c)) 
                                                AND Suffix=:dpmEmployee.DPM_Suffix__c
                                            )
                                        )
                                        ORDER BY CreatedDate DESC];
        
        //Check for matching Person Roles
        List<RE_Person_Role__c> lstMatchingPersonRoles = new List<RE_Person_Role__c>();
        lstMatchingPersonRoles = [SELECT Id,RE_Account__r.Name,RE_Account__r.BillingState,DPM_Work_Phone__c,DPM_Work_Email__c FROM RE_Person_Role__c
                                  WHERE (DPM_Work_Phone__c!= NULL AND DPM_Work_Phone__c=:dpmEmployee.DPM_Cell_Phone__c)
                                  OR DPM_Work_Email__c=:dpmEmployee.DPM_Email__c
                                  ORDER BY CreatedDate DESC];
        
        //Check for matching Users
        List<User> lstMatchingUsers = new List<User>();
        //Get placebo stores
        List<Account> lstPlaceboAccounts = new List<Account>();
        if(!lstMatchingRetailerEmployees.isEmpty() || !lstMatchingPersonRoles.isEmpty()) {
            lstPlaceboAccounts = [SELECT Id,Name FROM Account 
                                  WHERE BillingState = :strStateForPlaceboStores AND Id NOT IN :setAccountIds AND RecordType.Name = 'Retailer'
                                  LIMIT 3];
        }        
        if(!lstMatchingRetailerEmployees.isEmpty()) {            
            for(Contact c: lstMatchingRetailerEmployees) {
                if(!setAccountIds.contains(c.AccountId)) {
                    dpmDuplicateResult.dpmDuplicates.add(new DPM_DuplicateRecord('Contact',c.Id,c.Account.Name,false,c));
                    setAccountIds.add(c.AccountId);
                    if(strStateForPlaceboStores == '' && c.Account.BillingState != NULL) {
                        strStateForPlaceboStores = c.Account.BillingState;
                    }
                } 
                if(lstMatchingUsers.isEmpty()) {
                    if(dpmDuplicateResult.dpmDuplicates.size() == 3) {
                        break;
                    }
                } else {
                    if(dpmDuplicateResult.dpmDuplicates.size() == 2) {
                        break;
                    }
                }
            }
        }
        if(!lstMatchingPersonRoles.isEmpty()) {
            for(RE_Person_Role__c pr: lstMatchingPersonRoles) {
                if(!setAccountIds.contains(pr.RE_Account__c)) {
                    dpmDuplicateResult.dpmDuplicates.add(new DPM_DuplicateRecord('Person Role',pr.Id,pr.RE_Account__r.Name,false,pr));
                    setAccountIds.add(pr.RE_Account__c);
                    if(strStateForPlaceboStores == '' && pr.RE_Account__r.BillingState != NULL) {
                        strStateForPlaceboStores = pr.RE_Account__r.BillingState;
                    }
                }
                if(lstMatchingUsers.isEmpty()) {
                    if(dpmDuplicateResult.dpmDuplicates.size() == 3) {
                        break;
                    }
                } else {
                    if(dpmDuplicateResult.dpmDuplicates.size() == 2) {
                        break;
                    }
                }                
            }
        }
        if(!lstPlaceboAccounts.isEmpty()) {
            for(Account a: lstPlaceboAccounts) {
                dpmDuplicateResult.dpmDuplicates.add(new DPM_DuplicateRecord('Account',a.Id,a.Name,true,a));
                if(lstMatchingUsers.isEmpty()) {
                    if(dpmDuplicateResult.dpmDuplicates.size() == 4) {
                        break;
                    }
                } else {
                    if(dpmDuplicateResult.dpmDuplicates.size() == 3) {
                        break;
                    }
                }
            }
        }
        if(!lstMatchingUsers.isEmpty()) {
            for(User u: lstMatchingUsers) {
                dpmDuplicateResult.dpmDuplicates.add(new DPM_DuplicateRecord('User',u.Id,'I worked for VCC',false,u));
            }
        }        
        dpmDuplicateResult.hasDuplicates = (dpmDuplicateResult.dpmDuplicates.size()>0);
        if(dpmDuplicateResult.hasDuplicates) {
            dpmDuplicateResult.dpmDuplicates.add(new DPM_DuplicateRecord('None','None','None of the above',false,NULL));
        }        
        return dpmDuplicateResult;
    }
    public static List<Contact> findMatchingEmployeeProfiles(String strDPMEmployee) {
        DPM_Employee__c dpmEmployee = (DPM_Employee__c) JSON.deserialize(strDPMEmployee, DPM_Employee__c.class);        
        List<Contact> lstMatchingContacts = new List<Contact>();
        List<String> listOfRetailerIds = new List<String>();
        for(DPM_Configuration__mdt dpmCon : [SELECT Id, DeveloperName, DPM_Retailer_Codes_for_Access__c, DPM_Additional_Accounts_for_Search__c FROM DPM_Configuration__mdt WHERE DeveloperName = 'DPM_Employee']) {
            if(String.isNotBlank(dpmCon.DPM_Retailer_Codes_for_Access__c)) {
                listOfRetailerIds.addAll(dpmCon.DPM_Retailer_Codes_for_Access__c.split(';'));
            }
            if(String.isNotBlank(dpmCon.DPM_Additional_Accounts_for_Search__c)) {
                listOfRetailerIds.addAll(dpmCon.DPM_Additional_Accounts_for_Search__c.split(';'));
            }
        }
        lstMatchingContacts = [SELECT Id,Employee_Hired_Date__c,MailingStreet,MailingAddress,MailingState,MailingCountry,MailingPostalCode,FirstName,MiddleName,LastName,MailingCity,Suffix,DPM_Preferred_First_Name__c,DPM_Gender__c,DPM_Other_Gender__c,Salutation,Email,Phone,DPM_Personal_Email__c,
                               DPM_Ethnicity__c,DPM_US_Military__c,DPM_Language_1__c,DPM_Language_2__c,DPM_Language_3__c,DPM_Proficiency_1__c,DPM_Proficiency_2__c,DPM_Proficiency_3__c,DPM_Race__c,
                               (SELECT Id,RE_Account__r.Name,RE_Account__r.Retailer__c,RE_Employee_Position__c,RE_Psn_Active__c,RE_Psn_Active_Date__c,RE_Psn_NonActive_Date__c FROM Person_Roles__r),
                               DPM_Firstname_Soundex__c,DPM_Lastname_Soundex__c,DPM_Preferred_FirstName_Soundex__c
                               FROM Contact 
                               WHERE (RecordType.Name='Retailer Employee' OR Account.Retailer__c IN :listOfRetailerIds)
                               AND (
                                   Email=:dpmEmployee.DPM_Email__c
                                   OR DPM_Personal_Email__c=:dpmEmployee.DPM_Email__c
                                   OR DPM_Additional_Email_1__c=:dpmEmployee.DPM_Email__c
                                   OR DPM_Additional_Email_2__c=:dpmEmployee.DPM_Email__c
                                   OR (Phone!=NULL AND Phone=:dpmEmployee.DPM_Cell_Phone__c)
                                   OR (DPM_SSN__c!=NULL AND DPM_SSN__c=:dpmEmployee.DPM_SSN_SIN__c)
                                   OR (HomePhone!=NULL AND HomePhone=:dpmEmployee.DPM_Cell_Phone__c) 
                                   OR (OtherPhone!=NULL AND OtherPhone=:dpmEmployee.DPM_Cell_Phone__c)
                                   OR (LastName=:dpmEmployee.DPM_Last_Name__c AND FirstName=:dpmEmployee.DPM_Legal_First_Name__c AND Suffix=:dpmEmployee.DPM_Suffix__c) 
                                   OR (LastName=:dpmEmployee.DPM_Last_Name__c AND DPM_Preferred_First_Name__c!= NULL AND DPM_Preferred_First_Name__c=:dpmEmployee.DPM_Preferred_First_Name__c AND Suffix=:dpmEmployee.DPM_Suffix__c)
                                   OR (DPM_Lastname_Soundex__c=:DPM_Soundex.toSoundex(dpmEmployee.DPM_Last_Name__c) AND DPM_FirstName_Soundex__c=:DPM_Soundex.toSoundex(dpmEmployee.DPM_Legal_First_Name__c) AND Suffix=:dpmEmployee.DPM_Suffix__c) 
                                   OR (DPM_Lastname_Soundex__c=:DPM_Soundex.toSoundex(dpmEmployee.DPM_Last_Name__c) AND DPM_Preferred_FirstName_Soundex__c != NULL AND DPM_Preferred_FirstName_Soundex__c=:DPM_Soundex.toSoundex(dpmEmployee.DPM_Preferred_First_Name__c) AND Suffix=:dpmEmployee.DPM_Suffix__c)
                               )
                              ];
        return lstMatchingContacts;
    }
    public static List<Contact> findMatchingEmployeeProfiles_SelfReg(String idContact) {
        List<Contact> lstMatchingContacts = new List<Contact>();
        lstMatchingContacts = [SELECT Id,FirstName,MiddleName,LastName,Suffix,DPM_Preferred_First_Name__c,DPM_Gender__c,DPM_Other_Gender__c,Salutation,Email,Phone,DPM_Personal_Email__c,
                               (SELECT Id,RE_Account__r.Name,RE_Account__r.Retailer__c,RE_Employee_Position__c,RE_Psn_Active__c,RE_Psn_Active_Date__c,RE_Psn_NonActive_Date__c FROM Person_Roles__r)
                               FROM Contact 
                               WHERE Id = :idContact
                              ];
        return lstMatchingContacts;
    }
    public static Boolean checkDPMAccess(RE_Person_Role__c personRole) {
        DPM_Configuration__mdt dpmConfig = getDPMConfigCustomMetadata();
        List<String> lstRetailerCodes = new List<String>();
        List<String> lstSupplierCodes = new List<String>();
        lstRetailerCodes = dpmConfig.DPM_Retailer_Codes_for_Access__c.split(';');
        lstSupplierCodes = dpmConfig.DPM_Additional_Accounts_for_Search__c .split(';');
        lstRetailerCodes.addAll(lstSupplierCodes);
        if(!lstRetailerCodes.isEmpty() && personRole!=NULL) {
            return lstRetailerCodes.contains(personRole.RE_Account__r.Retailer__c);
        }
        return false;
    }
    public static DPM_LogData performCalloutFromLog(Id idLog) {
        DPM_Log__c dpmLog = [SELECT Id,DPM_Request_Body__c,DPM_type__c,DPM_Callout_Endpoint__c,DPM_Integration_Method__c FROM DPM_Log__c WHERE Id = :idLog];
        DPM_LogData logData = new DPM_LogData();
        OSD_System_API__mdt mulesoftIDMAPI = getIDMEndpoint();
        HttpRequest req = new HttpRequest();        
        req.setMethod(dpmLog.DPM_Integration_Method__c);
        req.setHeader('Authorization', getAuthorizationHeader(mulesoftIDMAPI));
        req.setHeader('Content-Type', 'application/json');
        req.setBody(dpmLog.DPM_Request_Body__c);
        req.setEndpoint(dpmLog.DPM_Callout_Endpoint__c);
        req.setTimeout(intTimeout);
        try {
            HttpResponse res = new Http().send(req);
            logData.intResponseCode = res.getStatusCode();
            if(!lstValidResponseCodes.contains(logData.intResponseCode)) {
                logData.objDPMLog = new DPM_Log__c();
                logData.objDPMLog.DPM_Request_Body__c = req.getBody();
                logData.objDPMLog.DPM_Response_Body__c = res.getStatusCode()+' : '+res.getBody();
                logData.objDPMLog.DPM_Callout_Endpoint__c = req.getEndpoint();
                logData.objDPMLog.DPM_Integration_Method__c = req.getMethod();
                logData.strResponse = 'Error: ';
            } else {
                logData.strResponse = 'Success: ';
            } 
            logData.strResponse += res.getStatusCode()+' : '+res.getBody();
            return logData;
        } catch(Exception e) {
            logData.intResponseCode = 500;
            logData.objDPMLog = new DPM_Log__c();
            logData.objDPMLog.DPM_Request_Body__c = req.getBody();
            logData.objDPMLog.DPM_Response_Body__c = 'Error: '+e.getMessage();
            logData.objDPMLog.DPM_Callout_Endpoint__c = req.getEndpoint();
            logData.objDPMLog.DPM_Integration_Method__c = req.getMethod();
            return logData;
        }                 
    }
    @future(callout=true)
    public static void performCallouts(String strCalloutType, String strCalloutDetails) {
        List<DPM_Log__c> lstDPMLogsToInsert = new List<DPM_Log__c>();
        if(strCalloutType == 'IDMUpdate') {
            List<DPM_ContactTriggerHelper.IDMUpdateRequest> lstIDMUpdateReq=(List<DPM_ContactTriggerHelper.IDMUpdateRequest>)JSON.deserialize(strCalloutDetails,List<DPM_ContactTriggerHelper.IDMUpdateRequest>.class);
            for(DPM_ContactTriggerHelper.IDMUpdateRequest objIDMUpdateRequest : lstIDMUpdateReq) {
                DPM_LogData logData = DPM_PersonnelMasterServices.callIDMToUpdateEmployeeData(objIDMUpdateRequest.strCDSID,objIDMUpdateRequest.strNewValue,objIDMUpdateRequest.strOldValue,objIDMUpdateRequest.strField,objIDMUpdateRequest.personRoleId);
                if(logData.intResponseCode!=NULL && !lstValidResponseCodes.contains(logData.intResponseCode)) {
                    logData.objDPMLog.RecordTypeId = DPM_PersonnelMasterServicesExt.idOfDpmIntegrationErrorRecordType;
                    lstDPMLogsToInsert.add(logData.objDPMLog);
                }
            }
        }
        if(strCalloutType == 'IDMUpdate_Contact') {
            List<DPM_ContactTriggerHelper.IDMUpdateRequest> lstIDMUpdateReq=(List<DPM_ContactTriggerHelper.IDMUpdateRequest>)JSON.deserialize(strCalloutDetails,List<DPM_ContactTriggerHelper.IDMUpdateRequest>.class);
            Set<Id> setContactIds = new Set<Id>();
            for(DPM_ContactTriggerHelper.IDMUpdateRequest IDMUpdateReq : lstIDMUpdateReq) {
                setContactIds.add(IDMUpdateReq.idContact);
            }
            Map<Id,List<String>> mapContactIdToLstCDSID = new Map<Id,List<String>>();
            Map<String,Id> mapCDSIDToPersonRoleId = new Map<String,Id>();
            for(RE_Person_Role__c personRole : [SELECT Id,RE_Contact__c,DPM_CDS_Id__c FROM RE_Person_Role__c WHERE RE_Contact__c IN :setContactIds]) {
                if(personRole.DPM_CDS_Id__c != NULL) {
                    if(!mapContactIdToLstCDSID.keyset().contains(personRole.RE_Contact__c)) {
                        mapContactIdToLstCDSID.put(personRole.RE_Contact__c,new list<String>());
                    }
                    mapContactIdToLstCDSID.get(personRole.RE_Contact__c).add(personRole.DPM_CDS_Id__c);
                    mapCDSIDToPersonRoleId.put(personRole.DPM_CDS_Id__c,personRole.Id);
                }                
            }
            for(DPM_ContactTriggerHelper.IDMUpdateRequest objIDMUpdateRequest : lstIDMUpdateReq) {
                if(mapContactIdToLstCDSID.keyset().contains(objIDMUpdateRequest.idContact)) {
                    for(String strCDSID : mapContactIdToLstCDSID.get(objIDMUpdateRequest.idContact)) {
                        DPM_LogData logData = DPM_PersonnelMasterServices.callIDMToUpdateEmployeeData(strCDSID,objIDMUpdateRequest.strNewValue,objIDMUpdateRequest.strOldValue,objIDMUpdateRequest.strField,objIDMUpdateRequest.personRoleId);
                        if(logData.intResponseCode!=NULL && !lstValidResponseCodes.contains(logData.intResponseCode)) {
                            logData.objDPMLog.DPM_Person_Role__c = mapCDSIDToPersonRoleId.get(strCDSID);
                            logData.objDPMLog.RecordTypeId = DPM_PersonnelMasterServicesExt.idOfDpmIntegrationErrorRecordType;
                            lstDPMLogsToInsert.add(logData.objDPMLog);
                        }
                    }
                }
            }
        }
        if(strCalloutType == 'IDMCreate') {
            Set<Id> setContactIds = (Set<Id>)JSON.deserialize(strCalloutDetails,Set<Id>.class);
            for(Id idContact : setContactIds) {
                DPM_LogData logData = DPM_PersonnelMasterServices.callIDMForCDSIDCreation(idContact,NULL,'New',false);
                if(logData.intResponseCode!=NULL && !lstValidResponseCodes.contains(logData.intResponseCode)) {
                    logData.objDPMLog.RecordTypeId = DPM_PersonnelMasterServicesExt.idOfDpmIntegrationErrorRecordType;
                    lstDPMLogsToInsert.add(logData.objDPMLog);
                }
            }
        }
        if(strCalloutType == 'IDMCreate_Approved') {
            DPM_Employee__c dpmEmployee = (DPM_Employee__c)JSON.deserialize(strCalloutDetails,DPM_Employee__c.class);
            DPM_LogData logData = DPM_PersonnelMasterServices.callIDMForCDSIDCreation(NULL,dpmEmployee.Id,dpmEmployee.DPM_Request_Type__c,false);
            if(logData.intResponseCode!=NULL && !lstValidResponseCodes.contains(logData.intResponseCode)) {
                logData.objDPMLog.RecordTypeId = DPM_PersonnelMasterServicesExt.idOfDpmIntegrationErrorRecordType;
                lstDPMLogsToInsert.add(logData.objDPMLog);
            }
        }
        if(strCalloutType == 'EncryptDecryptSSN') {
            Map<Id,String> mapContactIdToType = (Map<Id,String>)JSON.deserialize(strCalloutDetails,Map<Id,String>.class);
            List<Contact> lstContactToUpdate = new List<Contact>();
            for(Contact c : [SELECT Id,DPM_SSN__c,DPM_SSNEncrypted__c FROM Contact WHERE Id IN :mapContactIdToType.keyset()]) {
                if(mapContactIdToType.get(c.Id) == 'Encrypt') {
                    lstContactToUpdate.add(encryptSSN(c));
                }
                if(mapContactIdToType.get(c.Id) == 'Decrypt') {
                    lstContactToUpdate.add(decryptSSN(c));
                }
            }
            if(!lstContactToUpdate.isEmpty()) {
                contexec=false;
                update lstContactToUpdate;
            }
        }
        if(!lstDPMLogsToInsert.isEmpty()) {
            insert lstDPMLogsToInsert;
        }
    }
     public static DPM_LogData callIDMForCDSIDCreation(Id idContact,Id idDPMEmployee,String strType,Boolean blnOracleDecom) {
        OSD_System_API__mdt mulesoftIDMAPI = getIDMEndpoint();
        DPM_LogData logData = new DPM_LogData();
        if(mulesoftIDMAPI != NULL) {
            IDMRequest_CDSID createCDSIDReq = new IDMRequest_CDSID();
            DPM_Employee__c dpmEmployee =  new DPM_Employee__c();
            if(idDPMEmployee == NULL) {
                dpmEmployee = [SELECT Id,DPM_Account__r.DPM_Global_Retailer_Code__c,DPM_Account__r.Org_activated__c,DPM_Contact__c,DPM_Contact__r.PsnId__c,DPM_Contact__r.DPM_VPID__c,DPM_Email__c,DPM_Cell_Phone__c,
                               DPM_Country__c,DPM_Canadian_State__c,DPM_US_State__c,DPM_Legal_First_Name__c,DPM_Last_Name__c,DPM_City__c,DPM_Personal_Email__c,
                               (SELECT Id,Name,DPM_Primary__c FROM DPM_Job_Positions__r WHERE DPM_End_Date__c=NULL OR DPM_End_Date__c>=TODAY)
                                               FROM DPM_Employee__c WHERE DPM_Contact__c = :idContact AND DPM_Status__c = 'Approved' ORDER BY LastModifiedDate DESC LIMIT 1];
            } else {
                dpmEmployee = [SELECT Id,DPM_Account__r.DPM_Global_Retailer_Code__c,DPM_Contact__c,DPM_Contact__r.PsnId__c,DPM_Contact__r.DPM_VPID__c,DPM_Email__c,DPM_Cell_Phone__c,
                               DPM_Country__c,DPM_Canadian_State__c,DPM_US_State__c,DPM_Legal_First_Name__c,DPM_Last_Name__c,DPM_City__c,DPM_Personal_Email__c,
                               (SELECT Id,Name,DPM_Primary__c FROM DPM_Job_Positions__r WHERE DPM_End_Date__c=NULL OR DPM_End_Date__c>=TODAY)
                                               FROM DPM_Employee__c WHERE Id = :idDPMEmployee];
            }
            createCDSIDReq.firstname = dpmEmployee.DPM_Legal_First_Name__c;
            createCDSIDReq.lastname = dpmEmployee.DPM_Last_Name__c;
            if(dpmEmployee.DPM_City__c != null){
                createCDSIDReq.city = dpmEmployee.DPM_City__c;
            }
            if(dpmEmployee.DPM_Country__c == 'United States') {
                createCDSIDReq.country = 'US';
            } else if(dpmEmployee.DPM_Country__c == 'Mexico') {
                createCDSIDReq.country = 'MEX';
            } else {
                createCDSIDReq.country = 'CAN';
            }
            createCDSIDReq.mailaddress = dpmEmployee.DPM_Email__c;
            //Replace job postion description with abbreviation
            Map<String,String> abbreviationMap=new Map<String,String>();
            for(RE_Job_to_Persona_map__mdt job:[SELECT MasterLabel,Job_Abbr__c FROM RE_Job_to_Persona_map__mdt]){
                String abbreviation=job.Job_Abbr__c;
                //check if abbreviation has length of 3 or not
                if(abbreviation!=null && abbreviation.length()<3){
                   if(abbreviation.length()==2){
                     abbreviation='0'+abbreviation;  
                   }
                   if(abbreviation.length()==1){
                     abbreviation='00'+abbreviation;  
                   }
                }
                abbreviation=abbreviation.trim();
                abbreviationMap.put(job.MasterLabel,abbreviation);
            }
            //send only abbreviation instead of description
            String primaryPositionStr='';
            String secondaryPositionsStr='';
            for(DPM_Job_Position__c job:dpmEmployee.DPM_Job_Positions__r){
                if(job.DPM_Primary__c){
                    primaryPositionStr+=abbreviationMap.get(job.Name)+';';
                }else{
                    secondaryPositionsStr+=abbreviationMap.get(job.Name)+';';
                }
            }
            string allpositionsstr='';
            if(primaryPositionStr!=''){
                primaryPositionStr=primaryPositionStr.trim();
                allpositionsstr+=primaryPositionStr;
            }
            if(secondaryPositionsStr!=''){
                secondaryPositionsStr=secondaryPositionsStr.trim();
                allpositionsstr+=secondaryPositionsStr;
            }
            allpositionsstr=allpositionsstr.removeEnd(';');
            createCDSIDReq.title = allpositionsstr;
            if(dpmEmployee.DPM_Cell_Phone__c != null){
                createCDSIDReq.phonenumber = String.valueOf(dpmEmployee.DPM_Cell_Phone__c);
            } 
            createCDSIDReq.partnertype = 'Retailer';
            createCDSIDReq.cdsstatus = 'true';
            createCDSIDReq.dealercode = dpmEmployee.DPM_Account__r.DPM_Global_Retailer_Code__c;
            createCDSIDReq.cdsvpid = (blnOracleDecom?string.valueOf(dpmEmployee.DPM_Contact__r.DPM_VPID__c):dpmEmployee.DPM_Contact__r.PsnId__c);            
            createCDSIDReq.altemail = dpmEmployee.DPM_Personal_Email__c;
            HttpRequest req = new HttpRequest();        
            req.setMethod('POST');
            req.setHeader('Authorization', getAuthorizationHeader(mulesoftIDMAPI));
            req.setHeader('Content-Type', 'application/json');
            system.debug('asd123$ '+JSON.serialize(createCDSIDReq,true));
            req.setBody(JSON.serialize(createCDSIDReq,true));
            req.setEndpoint(mulesoftIDMAPI.Base_URI__c);
            req.setTimeout(intTimeout);
            try {
                HttpResponse res = new Http().send(req);
                //Create Log Data
                logData.intResponseCode = res.getStatusCode();                
                if(!lstValidResponseCodes.contains(logData.intResponseCode)) {
                    logData.objDPMLog = new DPM_Log__c();
                    logData.objDPMLog.DPM_Request_Body__c = req.getBody();
                    //logData.objDPMLog.DPM_Response_Body__c = res.getStatusCode()+' : '+res.getBody();
                    if(String.valueOf(res.getStatusCode()+' : '+res.getBody()).length()<254){
                    	logData.objDPMLog.DPM_Response_Body__c = String.valueOf(res.getStatusCode()+' : '+res.getBody());
                    }else{
                        logData.objDPMLog.DPM_Response_Body__c = String.valueOf(res.getStatusCode()+' : '+res.getBody()).subString(0,254);
                    }
                    logData.objDPMLog.DPM_Callout_Endpoint__c = req.getEndpoint();
                    logData.objDPMLog.DPM_Contact__c = dpmEmployee.DPM_Contact__c;
                    logData.objDPMLog.DPM_Integration_Method__c = req.getMethod();
                    logData.strResponse = 'Error: ';
                } else {
                    logData.strResponse = 'Success: ';
                }
                logData.strResponse += res.getStatusCode()+' : '+res.getBody();
                return logData;
            } catch(Exception e) {
                logData.intResponseCode = 500;
                logData.strResponse = 'Error: '+e.getMessage();
                logData.objDPMLog = new DPM_Log__c();
                logData.objDPMLog.DPM_Request_Body__c = req.getBody();
                //logData.objDPMLog.DPM_Response_Body__c = e.getMessage();
                if(String.valueOf(e+'\n'+e.getMessage()+'\n'+e.getStackTraceString()).length()<254){
                	logData.objDPMLog.DPM_Response_Body__c = String.valueOf(e+'\n'+e.getMessage()+'\n'+e.getStackTraceString());
                }else{
                    logData.objDPMLog.DPM_Response_Body__c = String.valueOf(e+'\n'+e.getMessage()+'\n'+e.getStackTraceString()).subString(0,254);
                }
                logData.objDPMLog.DPM_Callout_Endpoint__c = req.getEndpoint();
                logData.objDPMLog.DPM_Contact__c = dpmEmployee.DPM_Contact__c;
                logData.objDPMLog.DPM_Integration_Method__c = req.getMethod();
                return logData;
            }                       
            //System.debug(res.getBody());
        }
        return logData;
    }
    
    public static DPM_LogData callIDMToUpdateEmployeeData(String strCDSID, String strNewValue, String strOldValue, String strField,string personRoleId) {
        string allpositionsstr='';
        RE_Person_Role__c personRoleObj;
        if(strField!=null && strField.equals('title')){
            system.debug('strField-=-=>'+strField);
            //Replace job postion description with abbreviation
            Map<String,String> abbreviationMap=new Map<String,String>();
            for(RE_Job_to_Persona_map__mdt job:[SELECT MasterLabel,Job_Abbr__c FROM RE_Job_to_Persona_map__mdt]){
                String abbreviation=job.Job_Abbr__c;
                //check if abbreviation has length of 3 or not
                if(abbreviation!=null && abbreviation.length()<3){
                    if(abbreviation.length()==2){
                        abbreviation='0'+abbreviation;  
                    }
                    if(abbreviation.length()==1){
                        abbreviation='00'+abbreviation;  
                    }
                }
                abbreviation=abbreviation.trim();
                abbreviationMap.put(job.MasterLabel,abbreviation);
            }
            try{
                personRoleObj=[select Id, DPM_CDS_Id__c,DPM_Work_Email__c,DPM_OldJob_Titles__c,
                                             (SELECT Id, Name, DPM_Position_Title__c, DPM_Primary_Position__c 
                                              FROM DPM_Job_Positions__r 
                                              WHERE DPM_Position_End_Date__c=NULL OR DPM_Position_End_Date__c>=TODAY) 
                                             from RE_Person_Role__c
                                            WHERE DPM_CDS_Id__c=:strCDSID and id =:personRoleId ]; 
            }
            catch(exception e){
                system.debug('error-->'+e);
            }
                                                       

            String primaryPositionStr='';
            String secondaryPositionsStr='';
            for(DPM_EmployeeJobPosition__c job:personRoleObj.DPM_Job_Positions__r){
                if(job.DPM_Primary_Position__c){
                    primaryPositionStr+=abbreviationMap.get(job.DPM_Position_Title__c)+';';
                }else{
                    secondaryPositionsStr+=abbreviationMap.get(job.DPM_Position_Title__c)+';';
                }
            }
            
            if(primaryPositionStr!=''){
                primaryPositionStr=primaryPositionStr.trim();
                allpositionsstr+=primaryPositionStr;
            }
            if(secondaryPositionsStr!=''){
                secondaryPositionsStr=secondaryPositionsStr.trim();
                allpositionsstr+=secondaryPositionsStr;
            }
            allpositionsstr=allpositionsstr.removeEnd(';');
           	strNewValue=allpositionsstr;
            if(personRoleObj.DPM_OldJob_Titles__c!=null){
           		strOldValue=personRoleObj.DPM_OldJob_Titles__c;
            }else{
                if(abbreviationMap.containsKey(strOldValue)){
                	strOldValue=abbreviationMap.get(strOldValue);
                }
            }
        }
        OSD_System_API__mdt mulesoftIDMAPI = getIDMEndpoint();
        DPM_LogData logData = new DPM_LogData();
        if(mulesoftIDMAPI != NULL && strCDSID != NULL) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(mulesoftIDMAPI.Base_URI__c+'/'+strCDSID.split('@')[0]);
            req.setMethod('PUT');
            //req.setTimeout(1);  
            req.setTimeout(intTimeout);                       
            req.setHeader('Content-Type', 'application/json');
            String strBody = '{"'+strField+'":[{'+'"remove":["'+strOldValue+'"]},{"add":["'+strNewValue+'"]}]}';
            if(strField == 'CDSIDSwitch') {
                strBody = '{"cdsstatus":[{'+'"remove":["true"]},{"add":["false"]}],"secondarycdsid":[{"add":["'+strNewValue.split('@')[0]+'"]}]}';
            }
            if(strField == 'buySell') {
                strBody = '{"dealercode":[{'+'"remove":["'+strOldValue+'"]},{"add":["'+strNewValue+'"]}],"isbuysell":[{"add":["true"]}]}';
            }
            system.debug(strBody);
            req.setBody(strBody);
            req.setHeader('Authorization', getAuthorizationHeader(mulesoftIDMAPI));
            req.setHeader('Content-Type', 'application/json');
            try {
                HttpResponse res = new Http().send(req);
                logData.intResponseCode = res.getStatusCode();
                logData.strResponse = res.getStatusCode()+' : '+res.getBody();
                if(!lstValidResponseCodes.contains(logData.intResponseCode)) {
                    logData.objDPMLog = new DPM_Log__c();
                    logData.objDPMLog.DPM_Request_Body__c = req.getBody();
                    //logData.objDPMLog.DPM_Response_Body__c = res.getStatusCode()+' : '+res.getBody();
                    if(String.valueOf(res.getStatusCode()+' : '+res.getBody()).length()<254){
                    	logData.objDPMLog.DPM_Response_Body__c = String.valueOf(res.getStatusCode()+' : '+res.getBody());
                    }else{
                        logData.objDPMLog.DPM_Response_Body__c = String.valueOf(res.getStatusCode()+' : '+res.getBody()).subString(0,254);
                    }
                    logData.objDPMLog.DPM_Callout_Endpoint__c = req.getEndpoint();
                    logData.objDPMLog.DPM_Integration_Method__c = req.getMethod();
                    logData.strResponse = 'Error: ';
                } else {
                    logData.strResponse = 'Success: ';
                    if(strField!=null && strField.equals('title') && personRoleObj != null){
                        personRoleObj.DPM_OldJob_Titles__c=allpositionsstr; 
                        RE_Person_RoleTriggerStatic.dpm_stop_flag=true;
                        update personRoleObj;
                    }
                }
                logData.strResponse += res.getStatusCode()+' : '+res.getBody();
                return logData;
            } catch(Exception e) {
                logData.intResponseCode = 500;
                logData.strResponse = 'Error: '+e.getMessage();
                logData.objDPMLog = new DPM_Log__c();
                logData.objDPMLog.DPM_Request_Body__c = req.getBody();
               // logData.objDPMLog.DPM_Response_Body__c = e.getMessage();
                if(String.valueOf(e+'\n'+e.getStackTraceString()+'\n'+e.getMessage()).length()<254){
                	logData.objDPMLog.DPM_Response_Body__c = String.valueOf(e+'\n'+e.getStackTraceString()+'\n'+e.getMessage());
                }else{
                    logData.objDPMLog.DPM_Response_Body__c = String.valueOf(e+'\n'+e.getStackTraceString()+'\n'+e.getMessage()).subString(0,254);
                }
                logData.objDPMLog.DPM_Callout_Endpoint__c = req.getEndpoint();
                logData.objDPMLog.DPM_Integration_Method__c = req.getMethod();
                return logData;
            }
        }
        return logData;
    }

    
    //1/18/2021, encrypt ssn on contact
    public static Contact encryptSSN(Contact con){
        OSD_System_API__mdt auth;
        String strEnv='Production';
        String strEndpointType='DPM Encryption';
        auth = [SELECT Id,Auth_Password__c,Auth_Username__c,Base_URI__c,Enabled__c,RE_Environment__c,Order_URI__c,RE_Type__c FROM OSD_System_API__mdt WHERE RE_Type__c = :strEndpointType AND RE_Environment__c = :strEnv AND Enabled__c = TRUE LIMIT 1];
            //getEncryptionServiceEndpoint();
        String endpoint_uri = auth.Base_URI__c;
        String params='"'+con.DPM_SSN__c+'"'; 
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint_uri);
        req.setMethod('POST');
        req.setTimeout(intTimeout);                       
        req.setHeader('Content-Type', 'application/json');
        String authorizationHeader = getAuthorizationHeader(auth);
        req.setHeader('Authorization', authorizationHeader); 
        req.setBody(params);        
        Http h = new Http();
        String resp;
        HttpResponse res = h.send(req);
        resp = res.getBody();
        Map<String,Object> respmp=(Map<String,Object>)JSON.deserializeUntyped(resp);
        if(respmp!=null && respmp.containsKey('message')){
            con.DPM_SSNEncrypted__c=(String)respmp.get('message');
            return con;     
        }
        return NULL;
    }    
    //1/27/2021, decrypt ssn_encrypted field on contact
    public static Contact decryptSSN(Contact con){
        OSD_System_API__mdt auth ;
        String strEnv='Production';
        String strEndpointType='DPM Decryption';
        auth = [SELECT Id,Auth_Password__c,Auth_Username__c,Base_URI__c,Enabled__c,RE_Environment__c,Order_URI__c,RE_Type__c FROM OSD_System_API__mdt WHERE RE_Type__c = :strEndpointType AND RE_Environment__c = :strEnv AND Enabled__c = TRUE LIMIT 1];
         
        //= getDecryptionServiceEndpoint();
        String endpoint_uri = auth.Base_URI__c;
        String params='"'+con.DPM_SSNEncrypted__c+'"'; 
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint_uri);
        req.setMethod('POST');
        req.setTimeout(intTimeout);                       
        req.setHeader('Content-Type', 'application/json');
        String authorizationHeader = getAuthorizationHeader(auth);
        req.setHeader('Authorization', authorizationHeader); 
        req.setBody(params);
        Http h = new Http();
        String resp;
        HttpResponse res = h.send(req);
        resp = res.getBody();
        Map<String,Object> respmp=(Map<String,Object>)JSON.deserializeUntyped(resp);
        if(respmp!=null && respmp.containsKey('message')){
            con.DPM_SSN__c=(String)respmp.get('message');
            con.DPM_SSN__c = con.DPM_SSN__c.replaceAll('-','');
            return con;     
        }    
        return NULL;
    } 
    private static OSD_System_API__mdt getIDMEndpoint() {
        return getEndpoint(strIntegrationType);
    }
    private static OSD_System_API__mdt getEncryptionServiceEndpoint() {
        return getEndpoint(strEncryptionEndPointType);
    }
    private static OSD_System_API__mdt getDecryptionServiceEndpoint() {
        return getEndpoint(strDecryptionEndPointType);
    }
    private static OSD_System_API__mdt getEndpoint(String strEndpointType) {
        Boolean runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        String strEnv = runningInASandbox?'Sandbox':'Production';
        OSD_System_API__mdt mulesoftIDMAPI = [SELECT Id,Auth_Password__c,Auth_Username__c,Base_URI__c,Enabled__c,RE_Environment__c,Order_URI__c,RE_Type__c FROM OSD_System_API__mdt WHERE RE_Type__c = :strEndpointType AND RE_Environment__c = :strEnv AND Enabled__c = TRUE LIMIT 1];
        return mulesoftIDMAPI;
    }
    private static String getAuthorizationHeader(OSD_System_API__mdt connectionDetails) {
        Blob credentials = Blob.valueOf(connectionDetails.Auth_Username__c + ':' + connectionDetails.Auth_Password__c);        
        return 'Basic ' + EncodingUtil.base64Encode(credentials);
    }
    //Wrapper Classes 
    public class DPM_LogData {
        @AuraEnabled public Integer intResponseCode;
        @AuraEnabled public String strResponse;
        @AuraEnabled public DPM_Log__c objDPMLog;
    }   
    public class DPM_SessionSettings {
        public String sortBy;
        public String sortDirection;
        public String filterBy;
        public String filterString;
        public Integer intOffset;
        public Integer intLimit;
        public Boolean showViewMore;        
        public Boolean showViewMoreDPMEmployees;
        public Boolean skipOffset;
    }
    public class DPM_SearchEmployee {
        public String firstName;
        public String lastName;
        public String suffix;
        public String email;
        public String store_SFId;
        public String storeName;
        public String country;
        public String jobPosition;
        public Boolean showInactiveEmployees;
        public Boolean primaryJobOnly;
        public Boolean fromPortal;        
        public Boolean retailerAdmin;
        public Boolean owner;
        public String VPID;        
        public String SSN;
    }
    public class DPM_SearchResults {
        @AuraEnabled public List<RE_Person_Role__c> lstPersonRole=new List<RE_Person_Role__c>();
        @AuraEnabled public Integer intTotalResults;
        @AuraEnabled public Integer intTotalDPMEmployeeResults;
        @AuraEnabled public List<DPM_EmployeeJobPosition__c> lstJobPositions=new List<DPM_EmployeeJobPosition__c>();
        @AuraEnabled public Boolean blnIsIncentiveProfile;
        @AuraEnabled public List<DPM_Employee__c> lstDPMEmployees=new List<DPM_Employee__c>();
        @AuraEnabled public String RetailerId;
    }
    public class DPM_DuplicateCheckResult {
        @AuraEnabled public Boolean hasDuplicates;
        @AuraEnabled public List<DPM_DuplicateRecord> dpmDuplicates;
    }
    private class DPM_DuplicateRecord {
        @AuraEnabled public String objectType;
        @AuraEnabled public String recordId;
        @AuraEnabled public String accountName;
        @AuraEnabled public Boolean blnPlacebo;
        @AuraEnabled public sObject objRecord;
        public DPM_DuplicateRecord(String objType, String recId, String accName, Boolean isPlacebo, sObject objRec) {
            objectType = objType;
            recordId = recId;
            accountName = accName;
            blnPlacebo = isPlacebo;
            objRecord = objRec;
        }
    }
    public class IDMRequest_CDSID {
        public String firstname;
        public String lastname;
        public String city;
        public String country;
        public String mailaddress;
        public String title;
        public String phonenumber;
        public String partnertype;
        public String cdsstatus;
        public String dealercode;
        public String cdsvpid;
        public String altemail;
    }  
    public class CorporatePermissions {
        @AuraEnabled public Boolean editPermission;
        @AuraEnabled public Boolean viewGeneralData;
        @AuraEnabled public Boolean editGeneralData;
        @AuraEnabled public Boolean viewPersonalData;
        @AuraEnabled public Boolean editPersonalData; 
        @AuraEnabled public Boolean viewSSNLastFour;
        @AuraEnabled public Boolean viewSSN;
        @AuraEnabled public Boolean editSSN;
        @AuraEnabled public Boolean searchSSN;
        @AuraEnabled public Boolean viewStoreData;
        @AuraEnabled public Boolean editStoreData;
        @AuraEnabled public Boolean viewJobPositions;
        @AuraEnabled public Boolean editJobPositions;
        @AuraEnabled public Boolean accessBuySell;
        @AuraEnabled public Boolean manageSuppliers;        
        @AuraEnabled public Boolean viewSuppliers;
        @AuraEnabled public Boolean editSuppliers;
        @AuraEnabled public Boolean viewDiversityData;
        @AuraEnabled public Boolean editDiversityData;
        @AuraEnabled public Boolean viewLanguage;
        @AuraEnabled public Boolean editLanguage;
        @AuraEnabled public Boolean viewCDSIDMonitor;
        @AuraEnabled public Boolean hideCreateEmployee;
        @AuraEnabled public Boolean hideReactivateEmployee;
        @AuraEnabled public Boolean hideInitiatedRequestsTab;
        @AuraEnabled public Boolean hideSubmitedRequestsTab;
        @AuraEnabled public Boolean showUserGuideToIncentive;
        @AuraEnabled public Boolean viewW9;
        @AuraEnabled public Boolean editW9;
        @AuraEnabled public Boolean viewW9ForFireFighter;
        @AuraEnabled public Boolean isIncentiveProfile;
        @AuraEnabled public Boolean editDMSId;
        @AuraEnabled public Boolean editEmail;
        public CorporatePermissions() {
            //default corporate permissions
            editPermission = true;
            viewGeneralData = true;
            editGeneralData = true;
            viewPersonalData = false;
            editPersonalData = false;
            viewSSNLastFour = false;
            viewSSN = false;
            editSSN = false;
            searchSSN = false;
            viewStoreData = true;
            editStoreData = false;
            viewJobPositions = true;
            editJobPositions = false;
            accessBuySell = false;
            manageSuppliers = false;
            viewSuppliers = false;
            editSuppliers = false;
            viewDiversityData = false;
            editDiversityData = false;
            viewLanguage = true;
            editLanguage = false;
            viewCDSIDMonitor=false;
            hideCreateEmployee=false;
            hideReactivateEmployee=false;
            hideInitiatedRequestsTab=false;
            hideSubmitedRequestsTab=false;
            showUserGuideToIncentive = false;
            viewW9 = false;
            editW9 = false;
            viewW9ForFireFighter = false;
            isIncentiveProfile=false;
            editDMSId=false;
            editEmail = false;
        }
    }
}