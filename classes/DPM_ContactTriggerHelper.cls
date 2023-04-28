public class DPM_ContactTriggerHelper {
/*
* Name      : DPM_ContactTriggerHelper
* Purpose   : Helper class for Contact Trigger  
* Author    : Krishna Singh
* Date      : 29-Sept-2020
* 
* */
    private static final Id retailerEmployeeRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Retailer Employee').getRecordTypeId();
    private static final Id supplierEmployeeRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Supplier Employee').getRecordTypeId(); 

    public static void generateVPID(List<Contact> contactList) {
        List<Contact> lstContactsWithoutVPID = new List<Contact>();
        Set<Id> setAccountIds = new Set<Id>();        
        for (Contact c : contactList) {
            if((c.RecordTypeId == retailerEmployeeRecordTypeId || c.RecordTypeId == supplierEmployeeRecordTypeId ) && c.DPM_VPID__c == NULL) {
                lstContactsWithoutVPID.add(c);
                setAccountIds.add(c.AccountId); 
            }
        }        
        if(!lstContactsWithoutVPID.isEmpty()) {
            Map<Id,Account> mapAccountIdToRetailerCode = new Map<Id,Account>();
            for(Account a : [SELECT Id,Retailer__c,DPM_Country_Code__c FROM Account WHERE Id IN :setAccountIds]) {
                mapAccountIdToRetailerCode.put(a.Id,a);
            }
            //cannot use Max as more than 50000 rows
            Contact con = [SELECT DPM_VPID__c FROM Contact WHERE (CreatedDate = LAst_N_Months:2 or CreatedDate = THIS_MONTH) and recordtype.name IN ('Retailer Employee','Supplier Employee') and DPM_VPID__c <> null ORDER BY DPM_VPID__c DESC NULLS LAST LIMIT 1];
            Integer intMaxVPID = Integer.valueOf(con.DPM_VPID__c);
            for(Contact c : lstContactsWithoutVPID) {
                c.DPM_VPID__c = intMaxVPID+1;
                c.Cnt_Id__c = mapAccountIdToRetailerCode.get(c.AccountId).Retailer__c+''+c.DPM_VPID__c;
                intMaxVPID+=1;
                //set vpid as psnId for mexico, 17-Feb-2022
                if(mapAccountIdToRetailerCode.get(c.AccountId).DPM_Country_Code__c==System.Label.DPM_Mexico_Country_Code &&
                  c.PsnId__c==null){
                    c.PsnId__c=String.valueOf(c.DPM_VPID__c);
                }
            }
        }
    }
    public static void handleIDMRequests(List<Contact> contactList,Map<Id,Contact> oldConMap) {
        List<IDMUpdateRequest> lstIDMUpdateRequests = new List<IDMUpdateRequest>();
        Set<Id> setContactIdsForCDSIDCreation = new Set<Id>();
        for(Contact c : contactList) {
            if((c.RecordTypeId == retailerEmployeeRecordTypeId || c.RecordTypeId == supplierEmployeeRecordTypeId ) && c.PsnId__c != NULL) {
                if(oldConMap == NULL || (c.PsnId__c != oldConMap.get(c.Id).PsnId__c)) {
                    setContactIdsForCDSIDCreation.add(c.Id);
                }
                if(oldConMap != NULL) {
                    if(c.Phone != oldConMap.get(c.Id).Phone) {
                        lstIDMUpdateRequests.add(new IDMUpdateRequest(c.Id,c.Phone,oldConMap.get(c.Id).Phone,'phonenumber',''));
                    }
                    if(c.DPM_Personal_Email__c != oldConMap.get(c.Id).DPM_Personal_Email__c) {
                        lstIDMUpdateRequests.add(new IDMUpdateRequest(c.Id,c.DPM_Personal_Email__c,oldConMap.get(c.Id).DPM_Personal_Email__c,'altemail',''));
                    }
                    if(c.FirstName != oldConMap.get(c.Id).FirstName) {
                        lstIDMUpdateRequests.add(new IDMUpdateRequest(c.Id,c.FirstName,oldConMap.get(c.Id).FirstName,'firstname',''));
                    }
                    if(c.LastName != oldConMap.get(c.Id).LastName) {
                        lstIDMUpdateRequests.add(new IDMUpdateRequest(c.Id,c.LastName,oldConMap.get(c.Id).LastName,'lastname',''));
                    }
                    if(c.MailingCity != oldConMap.get(c.Id).MailingCity) {
                        lstIDMUpdateRequests.add(new IDMUpdateRequest(c.Id,c.MailingCity,oldConMap.get(c.Id).MailingCity,'city',''));
                    }
                    if(c.MailingCountry != oldConMap.get(c.Id).MailingCountry) {
                        lstIDMUpdateRequests.add(new IDMUpdateRequest(c.Id,c.MailingCountry,oldConMap.get(c.Id).MailingCountry,'country',''));
                    }
                }
            }
        }  
        if(!setContactIdsForCDSIDCreation.isEmpty()) {
            DPM_PersonnelMasterServices.performCallouts('IDMCreate',JSON.serialize(setContactIdsForCDSIDCreation));
        }
        if(!lstIDMUpdateRequests.isEmpty()) {
            //Reusing CBV label for Mulesoft Integration user
            //Temporary check until Oracle Decommission
            if(UserInfo.getName() != Label.CBV_MulesoftIntegration) {
                DPM_PersonnelMasterServices.performCallouts('IDMUpdate_Contact',JSON.serialize(lstIDMUpdateRequests));
            }
        }
    }
    //1/21/2021, Create encryption /decryption service for SSN/SIN field
    public static void doEncryptDecryptSSN(List<Contact> conlist,Boolean blnIsInsert, Map<Id,Contact> oldmap){
        Map<Id,String> mapContactIdToType = new Map<Id,String>();
        //query contacts after insert/update
        for(Contact con : conlist){
            //handle encryption
            if(blnIsInsert) {
                if(con.DPM_SSN__c!=null) {
                    mapContactIdToType.put(con.Id,'Encrypt');
                }
                if(con.DPM_SSN__c==null && con.DPM_SSNEncrypted__c!=null) {
                    mapContactIdToType.put(con.Id,'Decrypt');
                }
            } else {
                // handle decryption
                if(con.DPM_SSN__c!=oldmap.get(con.Id).DPM_SSN__c && con.DPM_SSN__c!=null) {
                    mapContactIdToType.put(con.Id,'Encrypt');
                }
                if(con.DPM_SSNEncrypted__c!=oldmap.get(con.Id).DPM_SSNEncrypted__c && con.DPM_SSNEncrypted__c!=null) {
                    mapContactIdToType.put(con.Id,'Decrypt');
                }
            }            
        }
        if(!mapContactIdToType.isEmpty()) {
            DPM_PersonnelMasterServices.performCallouts('EncryptDecryptSSN',JSON.serialize(mapContactIdToType));
        }
    }
    public class IDMUpdateRequest {
        public Id idContact;
        public String strCDSID;
        public String strNewValue;
        public String strOldValue;
        public String strField;
        public String personRoleId;
        public IDMUpdateRequest(Id idContact, String strNewValue, String strOldValue, String strField,String personRoleId) {
            this.idContact = idContact;
            this.strNewValue = strNewValue;
            this.strOldValue = strOldValue;
            this.strField = strField;
            this.personRoleId = personRoleId;
        }
        public IDMUpdateRequest(String strCDSID, String strNewValue, String strOldValue, String strField,String personRoleId) {
            this.strCDSID = strCDSID;
            this.strNewValue = strNewValue;
            this.strOldValue = strOldValue;
            this.strField = strField;
            this.personRoleId = personRoleId;
        }
    }
    public static void assignSoundex(Boolean isinsert,Boolean isupdate,List<Contact> contactList,Map<Id,Contact> oldmap,Map<Id,Contact> newmap){        
        for(Contact contactObj:contactList){
            if(contactObj.RecordTypeId == retailerEmployeeRecordTypeId){
            if((contactObj.DPM_Firstname_Soundex__c==null ||
                contactObj.DPM_Lastname_Soundex__c==null ||
                contactObj.DPM_Preferred_Firstname_Soundex__c==null) ||
               (isinsert || 
                (isupdate && 
                 (oldmap.get(contactObj.Id).Firstname!=newmap.get(contactObj.Id).Firstname || 
                  oldmap.get(contactObj.Id).Lastname!=newmap.get(contactObj.Id).Lastname || 
                  oldmap.get(contactObj.Id).DPM_Preferred_First_Name__c!=newmap.get(contactObj.Id).DPM_Preferred_First_Name__c
                 )
                ))){
                    if(contactObj.Firstname!=null){
                        contactObj.DPM_Firstname_Soundex__c=DPM_Soundex.toSoundex(contactObj.Firstname);
                    }
                    if(contactObj.Lastname!=null){
                        contactObj.DPM_Lastname_Soundex__c=DPM_Soundex.toSoundex(contactObj.Lastname);  
                    }
                    if(contactObj.DPM_Preferred_First_Name__c!=null){
                        contactObj.DPM_Preferred_Firstname_Soundex__c=DPM_Soundex.toSoundex(contactObj.DPM_Preferred_First_Name__c); 
                    }
                }
            }
        }
    }
    public static void accountChangingOwnership(Map<Id,Contact> oldMap,Map<Id,Contact> newmap,List<Contact> lstContacts){
        Set<Id> setAccountIdsToProcess = new Set<Id>();
        Map<Id,String> accountIdASMMIdMap = new Map<Id,String>();
        for(Contact contactObj:lstContacts){
            if(contactObj.RecordTypeId == retailerEmployeeRecordTypeId && oldMap.get(contactObj.Id).accountId!=newMap.get(contactObj.Id).accountId &&
            contactObj.accountId!=null){
                setAccountIdsToProcess.add(contactObj.accountId);
            }
        }
        if(!setAccountIdsToProcess.isEmpty()) {
            accountIdASMMIdMap = DPM_PersonnelMasterServicesExt.getASMMIdMap(setAccountIdsToProcess);
            for(Contact con:lstContacts) {
                if(setAccountIdsToProcess.contains(con.AccountId)) {
                    String strASMMId = accountIdASMMIdMap.get(con.AccountId);
                    if(strASMMId != null){
                        con.ownerId = strASMMId;
                    }
                }            
            }
        }        
    }
    // For US: 2388816 When ever contact inserted need to assign owner as After Sales Market Manager.
    public static void contactChangingOwnership(List<Contact> lstContacts){
        Set<Id> setAccountIdsToProcess = new Set<Id>();
        Map<Id,String> accountIdASMMIdMap = new Map<Id,String>();
        for(Contact contactObj:lstContacts){
            if(contactObj.RecordTypeId == retailerEmployeeRecordTypeId && contactObj.accountId != null){
                setAccountIdsToProcess.add(contactObj.accountId);
            }
        }
        if(!setAccountIdsToProcess.isEmpty()) {
            accountIdASMMIdMap = DPM_PersonnelMasterServicesExt.getASMMIdMap(setAccountIdsToProcess);
            for(Contact con:lstContacts) {
                String strASMMId = accountIdASMMIdMap.get(con.AccountId);
                if(strASMMId != null){
                    con.ownerId = strASMMId;
                }
            }
        }        
    }
}