global class DPM_BatchToUpdatedContactOwnerAsASMM implements Database.Batchable<sObject>,Database.Stateful {
    public set<Id> setAccountIds;
    public list<contact> contactListToBeUpdated;
    public map<Id,String> accountIdASMMIdMap;
    public DPM_BatchToUpdatedContactOwnerAsASMM(set<Id> setAccountIds){
        this.setAccountIds = setAccountIds;
        accountIdASMMIdMap=new Map<Id,String>();
        accountIdASMMIdMap = DPM_PersonnelMasterServicesExt.getASMMIdMap(setAccountIds);
    }
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return DataBase.getQueryLocator('SELECT Id, Name,accountId,ownerId FROM Contact where AccountId IN :setAccountIds');
    }    
    global void execute(Database.BatchableContext BC, List<contact> conList) {
        contactListToBeUpdated = new list<contact>();
        for(contact conObj: conList){
            //system.debug(accountIdASMMIdMap+' accid--> '+conObj.accountId);
            string marketOwner = accountIdASMMIdMap.get(conObj.accountId);
            if(marketOwner != null && marketOwner != conObj.OwnerId){
                conObj.OwnerId = marketOwner;
                contactListToBeUpdated.add(conObj);
            }
        }
        if(!contactListToBeUpdated.isEmpty()){
            update contactListToBeUpdated;
        }
    }   
    
    global void finish(Database.BatchableContext BC) {
    }
}