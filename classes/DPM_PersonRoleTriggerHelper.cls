public class DPM_PersonRoleTriggerHelper {
/*
* Name      : DPM_PersonRoleTriggerHelper
* Purpose	: Helper class for Person Role Trigger  
* Author	: Krishna Singh
* Date		: 29-Sept-2020
* 
* */
    public static final Id recordTypeIdContact = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Retailer Employee').getRecordTypeId();
    public static void populateCDSIDOnContact(List<RE_Person_Role__c> personRoleList,Map<Id,RE_Person_Role__c> oldPersonRoleMap) {
        List<Id> lstContactIds = new List<Id>();
        Map<Id,Contact> mapContactsToUpdate = new Map<Id,Contact>();
        List<RE_Person_Role__c> lstPersonRolesToConsider = new List<RE_Person_Role__c>();
        for(RE_Person_Role__c personRole : personRoleList) {
            if(personRole.DPM_CDS_Id__c != oldPersonRoleMap.get(personRole.Id).DPM_CDS_Id__c && personRole.RE_Contact__c != NULL) {
                lstContactIds.add(personRole.RE_Contact__c);
                lstPersonRolesToConsider.add(personRole);
            }
            //Update Contact Email, Account and CDSID in case of Primary Store switch
            if(personRole.DPM_Primary__c != oldPersonRoleMap.get(personRole.Id).DPM_Primary__c && personRole.DPM_Primary__c && personRole.RE_Contact__c != NULL) {
                mapContactsToUpdate.put(
                    personRole.RE_Contact__c,
                    new Contact(
                        Id = personRole.RE_Contact__c,
                        Cds_Id__c = personRole.DPM_CDS_Id__c,
                        Email = personRole.DPM_Work_Email__c,
                        AccountId = personRole.RE_Account__c
                    )
                );
            }
            //Update Email on Contact when Work Email on Primary PR changes
            if(personRole.DPM_Work_Email__c != oldPersonRoleMap.get(personRole.Id).DPM_Work_Email__c && personRole.DPM_Primary__c && personRole.RE_Contact__c != NULL) {
                mapContactsToUpdate.put(
                    personRole.RE_Contact__c,
                    new Contact(
                        Id = personRole.RE_Contact__c,
                        Email = personRole.DPM_Work_Email__c
                    )
                );
            }
        }
        if(!lstPersonRolesToConsider.isEmpty()) {
            List<DPM_Employee__c> lstDPMEmployee = [SELECT Id,DPM_Contact__c,DPM_Request_Type__c FROM DPM_Employee__c WHERE DPM_Contact__c IN :lstContactIds AND DPM_Status__c = 'Approved'];
            if(!lstDPMEmployee.isEmpty()) {
                Map<Id,DPM_Employee__c> mapContactIdtoDPMEmployee = new Map<Id,DPM_Employee__c>();                
                List<DPM_Employee__c> lstDPMEmployeesToUpdate = new List<DPM_Employee__c>();
                for(DPM_Employee__c dpmEmployee : lstDPMEmployee) {
                    mapContactIdtoDPMEmployee.put(dpmEmployee.DPM_Contact__c,dpmEmployee);
                }
                for(RE_Person_Role__c personRole : lstPersonRolesToConsider) {
                    if(mapContactIdtoDPMEmployee.keyset().contains(personRole.RE_Contact__c)) {
                        if(personRole.DPM_Primary__c) {
                            mapContactsToUpdate.put(
                                personRole.RE_Contact__c,
                                new Contact(
                                    Id = personRole.RE_Contact__c,
                                    Cds_Id__c = personRole.DPM_CDS_Id__c,
                                    Email = personRole.DPM_Work_Email__c,
                                    AccountId = personRole.RE_Account__c
                                )
                            );
                        }                        
                        lstDPMEmployeesToUpdate.add(
                            new DPM_Employee__c(
                                Id = mapContactIdtoDPMEmployee.get(personRole.RE_Contact__c).Id,
                                DPM_Status__c = 'Completed'
                            )
                        );
                    }
                }                
                if(!lstDPMEmployeesToUpdate.isEmpty()) {
                    update lstDPMEmployeesToUpdate;
                }
            }
        }
        if(!mapContactsToUpdate.isEmpty()) {
            update mapContactsToUpdate.values();
        }
    }
    public static void setCntIdOnPersonRole(List<RE_Person_Role__c> personRoleList,Boolean blnUpdate,Map<Id,RE_Person_Role__c> oldPersonRoleMap) {
        Set<Id> setAccountIds = new Set<Id>();
        Set<Id> setContactIds = new Set<Id>();
        List<RE_Person_Role__c> lstPersonRolesToConsider = new List<RE_Person_Role__c>();
        for(RE_Person_Role__c personRole : personRoleList) {
            if(personRole.RE_Cnt_Id__c == NULL) {
                setAccountIds.add(personRole.RE_Account__c);
                setContactIds.add(personRole.RE_Contact__c);
                lstPersonRolesToConsider.add(personRole);
            } else if(blnUpdate && (personRole.RE_Account__c != oldPersonRoleMap.get(personRole.Id).RE_Account__c || personRole.RE_Contact__c != oldPersonRoleMap.get(personRole.Id).RE_Contact__c)) {
                setAccountIds.add(personRole.RE_Account__c);
                setContactIds.add(personRole.RE_Contact__c);
                lstPersonRolesToConsider.add(personRole);
            }
        }
        if(!lstPersonRolesToConsider.isEmpty()) {
            Map<Id,String> mapAccountIdToRetailerCode = new Map<Id,String>();
            Map<Id,String> mapContactIdToVPID = new Map<Id,String>();
            for(Account a : [SELECT Id,Retailer__c FROM Account WHERE Id IN :setAccountIds]) {
                mapAccountIdToRetailerCode.put(a.Id,a.Retailer__c);
            }            
            for(Contact c : [SELECT Id,DPM_SF_VPID__c FROM Contact WHERE Id IN :setContactIds]) {
                mapContactIdToVPID.put(c.Id,String.valueOf(c.DPM_SF_VPID__c));
            }
            for(RE_Person_Role__c personRole : lstPersonRolesToConsider) {
                if(mapContactIdToVPID.get(personRole.RE_Contact__c)!=NULL && mapAccountIdToRetailerCode.get(personRole.RE_Account__c)!=NULL) {
					personRole.RE_Cnt_Id__c = mapAccountIdToRetailerCode.get(personRole.RE_Account__c)+''+mapContactIdToVPID.get(personRole.RE_Contact__c);
                }                
            }
        }
    }
    public static void uncheckPrimaryForTerminatedPersonRole(List<RE_Person_Role__c> personRoleList,Map<Id,RE_Person_Role__c> oldPersonRoleMap) {
        for(RE_Person_Role__c personRole : personRoleList) {
            if(personRole.RE_Psn_Active__c != oldPersonRoleMap.get(personRole.Id).RE_Psn_Active__c && !personRole.RE_Psn_Active__c) {
                personRole.DPM_Primary__c = false;
            }
        }
    }
    public static void handleIDMRequests(List<RE_Person_Role__c> personRoleList,Map<Id,RE_Person_Role__c> oldPersonRoleMap) {
        Set<Id> setContactIds = new Set<Id>();
        Set<String> setPrimaryCDSIDsToBeDeactivated = new Set<String>();
        List<DPM_ContactTriggerHelper.IDMUpdateRequest> lstIDMUpdateRequests = new List<DPM_ContactTriggerHelper.IDMUpdateRequest>();
        for(RE_Person_Role__c personRole : personRoleList) {
            //If the employee is terminated in a store
            if(personRole.RE_Psn_Active__c != oldPersonRoleMap.get(personRole.Id).RE_Psn_Active__c && !personRole.RE_Psn_Active__c) {
                if(!oldPersonRoleMap.get(personRole.Id).DPM_Primary__c) {
                    lstIDMUpdateRequests.add(new DPM_ContactTriggerHelper.IDMUpdateRequest(personRole.DPM_CDS_Id__c,'false','true','cdsstatus',''));
                } else {
                    setPrimaryCDSIDsToBeDeactivated.add(personRole.DPM_CDS_Id__c);  
                    setContactIds.add(personRole.RE_Contact__c);
                }                
            }
            if(personRole.RE_Employee_Position__c != oldPersonRoleMap.get(personRole.Id).RE_Employee_Position__c) {
                lstIDMUpdateRequests.add(new DPM_ContactTriggerHelper.IDMUpdateRequest(personRole.DPM_CDS_Id__c,personRole.RE_Employee_Position__c,oldPersonRoleMap.get(personRole.Id).RE_Employee_Position__c,'title',personRole.id));
            }
            if(personRole.DPM_Work_Email__c != oldPersonRoleMap.get(personRole.Id).DPM_Work_Email__c) {
                lstIDMUpdateRequests.add(new DPM_ContactTriggerHelper.IDMUpdateRequest(personRole.DPM_CDS_Id__c,personRole.DPM_Work_Email__c,oldPersonRoleMap.get(personRole.Id).DPM_Work_Email__c,'mailaddress',''));
            }
        }
        if(!setContactIds.isEmpty()) {
            List<RE_Person_Role__c> lstPersonRolesToUpdate = new List<RE_Person_Role__c>();
            List<Id> lstContactsForDeactivation = new List<Id>();
            for(Contact c : [SELECT Id,Cds_Id__c,(SELECT Id,DPM_CDS_Id__c,RE_Psn_Active_Date__c FROM Person_Roles__r WHERE RE_Psn_Active__c = TRUE ORDER BY RE_Psn_Active_Date__c LIMIT 1) FROM Contact WHERE Id IN :setContactIds]) {
                if(c.Person_Roles__r.isEmpty()) {
                    // No active person roles
                    lstContactsForDeactivation.add(c.Id);                    
                } else {
                    if(setPrimaryCDSIDsToBeDeactivated.contains(c.Cds_Id__c)) {
                        //switching primary person role which will trigger primary CDSID switch
                        lstPersonRolesToUpdate.add(
                            new RE_Person_Role__c(
                                Id = c.Person_Roles__r[0].Id,
                                DPM_Primary__c = TRUE
                            )
                        );  
                        //CDSID switch if secondary found
                       lstIDMUpdateRequests.add(new DPM_ContactTriggerHelper.IDMUpdateRequest(c.Cds_Id__c,c.Person_Roles__r[0].DPM_CDS_Id__c,c.Cds_Id__c,'CDSIDSwitch',''));
                       //remove this CDSID from the set
                       setPrimaryCDSIDsToBeDeactivated.remove(c.Cds_Id__c);
                    }                    
                }
            }
            if(!setPrimaryCDSIDsToBeDeactivated.isEmpty()) {
                // deactivate CDSIDs if secondary not found
                for(String strCDSID : setPrimaryCDSIDsToBeDeactivated) {
                    lstIDMUpdateRequests.add(new DPM_ContactTriggerHelper.IDMUpdateRequest(strCDSID,'false','true','cdsstatus',''));
                }
            }
            if(!lstPersonRolesToUpdate.isEmpty()) {
                update lstPersonRolesToUpdate;
            }
            if(!lstContactsForDeactivation.isEmpty()) {
                List<Id> lstUserIdsForDeactivation = new List<Id>();
                for(User u : [SELECT Id,UserName,FederationIdentifier,CommunityNickname,Alias FROM User WHERE ContactId IN :lstContactsForDeactivation]) {
                    lstUserIdsForDeactivation.add(u.Id);                    
                }
                if(!lstUserIdsForDeactivation.isEmpty()) {
                    deactivateUsers(lstUserIdsForDeactivation);
                }
            }
        }
        if(!lstIDMUpdateRequests.isEmpty()) {
            //Reusing CBV label for Mulesoft Integration user
            //Temporary check until Oracle Decommission
            if(UserInfo.getName() != Label.CBV_MulesoftIntegration) {
                DPM_PersonnelMasterServices.performCallouts('IDMUpdate',JSON.serialize(lstIDMUpdateRequests));
            }            
        }        
    }    
    @future
    public static void deactivateUsers(List<Id> lstUserIdsForDeactivation) {
        List<User> lstUsersForDeactivation = new List<User>();
        for(User u : [SELECT Id,UserName,FederationIdentifier,CommunityNickname,Alias FROM User WHERE Id IN :lstUserIdsForDeactivation]) {
            lstUsersForDeactivation.add(
                new User(
                    Id = u.Id,
                    FederationIdentifier = '',
                    Username = u.Username+Math.round(Math.random()*100),
                    CommunityNickname = u.CommunityNickname+Math.round(Math.random()*100),
                    Alias = (u.Alias.length()>5?u.Alias.substring(0,5):u.alias)+Math.round(Math.random()*100),
                    IsActive = false
                )
            );                    
        }
        if(!lstUsersForDeactivation.isEmpty()) {
            update lstUsersForDeactivation;
        }
    }
    public static void handlePrimaryPersonRoleCreation(List<RE_Person_Role__c> personRoleList) {
        Map<Id,Contact> mapContactsToUpdate = new Map<Id,Contact>();
        for(RE_Person_Role__c personRole : personRoleList) {
            if(personRole.DPM_Primary__c) {
                mapContactsToUpdate.put(
                    personRole.RE_Contact__c,
                    new Contact(
                        Id = personRole.RE_Contact__c,
                        Cds_Id__c = personRole.DPM_CDS_Id__c,
                        Email = personRole.DPM_Work_Email__c,
                        AccountId = personRole.RE_Account__c
                    )
                );
            }
        }
        if(!mapContactsToUpdate.isEmpty()) {
            update mapContactsToUpdate.values();
        }
    }
    public static void checkOwnerAndAssignPersona(List<RE_Person_Role__c> personRoleList) {
        Map<String,RE_Job_to_Persona_map__mdt> mapJobPositionToPersona = DPM_EmployeeJobPositionTriggerHelper.getPersonaMap();
        for(RE_Person_Role__c personRole : personRoleList) {
            if(personRole.DPM_Owner__c) {
                personRole.RE_Persona__c = (mapJobPositionToPersona.keyset().contains(personRole.DPM_Owner_Title__c)?mapJobPositionToPersona.get(personRole.DPM_Owner_Title__c).Persona__c:NULL);
            } 
        }
    }
    public static void useStoreAddressAsWorkAddress(List<RE_Person_Role__c> personRoleList) {
        List<RE_Person_Role__c> lstPersonRolesToConsider = new List<RE_Person_Role__c>();
        Set<Id> setAccountIds = new Set<Id>();
        for(RE_Person_Role__c personRole : personRoleList) {
            if(personRole.DPM_Work_Address_Same_as_Store_Address__c) {
                lstPersonRolesToConsider.add(personRole);
                setAccountIds.add(personRole.RE_Account__c);
            }
        }
        if(!lstPersonRolesToConsider.isEmpty()) {
            Map<Id,Account> mapAccIdToAcc = new Map<Id,Account>([SELECT Id,BillingStreet,BillingCity,BillingCountry,BillingState,BillingPostalCode FROM Account WHERE Id IN :setAccountIds]);
            for(RE_Person_Role__c personRole : lstPersonRolesToConsider) {
                personRole.DPM_Work_Address_Street__c = mapAccIdToAcc.get(personRole.RE_Account__c).BillingStreet;
                personRole.DPM_Work_Address_City__c = mapAccIdToAcc.get(personRole.RE_Account__c).BillingCity;
                personRole.DPM_Work_Address_Country__c = mapAccIdToAcc.get(personRole.RE_Account__c).BillingCountry;
                personRole.DPM_Work_Address_State__c = mapAccIdToAcc.get(personRole.RE_Account__c).BillingState;
                personRole.DPM_Work_Address_Zip_Postal_Code__c = mapAccIdToAcc.get(personRole.RE_Account__c).BillingPostalCode;
            }            
        }
    }
    public static void setPSNonActiveDateOnContact(Boolean isInsert,Boolean isUpdate,List<RE_Person_Role__c> newList,Map<Id,RE_Person_Role__c> oldMap){
        try{
        List<Contact> contactList=new List<Contact>();
        for(RE_Person_Role__c p:newList){
            if(p.RE_Psn_NonActive_Date__c!=null &&
             p.RE_Contact__c!=null){
            if(isInsert || (isUpdate && 
            p.RE_Psn_NonActive_Date__c!=oldMap.get(p.Id).RE_Psn_NonActive_Date__c)
            )
            {
                contactList.add(new Contact(Id=p.RE_Contact__c,
                Psn_NonActive_Date__c=p.RE_Psn_NonActive_Date__c));
            }
        }
        }
        if(!contactList.isEmpty()){
            map<id,contact> mapOfcontact = new map<id,contact>(contactList);
            update mapOfcontact.values();
        }
        }catch(Exception ex){
            system.debug(ex+'\n'+ex.getStackTraceString());
        }
    }
}