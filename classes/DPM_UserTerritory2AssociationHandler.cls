public class DPM_UserTerritory2AssociationHandler {
    public static void checkASMMAssignment(Boolean blnDelete,List<UserTerritory2Association> lstUserTerritoryAssocations,Map<Id,UserTerritory2Association> oldUserTerritory2AssociationMap) {
        Map<Id,UserTerritory2Association> mapTerritory2IdWithUserAssociation = new Map<Id,UserTerritory2Association>();
        for(UserTerritory2Association userTerritoryAssociation : lstUserTerritoryAssocations) {
            if(blnDelete) {
                if(userTerritoryAssociation.RoleInTerritory2 == 'Aftersales Market Manager') {
                    mapTerritory2IdWithUserAssociation.put(userTerritoryAssociation.Territory2Id,userTerritoryAssociation);
                }
            } else {
                if(userTerritoryAssociation.RoleInTerritory2 != 'Aftersales Market Manager' && oldUserTerritory2AssociationMap.get(userTerritoryAssociation.Id).RoleInTerritory2 == 'Aftersales Market Manager') {
                    mapTerritory2IdWithUserAssociation.put(userTerritoryAssociation.Territory2Id,userTerritoryAssociation);
                }
            }            
        }
        //system.debug('herer123$ '+mapTerritory2IdWithUserAssociation);
        set<Id> setTerritoryIdForContactOwnerChange = new set<Id>();
        for(Territory2 objTerritory : [SELECT Id, (SELECT Id FROM UserTerritory2Associations WHERE RoleInTerritory2 = 'Aftersales Market Manager') FROM Territory2 WHERE Id IN :mapTerritory2IdWithUserAssociation.keySet() AND Territory2Type.DeveloperName = :RE_Territory.TERRITORY_TYPE_MARKET]) {
            if(objTerritory.UserTerritory2Associations.isEmpty()) {
                mapTerritory2IdWithUserAssociation.get(objTerritory.Id).addError('There should be an AfterSales Market Manager assigned to the market.');
            } else {
                setTerritoryIdForContactOwnerChange.add(objTerritory.Id);
            }
        }
        if(!setTerritoryIdForContactOwnerChange.isEmpty()) {
            set<Id> setAccountId = new set<Id>();
            for(ObjectTerritory2Association objTerrAssociation : [SELECT Id,ObjectId FROM ObjectTerritory2Association WHERE Territory2Id IN :setTerritoryIdForContactOwnerChange]) {
                setAccountId.add(objTerrAssociation.ObjectId);
            }
            DPM_AccountTriggerHandler.updateContactOwners(setAccountId);
        }
    }    
}