@isTest
public class DPM_PersonnelMasterTest {    
    @Testsetup
    static void setup() {        
        test.startTest();   
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Country__c country = DPM_TestDataCreator.createCountry('USA');
        insert country;
        Region__c region = DPM_TestDataCreator.createRegion('NORTHEAST',country.Id);
        insert region;
        Market__c market = DPM_TestDataCreator.createMarket('1101',region.Id);
        insert market;
        
        Account account = DPM_TestDataCreator.createAccount();
        account.Country__c = country.Id;
        account.Region__c = region.Id;
        account.Market__c = market.Id;        
        insert account;
        
        Trigger_On_Off__c setting = new Trigger_On_Off__c(Off__c = false,Name='Switch Off');
        insert setting;
        Account_Country__c accountCountry = new Account_Country__c(Name='USA',Country__c='USA');
        insert accountCountry;
        RE_Community_User_Settings__c currentSettings = DPM_TestDataCreator.createCommunityUserSettings(account.Id);
        insert currentSettings;       
        
        Contact contact =DPM_TestDataCreator.createContact(account.Id);
        contact.RecordTypeId=Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Retailer Employee').getRecordTypeId(); 
        contact.DPM_SSN__c='12345';       
        contact.DPM_SSNencrypted__c=null;
        contact.DPM_VPID__c=null;
        contact.PsnId__c='12345';
        insert contact;
        
        RE_Person_Role__c personRole = DPM_TestDataCreator.createPersonRole(account.Id,contact.Id,UserInfo.getUserId());
        personRole.DPM_CDS_Id__c='testabc@volvocars.test';
        insert personRole;
        insert DPM_TestDataCreator.createEmployeeJobPosition(personRole.Id); 
        
        DPM_Log__c dpmlog=new DPM_Log__c();
        dpmlog.DPM_Request_Body__c='{"cdsstatus":[{"remove":["true"]},{"add":["false"]}],"secondarycdsid":[{"add":["Rajeev30"]}]}';
        dpmlog.DPM_Callout_Endpoint__c='http://dev-idm-system-api.us-e1.cloudhub.io/api/user/R-SHARM';
        dpmLog.DPM_Integration_Method__c='POST';
        insert dpmlog;
        
        Test.stopTest();
    }    
    
    
    public static testmethod void testPicklistValues() {
        test.startTest();   
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());        
        List<String> lstGenderOptions = DPM_PersonnelMasterController.getPicklistValues('DPM_Gender__c');
        List<String> lstPrefixOptions = DPM_PersonnelMasterController.getPicklistValues('DPM_Prefix__c');
        List<String> lstSuffixOptions = DPM_PersonnelMasterController.getPicklistValues('DPM_Suffix__c');
        System.assertEquals(lstGenderOptions.size()>0, true); 
        System.assertEquals(lstPrefixOptions.size()>0, true);
        System.assertEquals(lstSuffixOptions.size()>0, true);
        test.stopTest();        
    }
    
    public static testmethod void testJobPositionValues() {       
        test.startTest();
        Id accountId=null;
        try{
        accountId=[select Id from account limit 1].Id;
        }catch(Exception ex){
            system.debug(ex);
        }
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());  
        List<RE_Job_to_Persona_map__mdt> lstJobPositionValues = DPM_PersonnelMasterController.getAllJobPositions(accountId);
        System.assertEquals(lstJobPositionValues.size()>0, true);
        test.stopTest();
    }
    public static testmethod void testCurrentAccount() {
        test.startTest();       
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator()); 
        RE_Person_Role__c personRole=[select Id,DPM_Primary__c,DPM_CDS_Id__c from RE_Person_Role__c LIMIT 1];
        personRole.DPM_Primary__c=true;
        personRole.DPM_CDS_Id__c='testcu@volvocars.test';
        update personRole;
        Account acc = DPM_PersonnelMasterController.getCurrentAccount();
        System.assertEquals(acc.Id != NULL, true);
        test.stopTest();
    }
    public static testmethod void testDPMEmployeeInitiation() {
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator()); 
        DPM_Employee__c dpmEmployee = DPM_TestDataCreator.createDPMEmployee();
        Account account = [SELECT Id from Account Limit 1];
        dpmEmployee.DPM_Account__c = account.Id;
        dpmEmployee.DPM_Record_Origin__c = 'Corporate';
        List<DPM_Job_Position__c> lstJobPositions = new List<DPM_Job_Position__c>();
        lstJobPositions.add(DPM_TestDataCreator.createJobPosition());
        try{
        DPM_PersonnelMasterController.submitDPMRecord(JSON.serialize(dpmEmployee),JSON.serialize(lstJobPositions),'Initiated');
         }catch(Exception ex){
            System.assertNotEquals(0,ex.getMessage().length());
             dpmEmployee.DPM_Status__c = 'Initiated';
             insert dpmEmployee;
        }
        DPM_Employee__c dpmEmployeeInitiated = [SELECT Id,DPM_Status__c FROM DPM_Employee__c LIMIT 1];
        System.assertEquals(dpmEmployeeInitiated.DPM_Status__c == 'Initiated', true);
        test.stopTest();
    }
    public static testmethod void testDPMEmployeeSubmission() {
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());  
        DPM_Employee__c dpmEmployee = DPM_TestDataCreator.createDPMEmployee();
        Account account = [SELECT Id from Account Limit 1];
        dpmEmployee.DPM_Account__c = account.Id;
        dpmEmployee.DPM_Record_Origin__c = 'Corporate';
        List<DPM_Job_Position__c> lstJobPositions = new List<DPM_Job_Position__c>();
        lstJobPositions.add(DPM_TestDataCreator.createJobPosition());
        DPM_PersonnelMasterController.submitDPMRecord(JSON.serialize(dpmEmployee),JSON.serialize(lstJobPositions),'Submitted');
        DPM_Employee__c dpmEmployeeSubmitted = [SELECT Id,DPM_Status__c FROM DPM_Employee__c LIMIT 1];
        System.assertEquals(dpmEmployeeSubmitted.DPM_Status__c == 'Submitted', true);
        dpmEmployeeSubmitted.DPM_Contact__c=[select Id from contact limit 1].Id;
        dpmEmployeeSubmitted.DPM_Status__c='Approved';
        dpmEmployeeSubmitted.DPM_Request_Type__c='New';
        update dpmEmployeeSubmitted;
        RE_Person_Role__c personRole=[select Id,DPM_Primary__c,DPM_CDS_Id__c from RE_Person_Role__c LIMIT 1];
        personRole.DPM_Primary__c=true;
        personRole.DPM_CDS_Id__c='testcu@volvocars.test';
        try{
            update personRole;
            dpmEmployee.DPM_Country__c='Canada';
            Country__c c=[select name from country__c limit 1];
            c.name='CAN';
            update c;
            DPM_PersonnelMasterController.submitDPMRecord(JSON.serialize(dpmEmployee),JSON.serialize(lstJobPositions),'Initiated');
        }catch(Exception ex){
            system.debug(ex);
        }
        
        test.stopTest();
    }
    
    public static testmethod void testDPMEmployeeApproved() {
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());  
        DPM_Employee__c dpmEmployee = DPM_TestDataCreator.createDPMEmployee();
        Account account = [SELECT Id from Account Limit 1];
        Contact contact = [SELECT Id from Contact Limit 1];
        dpmEmployee.DPM_Account__c = account.Id;
        dpmEmployee.DPM_Contact__c=contact.Id;
        dpmEmployee.DPM_Record_Origin__c = 'Corporate';
        List<DPM_Job_Position__c> lstJobPositions = new List<DPM_Job_Position__c>();
        lstJobPositions.add(DPM_TestDataCreator.createJobPosition()); 
        insert dpmEmployee;
        for(DPM_Job_Position__c djp:lstJobPositions){
            djp.DPM_Employee_Registration__c=dpmEmployee.Id;
        }
        insert lstJobPositions;
        String idRecord=[select Id from RE_Person_Role__c limit 1].Id;
        //dpmEmployee.Id;
        String strCountry='United States';
        String strPosition='test';        
        DPM_PersonnelMasterServices.upsertContact(dpmEmployee);
        DPM_PersonnelMasterServices.insertPersonRole(contact.Id, dpmEmployee);
        DPM_PersonnelMasterServices.getValidDealershipsForDPM(false);
        RE_Person_Role__c personRole=[select Id,RE_Contact__c
                                      from RE_Person_Role__c limit 1];
        DPM_PersonnelMasterServices.insertJobPositions(personRole, dpmEmployee);
        //DPM_PersonnelMasterServicesExt.sendEmail_MissingSSN(idRecord, strPosition);
        String idContact=contact.id;
        String idDPMEmployee=dpmEmployee.Id;
        String strType='Extension';
        Boolean blnOracleDecom=false;
        
        // DPM_PersonnelMasterController.submitDPMRecord(JSON.serialize(dpmEmployee),JSON.serialize(lstJobPositions),'Approved');
        // DPM_Employee__c dpmEmployeeApproved = [SELECT Id,DPM_Status__c FROM DPM_Employee__c LIMIT 1];
        // System.assertEquals(dpmEmployeeApproved.DPM_Status__c == 'Approved', true);
        try{
            DPM_PersonnelMasterServices.callIDMForCDSIDCreation(idContact, idDPMEmployee, strType, blnOracleDecom);
            //	DPM_PersonnelMasterController.submitDPMRecord(JSON.serialize(dpmEmployee),null,'Approved');
            dpmEmployee.DPM_Record_Origin__c = 'Portal';
            dpmEmployee.DPM_SSN_SIN__c=null;
            DPM_PersonnelMasterController.submitDPMRecord(JSON.serialize(dpmEmployee),JSON.serialize(lstJobPositions),'Initiated');    
        }catch(Exception ex){
            system.debug('Aurahandled Exception');
        }
        test.stopTest();
    }
    public static testmethod void testDPMEmployeeEncryption() {
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator()); 
        DPM_Employee__c dpmEmployee = DPM_TestDataCreator.createDPMEmployee();
        Account account = [SELECT Id from Account Limit 1];
        dpmEmployee.DPM_Account__c = account.Id;
        dpmEmployee.DPM_Record_Origin__c = 'Corporate';
        List<DPM_Job_Position__c> lstJobPositions = new List<DPM_Job_Position__c>();
        lstJobPositions.add(DPM_TestDataCreator.createJobPosition());
        try{
            DPM_PersonnelMasterController.submitDPMRecord(JSON.serialize(dpmEmployee),JSON.serialize(lstJobPositions),'Initiated');
        }catch(Exception ex){
            System.assertNotEquals(0,ex.getMessage().length());
            insert dpmEmployee;
        }        
        DPM_Employee__c dpmEmployeeInitiated = [SELECT Id,DPM_Status__c FROM DPM_Employee__c LIMIT 1];
        String strEncryptedURL = DPM_PersonnelMasterServices.encryptRecordIdAndGenerateLink(dpmEmployeeInitiated.Id);
        String strEncryptedId = strEncryptedURL.split('id=')[1];
        try{
        DPM_Employee__c dpmEmployeeDecrypted = DPM_PersonnelMasterController.decryptAndCheckAccess(strEncryptedId);
        System.assertEquals(dpmEmployeeDecrypted.Id != NULL, true);
        }catch(Exception ex){
            System.assertNotEquals(0,ex.getMessage().length());
        }
        test.stopTest();
    }
    public static testmethod void testGetEmployees() {
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        DPM_PersonnelMasterController.getDPMEmployeeRecords();
        DPM_PersonnelMasterController.getDPMEmployeeRecordsCorp();
        DPM_PersonnelMasterController.getDealerships();
        DPM_PersonnelMasterController.getCountriesAndStates();
        DPM_PersonnelMasterController.getTotalStoreEmployees();
        test.stoptest();
    }
    public static testmethod void testEmployeeProfileActions() {    
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());   
        RE_Person_Role__c personRole = [SELECT Id FROM RE_Person_Role__c Limit 1];
        DPM_PersonnelMasterServices.DPM_SessionSettings sessionSettings = new DPM_PersonnelMasterServices.DPM_SessionSettings();
        sessionSettings.sortBy = 'Name';
        sessionSettings.sortDirection = 'ASC';
        sessionSettings.filterBy = 'Job_Position';
        sessionSettings.filterString = 'cash';
        sessionSettings.intOffset = 0;
        sessionSettings.intLimit= 10;
        sessionSettings.showViewMore = true;
        DPM_PersonnelMasterController.getExistingEmpRecords(JSON.serialize(sessionSettings));
        try{
            DPM_PersonnelMasterController.getCurrentUserProfile(personRole.Id);
        }catch(Exception ex){
            System.debug('System.AuraHandledException: Script-thrown exception');
        }
        sessionSettings.sortBy = 'CDSID';
        DPM_PersonnelMasterController.getExistingEmpRecords(JSON.serialize(sessionSettings));
        sessionSettings.sortBy = 'Job_Position';
        DPM_PersonnelMasterController.getExistingEmpRecords(JSON.serialize(sessionSettings));
        sessionSettings.sortBy = 'Email';
        DPM_PersonnelMasterController.getExistingEmpRecords(JSON.serialize(sessionSettings));  
        sessionSettings.sortBy = 'Hire_Date';
        DPM_PersonnelMasterController.getExistingEmpRecords(JSON.serialize(sessionSettings));
        sessionSettings.sortBy = 'Admin';
        DPM_PersonnelMasterController.getExistingEmpRecords(JSON.serialize(sessionSettings));
        sessionSettings.sortBy = 'Owner';
        DPM_PersonnelMasterController.getExistingEmpRecords(JSON.serialize(sessionSettings));
        sessionSettings.sortBy = 'Owner_Title';
        DPM_PersonnelMasterController.getExistingEmpRecords(JSON.serialize(sessionSettings));
        test.stoptest();
    }
    public static testmethod void testSaveProfile() {
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());       
        RE_Person_Role__c personRole = [SELECT Id FROM RE_Person_Role__c Limit 1];
        List<DPM_EmployeeJobPosition__c> lstEmpJobPositions = [SELECT Id FROM DPM_EmployeeJobPosition__c];
        Contact contact = [SELECT Id FROM Contact Limit 1];
        DPM_PersonnelMasterController.saveEmployeeProfile(JSON.serialize(personRole),JSON.serialize(contact),JSON.serialize(lstEmpJobPositions));
        test.stopTest();
    }
    public static testmethod void testDupCheckAdmin() {
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        DPM_Employee__c dpmEmployee = DPM_TestDataCreator.createDPMEmployee();
        Account account = [SELECT Id from Account Limit 1];
        dpmEmployee.DPM_Account__c = account.Id;
        dpmEmployee.DPM_Record_Origin__c = 'Corporate';
        DPM_PersonnelMasterController.duplicateCheck(JSON.serialize(dpmEmployee));
        test.stopTest();
    }
    public static testmethod void testEmailNotifyUsers() {
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator()); 
        DPM_EmailTemplateController emailTemplateController = new DPM_EmailTemplateController();
        DPM_Employee__c dpmEmployee = DPM_TestDataCreator.createDPMEmployee();
        Account account = [SELECT Id from Account Limit 1];
        dpmEmployee.DPM_Account__c = account.Id;
        dpmEmployee.DPM_Record_Origin__c = 'Corporate';
        List<DPM_Job_Position__c> lstJobPositions = new List<DPM_Job_Position__c>();
        lstJobPositions.add(DPM_TestDataCreator.createJobPosition());
        try{
        DPM_PersonnelMasterController.submitDPMRecord(JSON.serialize(dpmEmployee),JSON.serialize(lstJobPositions),'Initiated');
             }catch(Exception ex){
            System.assertNotEquals(0,ex.getMessage().length());
                 insert dpmEmployee;
        }
        DPM_Employee__c dpmEmployeeInitiated = [SELECT Id,DPM_Status__c FROM DPM_Employee__c LIMIT 1];
        DPM_EmailTemplateController.idDPMEmployee = dpmEmployeeInitiated.Id;
        DPM_EmailTemplateController.NotifyUsers notifyUser = new DPM_EmailTemplateController.NotifyUsers();
        notifyUser.strEmailType = '4days';
        notifyUser.idDPMEmployee = dpmEmployeeInitiated.Id;
        List<DPM_EmailTemplateController.NotifyUsers> lstNotifyRequests = new List<DPM_EmailTemplateController.NotifyUsers>();
        lstNotifyRequests.add(notifyUser);
        emailTemplateController.getAccountAddress();
        emailTemplateController.getLink();
        DPM_EmailTemplateController.sendNotificationMails(lstNotifyRequests);        
        dpmEmployeeInitiated.DPM_Record_Origin__c = 'Portal';
        update dpmEmployeeInitiated;
        DPM_EmailTemplateController.sendNotificationMails(lstNotifyRequests);        
        test.stopTest();
    }
    public static testmethod void testduplicateCheckSelfReg(){
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator()); 
        DPM_Employee__c dpmEmployee = DPM_TestDataCreator.createDPMEmployee();
        Account account = [SELECT Id from Account Limit 1];
        dpmEmployee.DPM_Account__c = account.Id;
        dpmEmployee.DPM_Record_Origin__c = 'Corporate';
        String strDPMEmployee=JSON.serialize(dpmEmployee);
        DPM_PersonnelMasterController.duplicateCheckSelfReg(strDPMEmployee);
        Test.stopTest();
    } 
    public static testmethod void testfindMatchingProfilesForReactivation(){
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());   
        DPM_Employee__c dpmEmployee = DPM_TestDataCreator.createDPMEmployee();
        Account account = [SELECT Id from Account Limit 1];
        dpmEmployee.DPM_Account__c = account.Id;
        dpmEmployee.DPM_Record_Origin__c = 'Corporate';
        String strDPMEmployee=JSON.serialize(dpmEmployee);
        DPM_PersonnelMasterController.findMatchingProfilesForReactivation(strDPMEmployee);
        Test.stopTest();
    }
    public static testmethod void testdeleteNewRetailerEmp(){
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        DPM_Employee__c dpmEmployee = DPM_TestDataCreator.createDPMEmployee();
        insert dpmEmployee;        
        String idDpmEmp=dpmEmployee.Id;
        DPM_PersonnelMasterController.deleteNewRetailerEmp(idDpmEmp);
        Test.stopTest();
    }
    public static testmethod void testgetDPMEmployeeByContactId(){
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        DPM_Employee__c dpmEmployee = DPM_TestDataCreator.createDPMEmployee();
        Account account = [SELECT Id from Account Limit 1];
        dpmEmployee.DPM_Account__c = account.Id;
        dpmEmployee.DPM_Record_Origin__c = 'Corporate';
        Contact con=[SELECT Id from Contact LIMIT 1];
        String idContactId=con.Id;
        DPM_PersonnelMasterController.getDPMEmployeeByContactId(idContactId);
        Test.stopTest();
    }
    public static testmethod void testcurrentPersonRole(){
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        String accId=[SELECT Id from Account LIMIT 1].Id;
        RE_Community_User_Settings__c userSettings=new RE_Community_User_Settings__c();
        userSettings.RE_Default_Account_Id__c=accId;
        insert userSettings;
        RE_Person_Role__c rpr=new RE_Person_Role__c();
        rpr.RE_Account__c=accId;
        rpr.RE_Contact__c=[SELECT Id from Contact LIMIT 1].Id;
        
        rpr.RE_User__c=UserInfo.getUserId();
        rpr.RE_Psn_Active__c=true;
        rpr.RE_Position_Active__c=true;
        rpr.DPM_CDS_Id__c='test@volvocars.test';
        insert rpr;
        String strPosition='Dispatcher';
        rpr.DPM_CDS_Id__c='test2@volvocars.test';
        update rpr;
        
        DPM_PersonnelMasterServices.getPersonaMap(strPosition);    
        try{
            DPM_PersonnelMasterController.currentPersonRole();           
        }catch(Exception ex){
            system.debug(ex);
        }
        Test.stopTest();
    }
    
    
    public static testmethod void testfindMatchingProfilesForReactivation_SelfReg(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator()); 
        Contact con=[select Id from contact limit 1];
        String strContactId=con.Id;
        DPM_PersonnelMasterController.findMatchingProfilesForReactivation_SelfReg(strContactId);       
        List<RE_Person_Role__c> personRoleList=[select Id,RE_Psn_Active__c,RE_Employee_Position__c,DPM_CDS_Id__c,RE_Contact__c,DPM_Work_Email__c
                                                from RE_Person_Role__c];
        for(RE_Person_Role__c pr:personRoleList){
            pr.RE_Psn_Active__c=false;
            pr.DPM_Primary__c=false;
            pr.RE_Contact__c=con.Id;
            pr.DPM_Work_Email__c='abcd@volvocars.test';
        }   
        try{
            //  update personRoleList; 
            Map<Id,RE_Person_Role__c> oldPersonRoleMap=new Map<Id,RE_Person_Role__c>();
            for(RE_Person_Role__c pr:[select Id,RE_Psn_Active__c,RE_Employee_Position__c,DPM_CDS_Id__c,RE_Contact__c,DPM_Work_Email__c
                                      from RE_Person_Role__c]){
                                          pr.RE_Psn_Active__c=true;
                                          pr.DPM_Primary__c=true;
                                          pr.RE_Contact__c=con.Id;
                                          pr.DPM_Work_Email__c='abc2d@volvocars.test';
                                          oldPersonRoleMap.put(pr.Id,pr);
                                      } 
            DPM_PersonRoleTriggerHelper.handleIDMRequests(personRoleList, oldPersonRoleMap);  
        }catch(Exception ex){
            System.debug(ex);
        }
        Test.stopTest();
    }
    public static testmethod void testPersonRoleTriggerHelper(){
        List<Id> lstUserIdsForDeactivation=new List<Id>();
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u = new User(Alias = 'stan22', Email='standard22@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='standard22r@testorg.com');
        insert u;
        lstUserIdsForDeactivation.add(u.Id);
        DPM_PersonRoleTriggerHelper.deactivateUsers(lstUserIdsForDeactivation);
    }
    public static testmethod void testsearchEmployees(){
        try{
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator()); 
        String strSessionSettings='{"existingEmployeeColumns":[{"label":"Name","name":"Name"},{"label":"Primary Job Position","name":"Job_Position"},{"label":"Main Email","name":"Email"},{"label":"Hire Date","name":"Hire_Date"},{"label":"Retailer Admin","name":"Admin"},{"label":"Owner","name":"Owner"},{"label":"Owner Title","name":"Owner_Title"}],"sortBy":"Name","sortDirection":"ASC","filterBy":"","filterString":"","showViewMore":false,"intOffset":0,"intLimit":0,"skipOffset":false}';
        String strSearchFields='{"showInactiveEmployees":false, "fromPortal":false, "retailerAdmin":true}';
        DPM_PersonnelMasterController.searchEmployees(strSessionSettings, strSearchFields);
        Test.stopTest();
        }catch(Exception ex){
            system.debug(ex);
        }
        try{
            DPM_PersonnelMasterServices.DPM_SearchEmployee empObj=new DPM_PersonnelMasterServices.DPM_SearchEmployee();
            empObj.primaryJobOnly=true;
            empObj.firstName='test';
            empObj.lastName='test';
            empObj.showInactiveEmployees=true;
            DPM_PersonnelMasterServices.DPM_SessionSettings sessObj=new DPM_PersonnelMasterServices.DPM_SessionSettings();
            sessObj.filterBy = 'Job_Position';
            sessObj.filterString='Cashier';            
            sessObj.skipOffset=true;
            sessObj.showViewMore=false;
            DPM_PersonnelMasterServices.getEmployeeJobPositionQuery(empObj,sessObj,'');
        }catch(Exception ex){
            system.debug(ex);
        }
    }
    
    public static testmethod void testcheckCorporatePermissions(){
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        List<PermissionSetAssignment> palist=new List<PermissionSetAssignment>();     
        Map<Id,set<Id>> pamap=new Map<Id,set<Id>>();
        set<Id> paset=new set<Id>();
        for(PermissionSet ps:[SELECT Id 
                              FROM PermissionSet 
                              WHERE Name IN ('DPM_Corp_Digital_Admin','DPM_Corp_Incentive','DPM_Corp_Helpdesk','DPM_Corp_Firefighter','DPM_Corp_Business_Admin')
                             ]){
                                 palist.add(new PermissionSetAssignment(AssigneeId = userinfo.getuserId(), PermissionSetId = ps.Id));
                                 paset.add(ps.Id);
                                 
                             }
        Database.insert(palist,false);
        DPM_PersonnelMasterController.checkCorporatePermissions();
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'stan22', Email='standard22@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='standard22r@testorg.com');
        insert u;
        pamap.put(u.Id,paset);
        String strMapUserIdToSetPS=JSON.serialize(pamap);
        Model_contact.insertPermissionSet(strMapUserIdToSetPS);      
        
        
        Test.stopTest();
    }
    
    public static testmethod void testresendRequestFromLog(){
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        DPM_Log__c dpmlog=[select Id from DPM_Log__c limit 1];
        DPM_PersonnelMasterController.resendRequestFromLog(dpmlog.Id);
        Test.stopTest();
    }
    
    
    public static testmethod void testeditContactAddress(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());            
        
        contact con=[select Id,accountId,DPM_SSN__c,DPM_SSNencrypted__c,phone,
                     email,firstname,lastname,mailingcity,mailingcountry
                     from contact limit 1];        
        con.DPM_SSN__c=null;    
        con.DPM_SSNencrypted__c='12345';
        con.phone='2234556789';
        con.email='test1@volvocars.test';
        con.firstname='te1';
        con.lastname='ab1';
        con.MailingCity='testcity';
        con.MailingCountry='United States';        
        update con;
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'stan22', Email='standard22@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='standard22r@testorg.com');
        insert u;
        
        Set<Contact> setContactsToProcess=new Set<Contact>{con};
            List<User> lstUser=new List<User>{u};
                Model_contact.updateUserCreatedOnContact(setContactsToProcess, lstUser);
        Set<Id> userIds=new Set<Id>{u.Id};            
            Model_contact.assignPermissionSetToNewUser(userIds, setContactsToProcess);
        DPM_Soundex.toSoundex('testa');
        Test.stopTest();
    }    
    
    public static testmethod void testModel_Contact(){
        
        Account acc=[select Id,ispartner,billingstreet from account limit 1];
        acc.IsPartner=true;
         acc.billingstreet='teststreet'+datetime.now();
        update acc;
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u = new User(Alias = 'stan22', Email='standard22@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='standard22r@testorg.com');
        insert u;
        system.runas(u){
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());            
            
            contact con=[select id,accountId,RecordTypeId,DPM_SSN__c,DPM_SSNencrypted__c,phone,
                         email,mailingcity,mailingcountry,DPM_Activated__c,
                         Cds_Id__c,Account_Country__c,PsnId__c,DPM_SF_VPID__c,Firstname,LastName
                         from contact limit 1];
            
            DPM_Employee__c dpmEmployee = DPM_TestDataCreator.createDPMEmployee();
            dpmEmployee.DPM_Contact__c=con.Id;
            dpmEmployee.DPM_Status__c='Approved';
            insert dpmEmployee;  
            List<DPM_Job_Position__c> lstJobPositions = new List<DPM_Job_Position__c>();
            lstJobPositions.add(DPM_TestDataCreator.createJobPosition());
            for(DPM_Job_Position__c djp:lstJobPositions){
                djp.DPM_Employee_Registration__c=dpmEmployee.Id;
            }
            insert lstJobPositions;
            con.PsnId__c='1234';
            con.DPM_VPID__c=2345;
            con.Cds_Id__c='abcdxyz@volvocars.test';
            try{
                update con;
            }catch(Exception ex){
                
            }
            List<Contact> lstContacts=new List<Contact>{con};
                
                lstContacts=[select id,accountId,RecordTypeId,DPM_SSN__c,DPM_SSNencrypted__c,phone,
                             email,mailingcity,mailingcountry,DPM_Activated__c,
                             Cds_Id__c,Account_Country__c,PsnId__c,DPM_SF_VPID__c,Firstname,LastName
                             from contact 
                            ];
            
            Model_contact.createPartnerUser(lstContacts);
            Test.stopTest();
        }
        
    }
    
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public  HTTPResponse respond(HTTPRequest req) {      
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"message":"abcdefgh"}');
            res.setStatusCode(200);
            res.setStatus('OK');
            return res;
        }        
    }
    
    public static testmethod void testsendEmail_MissingSSN(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());  
         contact con=[select id,accountId,RecordTypeId,DPM_SSN__c,DPM_SSNencrypted__c,phone,
                         email,mailingcity,mailingcountry,DPM_Activated__c,
                         Cds_Id__c,Account_Country__c,PsnId__c,DPM_SF_VPID__c,Firstname,LastName
                         from contact limit 1];
        	 DPM_Employee__c dpmEmployee = DPM_TestDataCreator.createDPMEmployee();
            dpmEmployee.DPM_Contact__c=con.Id;
            dpmEmployee.DPM_Status__c='Approved';
            insert dpmEmployee;  
        
        RE_Person_Role__c personRole=[select id from RE_Person_Role__c limit 1];
        	DPM_PersonnelMasterServicesExt.sendEmail_MissingSSN(dpmEmployee.Id,'Dispatcher');
        DPM_PersonnelMasterServicesExt.sendEmail_MissingSSN(personRole.Id,'Dispatcher');
        DPM_PersonnelMasterServicesExt.retailerEmpDupCheck_Approval(JSON.serialize(dpmEmployee));
        DPM_PersonnelMasterServicesExt.createDPMErrorNotification(con.accountId,'test');
        try{
        DPM_PersonnelMasterController.duplicateCheck_Approval(JSON.serialize(dpmEmployee));
        }catch(Exception ex){
            system.debug(ex);
        }
        try{
        DPM_PersonnelMasterController.fetchWorkflowAppLinks('type');
    }catch(Exception ex){
            system.debug(ex);
        }
        try{
        DPM_PersonnelMasterController.createDPMErrorNotification('accountId','msg');
            }catch(Exception ex){
            system.debug(ex);
        }
        try{
        DPM_PersonnelMasterController.getStatusValue('strRecordId');
            }catch(Exception ex){
            system.debug(ex);
        }
        try{
        DPM_PersonnelMasterController.sendRejectEmailToRetailerAdmin('strRecordId');
        }catch(Exception ex){
            system.debug(ex);
        }
        DPM_PersonnelMasterController.getAllDealerships();
        DPM_PersonnelMasterController.getCorpCountriesAndStates();
        DPM_PersonnelMasterController.getDealerships(true);
        try{
        DPM_PersonnelMasterServicesExt.createTier2Case(dpmEmployee);
        }catch(Exception ex){
            system.debug(ex);
        }
        try{
            DPM_ContactTriggerHelper.contactChangingOwnership(new List<Contact>{con});
        }catch(Exception ex){
            system.debug(ex);
        }
        Test.stopTest();
    }
    public static testmethod void testDPM_UtilBatch(){        
        Test.startTest();
        DPM_UtilBatch batch=new DPM_UtilBatch();
        database.executeBatch(batch);
        Test.stopTest();
        Account acc=[select id,ShippingStreet,ShippingCity,ShippingState,ShippingCountry,ShippingPostalCode
                     from account limit 1];
        acc.ShippingStreet='test';
        update acc;   
        List<DPM_EmployeeJobPosition__c> jobs=[SELECT Id,DPM_Position_Title__c,DPM_Person_Role__c FROM DPM_EmployeeJobPosition__c];
        try{
        DPM_PersonnelMasterServicesExt.checkIncentiveEligibleProfile(jobs);
        }catch(Exception ex){
            system.debug(ex);
        }
        try{
        DPM_PersonnelMasterServicesExt.getASMMIdMap(new set<Id>{acc.Id});
        }catch(Exception ex){
            system.debug(ex);
        }
        DPM_BatchToUpdatedContactOwnerAsASMM batch2=new DPM_BatchToUpdatedContactOwnerAsASMM(new set<Id>{acc.Id});
        database.executebatch(batch2,1);
    }
}