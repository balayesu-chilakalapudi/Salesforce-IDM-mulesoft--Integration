public class DPM_TestDataCreator {
    public static Country__c createCountry(String strName) {
        return new Country__c(Name=strName);
    }
    public static Region__c createRegion(String strName, Id idCountry) {
        return new Region__c(Name=strName,Country__c=idCountry);
    }
    public static Market__c createMarket(String strName, Id idMarket) {
        return new Market__c(Name=strName,Region__c=idMarket);
    }
    public static Account createAccount() {
        return new Account(Name='Test Account', 
                           BillingState = 'OH', 
                           BillingPostalCode = '44142', 
                           BillingStreet = '1234 Test Rd',
                           BillingCity = 'Cleveland', 
                           BillingCountry='United States',
                           ShippingState = 'OH', 
                           ShippingPostalCode = '44142', 
                           ShippingStreet = '1234 Test Rd',
                           ShippingCity = 'Cleveland', 
                           ShippingCountry='United States');
    }
    public static RE_Community_User_Settings__c createCommunityUserSettings(Id idAccount) {
        RE_Community_User_Settings__c currentSettings = new RE_Community_User_Settings__c();
        currentSettings.RE_Default_Account_Id__c = idAccount;
        currentSettings.SetupOwnerId = UserInfo.getUserId();
        return currentSettings;
    }
    public static DPM_Employee__c createDPMEmployee() {
        return new DPM_Employee__c(
        	DPM_Cell_Phone__c = '9999999999',
            DPM_City__c = 'Test City',
            DPM_Country__c = 'United States',
            DPM_Email__c = 'test123@test.com',
            DPM_Gender__c = 'Male',
            DPM_Hire_Date__c = system.today(),
            DPM_Home_Address_Street__c = 'Test Street 1',
            DPM_Home_Address_Street_2__c = 'Test Street 2',
            DPM_Home_Phone__c = '9988999988',
            DPM_Last_Name__c = 'TestLast',
            DPM_Legal_First_Name__c = 'First',
            DPM_Middle_Name__c = 'TestMiddle',
            DPM_Owner__c = true,
            DPM_Owner_Title__c = 'Chairman',
            DPM_Preferred_First_Name__c = 'Test',
            DPM_Prefix__c = 'Mr.',
            DPM_Retailer_Admin__c = true,
            DPM_US_State__c = 'NJ',
            DPM_Zipcode__c = '07003'
        );
    }
    public static DPM_Job_Position__c createJobPosition() {
        return new DPM_Job_Position__c(
        	Name = 'Cashier',
            DPM_Primary__c = true,
            DPM_Start_Date__c = system.today()
        );
    }
    public static Contact createContact(Id idAccount) {
        return new Contact(
        	FirstName = 'TestF',
            LastName = 'TestL',
            AccountId = idAccount,
            Email = 'test@test2.com', 
            Cds_Id__c = 'test001@volvocars.biz',
            DPM_VPID__c = 5012309 
        );
    }
    public static RE_Person_Role__c createPersonRole(Id idAccount, Id idContact, Id idUser) {
        return new RE_Person_Role__c(
        	RE_Contact__c = idContact,
            RE_Psn_Active_Date__c = system.today(),
            RE_Account__c = idAccount,
            RE_User__c = idUser,
            RE_Pos_Active_Date__c = system.today(),
            RE_IsAdmin__c = true,
            RE_Psn_Active__c = true,
            RE_Position_Active__c = true
        );
    }
    public static DPM_EmployeeJobPosition__c createEmployeeJobPosition(Id idPersonRole) {
        return new DPM_EmployeeJobPosition__c(
        	DPM_Person_Role__c = idPersonRole,
            DPM_Primary_Position__c = true,
            DPM_Position_Start_Date__c = system.today(),
            DPM_Position_Title__c = 'Cashier'
        );
    }
}