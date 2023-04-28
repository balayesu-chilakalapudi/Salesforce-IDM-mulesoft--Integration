public without sharing class DPM_PersonnelMasterController{
    /*
     * Name      : DPM_PersonnelMasterController
     * Purpose   : Common Controller class for DPM.
     * Author    : Krishna Singh
     * Date      : 17-Aug-2020
     *
     * */
    @AuraEnabled
    public static List<String> getPicklistValues(String strFieldName){
        return DPM_PersonnelMasterServices.getPicklistValuesFromObject(strFieldName, 'DPM_Employee__c', true);
    }

    @AuraEnabled
    public static List<RE_Job_to_Persona_map__mdt> getAllJobPositions(Id retailer_storeId){
        system.debug('accountId:'+retailer_storeId);
        return DPM_PersonnelMasterServices.getPositionsForDPMEmployee(retailer_storeId);
    }

    @AuraEnabled
    public static Account getCurrentAccount(){
        return DPM_PersonnelMasterServices.getDefaultAccount();
    }

    @AuraEnabled
    public static void submitDPMRecord(String strDPMEmployee, String strDPMJobPositions, String strType){
        Savepoint dpmSavePoint = Database.setSavepoint();
        try{
            system.debug(strDPMJobPositions + ' submit123$ ' + strDPMEmployee +' strtype-- '+ strType);
            DPM_Employee__c dpmEmployee = (DPM_Employee__c)JSON.deserialize(strDPMEmployee, DPM_Employee__c.class );
            system.debug('dpmEmployee-=-=' + dpmEmployee);
            //Insert the DPM Employee record
            if (strType == 'Initiated'){
                dpmEmployee.DPM_Status__c = 'Initiated';
                dpmEmployee.DPM_Employee_Type__c = 'Retailer';
                String territoryCountry;

                if (dpmEmployee.DPM_Record_Origin__c == 'Portal'){
                    territoryCountry = RE_CurrentUser.getTerritoryCountry();
                    if (territoryCountry == NULL || territoryCountry == ''){
                        throw new AuraHandledException('Account is not assigned to a territory.');
                    }
                } else if (dpmEmployee.DPM_Record_Origin__c == 'Corporate'){
                    Account a = [SELECT Id, Country__r.Name
                                 FROM Account
                                 WHERE Id = :dpmEmployee.DPM_Account__c];
                    territoryCountry = a.Country__r.Name;
                }
                if (dpmEmployee.DPM_Country__c == null){
                    if (territoryCountry == 'USA' || territoryCountry == 'United States'){
                        dpmEmployee.DPM_Country__c = 'United States';
                    } else if (territoryCountry == 'CAN' || territoryCountry == 'Canada'){
                        dpmEmployee.DPM_Country__c = 'Canada';
                    } else if (territoryCountry == 'Mex' || territoryCountry == 'Mexico'){
                        dpmEmployee.DPM_Country__c = 'Mexico';
                    }
                }
                dpmEmployee.DPM_Expiration_Date__c = date.today() + 8;
            } else if (strType == 'Pending Corporate Approval' || strType == 'Approved' || strType == 'Submitted' || strType == 'Submitted - Duplicate Confirmed' || strType == 'Submitted - Duplicate Not Confirmed'){
                dpmEmployee.DPM_Status__c = strType;
                if (dpmEmployee.DPM_SSN_SIN__c != NULL){
                    dpmEmployee.DPM_SSN_SIN__c = dpmEmployee.DPM_SSN_SIN__c.replaceAll('-', '');
                }
                //dpmEmployee.DPM_Submitted_DateTime__c = system.now()+3;
            } else if (strType == 'Submitted - SSN Mismatch'){
                dpmEmployee.DPM_Status__c = 'Submitted';
            }

            if (dpmEmployee.DPM_Country__c == 'Mexico' && strType != 'Initiated'){
                //check if address is missing
                if (String.isEmpty(dpmEmployee.DPM_Home_Address_Street__c) && String.isEmpty(dpmEmployee.DPM_City__c) && String.isEmpty(dpmEmployee.DPM_Mexican_State__c) && String.isEmpty(dpmEmployee.DPM_Zipcode__c)){
                    Account accStore = [SELECT Id, ShippingStreet, ShippingState, ShippingCity, ShippingPostalCode, Phone
                                        FROM Account
                                        WHERE Id = :dpmEmployee.DPM_Account__c];
                    dpmEmployee.DPM_Home_Address_Street__c = accStore.ShippingStreet;
                    dpmEmployee.DPM_Mexican_State__c = accStore.ShippingState;
                    dpmEmployee.DPM_City__c = accStore.ShippingCity;
                    dpmEmployee.DPM_Zipcode__c = accStore.ShippingPostalCode;
                    dpmEmployee.DPM_Cell_Phone__c = accStore.Phone;
                }
            }

            // KRISHNA : For CDSID Testing Only
            //dpmEmployee.DPM_CDS_ID__c = dpmEmployee.DPM_Legal_First_Name__c+Math.round(Math.random()*100)+'@volvocars.test';
            upsert dpmEmployee;
            if (strType == 'Pending Corporate Approval'){
                //create case  
                DPM_PersonnelMasterServicesExt.createTier2Case(dpmEmployee);            
            }
            system.debug('upsertdpmEmployee-=-=' + dpmEmployee);

            if (strDPMJobPositions != null){
                List<DPM_Job_Position__c> lstDPMPositions = (List<DPM_Job_Position__c>)JSON.deserialize(strDPMJobPositions, List<DPM_Job_Position__c>.class );
                if (!lstDPMPositions.isEmpty()){
                    for (DPM_Job_Position__c jobPosition : lstDPMPositions){
                        if (jobPosition.DPM_Employee_Registration__c == NULL){
                            jobPosition.DPM_Employee_Registration__c = dpmEmployee.Id;
                        }
                    }
                    upsert lstDPMPositions;
                    if (strType.contains('Submitted') && dpmEmployee.DPM_SSN_SIN__c == NULL && dpmEmployee.DPM_Country__c!='Canada'){
                        DPM_PersonnelMasterServicesExt.checkIncentiveEligibleRegistration(lstDPMPositions);
                    }
                }
            }

            //TODO - Krishna : Move to Process Builder
            //Send Email to the Retailer Employee
            if (strType == 'Initiated'){
                DPM_PersonnelMasterServices.sendEmailToRetEmp(dpmEmployee.Id);
            }
            system.debug('strType-=-'+strType);
            if(strType == 'Approved') {   
                /*if (dpmEmployee.DPM_Country__c == null){
                    if (territoryCountry == 'USA' || territoryCountry == 'United States'){
                        dpmEmployee.DPM_Country__c = 'United States';
                    } else if (territoryCountry == 'CAN' || territoryCountry == 'Canada'){
                        dpmEmployee.DPM_Country__c = 'Canada';
                    } else if (territoryCountry == 'Mex' || territoryCountry == 'Mexico'){
                        dpmEmployee.DPM_Country__c = 'Mexico';
                    }
                }*/
                system.debug('RequestType-=-=>'+dpmEmployee.DPM_Request_Type__c);
                Id idContact = DPM_PersonnelMasterServices.upsertContact(dpmEmployee);
                RE_Person_Role__c personRole = DPM_PersonnelMasterServices.insertPersonRole(idContact,dpmEmployee);
                DPM_PersonnelMasterServices.insertJobPositions(personRole,dpmEmployee);
                DPM_Configuration__mdt DPMConfig = DPM_PersonnelMasterServices.getDPMConfigCustomMetadata(); 
                system.debug('dpmEmployee.DPM_Request_Type__c-=-'+dpmEmployee.DPM_Request_Type__c);
                //Mexico country check added, 17-Feb-2022
                if(DPMConfig.DPM_Oracle_Decommission__c || dpmEmployee.DPM_Request_Type__c != 'New' || dpmEmployee.DPM_Country__c == 'Mexico') {  
                    DPM_PersonnelMasterServices.performCallouts('IDMCreate_Approved', JSON.serialize(dpmEmployee));
                }
            }   
        } catch (exception e){
            system.debug('-=-=-=-' + e + '\n' + e.getStackTraceString()+'line number: '+e.getLineNumber());
            throw new AuraHandledException(e+'\n'+e.getStackTraceString()+'\n'+e.getMessage());
        }
    }

    @AuraEnabled
    public static DPM_Employee__c decryptAndCheckAccess(String strEncryptedId){
        return DPM_PersonnelMasterServices.decryptRecordIdAndCheckAccess(strEncryptedId);
    }

    @AuraEnabled
    public static list<DPM_Employee__c> getDPMEmployeeRecords(){
        return DPM_PersonnelMasterServices.getDPMEmployees();
    }

    @AuraEnabled
    public static list<DPM_Employee__c> getDPMEmployeeRecordsCorp(){
        return DPM_PersonnelMasterServices.getDPMEmployeesCorp();
    }

    @AuraEnabled
    public static list<RE_Person_Role__c> getExistingEmpRecords(String strSessionSettings){
        return DPM_PersonnelMasterServices.getExistingEmployees(strSessionSettings);
    }

    @AuraEnabled
    public static list<Account> getDealerships(boolean isSupplier){
        return DPM_PersonnelMasterServices.getValidDealershipsForDPM(isSupplier);
    }
    
    @AuraEnabled
    public static list<Account> getAllDealerships(){
        return DPM_PersonnelMasterServicesExt.getValidDealershipsForDPM();
    }

    @AuraEnabled
    public static RE_Person_Role__c getCurrentUserProfile(String strPersonRoleId){
        try{
            if (strPersonRoleId == ''){
                RE_Community_User_Settings__c userSettings = RE_CurrentUser.userSettings;
                return DPM_PersonnelMasterServices.getUserProfile(UserInfo.getUserId(), userSettings.RE_Default_Account_Id__c);
            } else{
                return DPM_PersonnelMasterServices.getUserProfile(strPersonRoleId);
            }
        } catch (exception e){
            system.debug(e + ' exceptiontype123$ ' + e.getTypeName());
            if (e.getTypeName() == 'System.AuraHandledException'){
                throw e;
            }
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static RE_Person_Role__c currentPersonRole(){
        RE_Community_User_Settings__c userSettings = RE_CurrentUser.userSettings;
        system.debug('userSettings-=->'+userSettings.RE_Default_Account_Id__c+' id-->'+UserInfo.getUserId());
        return DPM_PersonnelMasterServices.getUserProfile(UserInfo.getUserId(), userSettings.RE_Default_Account_Id__c);
    }

    @AuraEnabled
    public static void saveEmployeeProfile(String strPersonRole, String strContact, String strJobPositions){
        system.debug('strPersonRole--> ' + strPersonRole);
        system.debug('strContact--> ' + strContact);
        system.debug('strJobPositions--> ' + strJobPositions);
        Integer personRole_count=0;
        try{
            RE_Person_Role__c personRole = (RE_Person_Role__c)JSON.deserialize(strPersonRole, RE_Person_Role__c.class );
            //The DMS Id is unique across a store but not necessarily across other stores (Reason:  Diff vendors are used as DMS providers)
            if(personRole.DPM_DMS_Id__c!=null && personRole.DPM_DMS_Id__c!=''){
                personRole_count=[SELECT count() from RE_Person_Role__c 
                WHERE DPM_DMS_Id__c=:personRole.DPM_DMS_Id__c
                AND RE_Account__c=:personRole.RE_Account__c
                AND Id!=:personRole.Id];
                if(personRole_count>0){
                    throw new AuraHandledException('The DMS Employee# entered has been assigned to another employee in this store.   Please provide an unique value');
                }
            }

            Contact contact = (Contact)JSON.deserialize(strContact, Contact.class );
            if (contact.id == NULL){
                contact.id = personRole.RE_Contact__c;
            }

            if (contact.accountId == NULL){
                contact.accountId = personRole.RE_Account__c;
            }

            system.debug('CONTACT----' + contact);

            List<DPM_EmployeeJobPosition__c> lstJobPositions;

            // strJobPositions is null sometimes - KS: after deduplication and data fixing it will not happen
            try{
                lstJobPositions = (List<DPM_EmployeeJobPosition__c>)JSON.deserialize(strJobPositions, List<DPM_EmployeeJobPosition__c>.class );
            } catch (Exception ex){
                lstJobPositions = new List<DPM_EmployeeJobPosition__c>();
            }
            if (!personRole.DPM_Owner__c){
                personRole.DPM_Owner_Title__c = NULL;
            }
            
            if (contact.DPM_SSN__c != NULL && contact.DPM_SSN__c != ''){
                contact.DPM_SSN__c = contact.DPM_SSN__c.replaceAll('-', '');
            }
            system.debug('contact1-=>'+contact.DPM_w9_reason__c);
            system.debug('contact2-=>'+contact.DPM_w9_date__c);
            system.debug('contact3-=>'+contact.DPM_w9_flag__c);
            system.debug('contact4-=>'+contact);
            update contact;
            update personRole;
            system.debug('contact 22-=>'+contact);
            system.debug('contact12-=>'+contact.DPM_w9_reason__c);
            system.debug('contact222-=>'+contact.DPM_w9_date__c);
            system.debug('contact32-=>'+contact.DPM_w9_flag__c);
            if (!lstJobPositions.isEmpty()){
                for (DPM_EmployeeJobPosition__c jobPosition : lstJobPositions){
                    jobPosition.DPM_Person_Role__c = personRole.Id;
                    jobPosition.DPM_Contact__c = contact.Id;
                    jobPosition.DPM_Account__c = personRole.RE_Account__c;
                    if (personRole.RE_Psn_NonActive_Date__c != NULL && jobPosition.DPM_Position_End_Date__c == NULL){
                        jobPosition.DPM_Position_End_Date__c = personRole.RE_Psn_NonActive_Date__c;
                    }
                }
                upsert lstJobPositions;//commented for testing purpose by gauravs
                contact=[SELECT Id,recordtype.name,DPM_SSN__c, Account_Country__c FROM contact where id=:contact.Id];
                if (contact.recordtype.name != 'Supplier Employee' && contact.DPM_SSN__c == NULL && contact.account_country__c!='CAN'){
                    DPM_PersonnelMasterServicesExt.checkIncentiveEligibleProfile(lstJobPositions);
                }
            }
        }
        
         catch (exception e){
            system.debug('EXCEPTION----' + e + '\n' + e.getStackTraceString());
            if(personRole_count>0){
                throw new AuraHandledException('The DMS Employee# entered has been assigned to another employee in this store.   Please provide an unique value');
            }else{            
                throw new AuraHandledException(e.getMessage()+'\n'+e+'\n'+e.getStackTraceString());
            }
        }
    }

    @AuraEnabled
    public static Map<String, List<String>> getCountriesAndStates(){
        return DPM_PersonnelMasterServices.getCountryStatesMap();
    }

    @AuraEnabled
    public static Map<String, List<String>> getCorpCountriesAndStates(){
        return DPM_PersonnelMasterServicesExt.getCorpCountryStatesMap();
    }

    @AuraEnabled
    public static Integer getTotalStoreEmployees(){
        return DPM_PersonnelMasterServices.getExistingEmployeesTotal();
    }

    //Duplicate check for new Retailer Employee when Admin Initiates a request
    @AuraEnabled
    public static List<RE_Person_Role__c> duplicateCheck(String strDPMEmployee){
        return DPM_PersonnelMasterServices.retailerEmpDupCheck_RetailerAdmin(strDPMEmployee);
    }

    //Duplicate Check for new Retailer Employee after Self registration
    @AuraEnabled
    public static DPM_PersonnelMasterServices.DPM_DuplicateCheckResult duplicateCheckSelfReg(String strDPMEmployee){
        return DPM_PersonnelMasterServices.retailerEmpDupCheck_SelfReg(strDPMEmployee);
    }

    //Find matching profiles for Reactivation
    @AuraEnabled
    public static List<Contact> findMatchingProfilesForReactivation(String strDPMEmployee){
        return DPM_PersonnelMasterServices.findMatchingEmployeeProfiles(strDPMEmployee);
    }

    //Find matching profiles for Reactivation - Self Reg
    @AuraEnabled
    public static List<Contact> findMatchingProfilesForReactivation_SelfReg(String strContactId){
        return DPM_PersonnelMasterServices.findMatchingEmployeeProfiles_SelfReg(strContactId);
    }

    //Delete new retailer employee registration record
    @AuraEnabled
    public static void deleteNewRetailerEmp(String idDpmEmp){
        DPM_Employee__c dpmEmpl = [SELECT Id, Name
                                   FROM DPM_Employee__c
                                   where Id = :idDpmEmp];
        try{
            delete dpmEmpl;
        } catch (exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    // GET dpm record based on contact Id
    @AuraEnabled
    public static DPM_Employee__c getDPMEmployeeByContactId(String idContactId){
        DPM_Employee__c dpmEmployee;
        try{
            //get contact from Id
            Contact con = [SELECT Email
                           FROM Contact
                           WHERE Id = :idContactId];
            dpmEmployee = [SELECT Id, CreatedById, LastModifiedById, DPM_Account__r.Name, DPM_Account__r.Retailer__c, DPM_Email__c, DPM_Legal_First_Name__c, DPM_Status__c, DPM_Gender__c, DPM_Prefix__c, DPM_Middle_Name__c, DPM_Last_Name__c, DPM_Suffix__c, DPM_Preferred_First_Name__c, DPM_Hire_Date__c, DPM_Owner__c, DPM_Owner_Title__c, DPM_Canadian_State__c, DPM_Cell_Phone__c, DPM_City__c, DPM_Country__c, DPM_Home_Address_Street__c, DPM_Home_Phone__c, DPM_US_State__c, DPM_Zipcode__c, DPM_Home_Address_Street_2__c, DPM_Submitted_DateTime__c, DPM_Retailer_Admin__c, DPM_Request_Type__c, DPM_Ethnicity__c, DPM_US_Military__c, DPM_Language_1__c, DPM_Language_2__c, DPM_Language_3__c, DPM_Proficiency_1__c, DPM_Proficiency_2__c, DPM_Proficiency_3__c, DPM_Race__c, (SELECT Id, DPM_End_Date__c, DPM_Primary__c, Name, DPM_Start_Date__c
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           FROM DPM_Job_Positions__r), DPM_Record_Origin__c
                           FROM DPM_Employee__c
                           WHERE DPM_Email__c = :con.Email
                           LIMIT 1];
        } catch (Exception ex){
            System.debug(ex);
        }
        return dpmEmployee;
    }

    @AuraEnabled
    public static DPM_PersonnelMasterServices.DPM_SearchResults searchEmployees(String strSessionSettings, String strSearchFields){
        return DPM_PersonnelMasterServices.searchEmployees(strSessionSettings, strSearchFields);
    }

    @AuraEnabled
    public static DPM_PersonnelMasterServices.CorporatePermissions checkCorporatePermissions(){
        return DPM_PersonnelMasterServices.getCorporatePermissions();
    }

    @AuraEnabled
    public static DPM_PersonnelMasterServices.DPM_LogData resendRequestFromLog(Id logId){
        return DPM_PersonnelMasterServices.performCalloutFromLog(logId);
    }

    @AuraEnabled
    public static List<Account> getSellingRetailers(){
        return [SELECT Id, Name, IsPartner, Retailer__c, Org_activated__c, Org_non_activated__c, Market__r.Name, Region__r.Name, Country__r.Name
                FROM Account
                WHERE RecordType.Name = 'Retailer' AND Org_non_activated__c <> NULL AND IsPartner = TRUE AND Org_non_activated__c = LAST_N_DAYS:30
                ORDER BY Name];
    }

    // Buy/Sell Methods
    @AuraEnabled
    public static List<Account> getBuyingRetailers(){
        return [SELECT Id, Name, IsPartner, Retailer__c, Org_activated__c, Org_non_activated__c, Market__r.Name, Region__r.Name, Country__r.Name
                FROM Account
                WHERE RecordType.Name = 'Retailer' AND Org_non_activated__c = NULL AND IsPartner = TRUE AND Org_activated__c = LAST_N_DAYS:30
                ORDER BY Name];//user Strory:Buy/Sell:  #1, point :2
    }

    @AuraEnabled(cacheable = true)
    public static List<Account> getActivePersonnel(String sellingRetailerId, String buyingRetailerId){
        String strQuery = 'SELECT Id,Retailer__c,Name,(SELECT RE_Contact__r.Name,RE_Employee_Position__c,RE_Psn_Active_Date__c,RE_IsAdmin__c FROM Person_Roles__r WHERE RE_Psn_Active__c =true AND RE_Position_Active__c =true AND RE_Account__c = :sellingRetailerId) FROM Account WHERE Id =:sellingRetailerId OR Id=:buyingRetailerId';
        return database.query(strQuery);
    }

    @AuraEnabled
    public static void transferPersonnel(List<Id> lstPersonRoleIds, String strSellingRetailerId, String strBuyingRetailerId, String dtOriginalAppointmentDate){
        Id idbatchJob = Database.executeBatch(new DPM_BuySellProcessBatch(lstPersonRoleIds, strBuyingRetailerId, strSellingRetailerId, Date.valueOf(dtOriginalAppointmentDate)), 10);
    }

    @AuraEnabled
    public static List<DPM_Setting__mdt> getDiversityData(){
        return [SELECT Id, MasterLabel, DPM_Available_Languages__c, DPM_Available_Races__c, DPM_Available_Ethnicities__c
                from DPM_Setting__mdt];
    }

    @AuraEnabled
    public static List<RE_Person_Role__c> duplicateCheck_Approval(String strDPMEmployee){
        return DPM_PersonnelMasterServicesExt.retailerEmpDupCheck_Approval(strDPMEmployee);
    }

    @AuraEnabled
    public static List<Workflow_Application_Link__mdt> fetchWorkflowAppLinks(String type){
        return [SELECT Id, MasterLabel, URL__c, Order__c
                FROM Workflow_Application_Link__mdt
                WHERE Type__c = :type
                ORDER BY Order__c];
    }

    @AuraEnabled
    public static string createDPMErrorNotification(string accountId, String strExceptionMsg){
        DPM_PersonnelMasterServicesExt.createDPMErrorNotification(accountId, strExceptionMsg);
        return NULL;
    }
    @AuraEnabled 
    public static DPM_Employee__c getStatusValue(String strRecordId){
        return DPM_PersonnelMasterServicesExt.getStatusVal(strRecordId); 
    }
    @AuraEnabled
    public static void sendRejectEmailToRetailerAdmin(String strRecordId){
        DPM_PersonnelMasterServicesExt.setRegistrationStatus(strRecordId);
    }    
    @AuraEnabled
    public static DPM_PersonnelMasterServices.DPM_SearchResults searchEmployeeCreationStatusAction(String strSessionSettings, String strSearchFields){
        try {
            return DPM_PersonnelMasterServicesExt.searchEmployeeCreationStatusAction(strSessionSettings,strSearchFields);
        } catch (Exception e) {
            throw new AuraHandledException(e+'\n'+e.getStackTraceString());
        }
    }
}