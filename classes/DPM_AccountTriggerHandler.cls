/**
* --------------------------------------------------------------------------------
* @Name         DPM_AccountTriggerHandler
* @Author       Krishna Singh
* @CreatedDate  03/23/2021
* --------------------------------------------------------------------------------
* @Description
*   Trigger handler for AccountTrigger
* --------------------------------------------------------------------------------
**/
public class DPM_AccountTriggerHandler {
	public static void changeWorkAddressOnPersonRoles(List<Account> newAccountList, Map<Id, Account> oldAccountMap) {
        Map<Id,Account> mapAccIdToAcc = new Map<Id,Account>();
        for(Account a : newAccountList) {
            if(a.ShippingStreet != oldAccountMap.get(a.Id).ShippingStreet
              || a.ShippingCity != oldAccountMap.get(a.Id).ShippingCity
              || a.ShippingState != oldAccountMap.get(a.Id).ShippingState
              || a.ShippingCountry != oldAccountMap.get(a.Id).ShippingCountry
              || a.ShippingPostalCode != oldAccountMap.get(a.Id).ShippingPostalCode) {
                mapAccIdToAcc.put(a.Id,a);
            }
        }
        if(!mapAccIdToAcc.isEmpty()) {
            list<RE_Person_Role__c> lstPersonRolesToUpdate = new list<RE_Person_Role__c>();
            for(RE_Person_Role__c personRole : [SELECT Id,RE_Account__c FROM RE_Person_Role__c WHERE RE_Account__c IN :mapAccIdToAcc.keyset() AND RE_Psn_Active__c=TRUE AND DPM_Work_Address_Same_as_Store_Address__c = TRUE]) {
                lstPersonRolesToUpdate.add(
                	new RE_Person_Role__c(
                    	Id = personRole.Id,
                        DPM_Work_Address_Street__c = mapAccIdToAcc.get(personRole.RE_Account__c).ShippingStreet,
                        DPM_Work_Address_City__c = mapAccIdToAcc.get(personRole.RE_Account__c).ShippingCity,
                        DPM_Work_Address_State__c = mapAccIdToAcc.get(personRole.RE_Account__c).ShippingState,
                        DPM_Work_Address_Country__c = mapAccIdToAcc.get(personRole.RE_Account__c).ShippingCountry,
                        DPM_Work_Address_Zip_Postal_Code__c = mapAccIdToAcc.get(personRole.RE_Account__c).ShippingPostalCode
                    )
                );
            }
            if(!lstPersonRolesToUpdate.isEmpty()) {
                update lstPersonRolesToUpdate;
            }
        }
    }
    // When Market Change on Account
    public static void marketChangingOnAccount(List<Account> newAccountList,Map<Id,Account> oldAccountMap){
		set<Id> setAccountId = new set<id>();       
        for(Account accountObj:newAccountList){
            //check if market changed on account
            if(accountObj.Market__c!=null && oldAccountMap.get(accountObj.Id).Market__c!=accountObj.Market__c) {
                setAccountId.add(accountObj.id);
            }
        }
        if(!setAccountId.isEmpty()) {
            updateContactOwners(setAccountId);
        }        
    }
    public static void updateContactOwners(set<Id> setAccountIds) {
        if(setAccountIds != null && !setAccountIds.isEmpty()){
            DPM_BatchToUpdatedContactOwnerAsASMM batch=new DPM_BatchToUpdatedContactOwnerAsASMM(setAccountIds);
            Database.executeBatch(batch,20);
        }
    }
}