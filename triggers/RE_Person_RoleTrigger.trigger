/**
* --------------------------------------------------------------------------------
* @Name         RE_Person_RoleTrigger
* @Author       Gary Hamilton
* @ModifiedBy   
* @Version      v1.0
* @CreatedDate  04-11-2018
* @UsedBy       RE_Person_Role__c object
* --------------------------------------------------------------------------------
* @Description
*   Person Role trigger
* --------------------------------------------------------------------------------
* @Changes
*        
* --------------------------------------------------------------------------------
**/
trigger RE_Person_RoleTrigger on RE_Person_Role__c (before insert, before update, after insert, after update, before delete, after delete) {
    if(!RE_Person_RoleTriggerStatic.dpm_stop_flag){       
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            RE_Person_Role_TriggerHelper.setActiveFlags(Trigger.new,Trigger.OldMap,Trigger.NewMap,Trigger.isInsert,Trigger.isUpdate);
            DPM_PersonRoleTriggerHelper.setCntIdOnPersonRole(Trigger.New,Trigger.isUpdate,Trigger.OldMap);
            if(Trigger.isUpdate) {
                DPM_PersonRoleTriggerHelper.uncheckPrimaryForTerminatedPersonRole(Trigger.New,Trigger.OldMap);
            }  
            DPM_PersonRoleTriggerHelper.checkOwnerAndAssignPersona(Trigger.New);
            DPM_PersonRoleTriggerHelper.useStoreAddressAsWorkAddress(Trigger.New);
        }
        else if (Trigger.isDelete) {
            //new RE_PersonRoleGroup(Trigger.old).deleteOldGroupMembers();
            //Database.executeBatch(new RE_PersonRoleGroupBatch(Trigger.oldMap.keySet(), 'delete'), 10);    
            //RE_PersonRoleGroupBatch.processDeletions((Trigger.old);          
            RE_PersonRoleGroupBatchHelper.processDeletions(Trigger.old);   
        }
    }
    else if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            RE_Person_Role_TriggerHelper.shareAccounts(Trigger.new);
            RE_Person_Role_TriggerHelper.updateDefaultAccount(Trigger.new,Trigger.OldMap);
            if (!System.isBatch()) {
                Database.executeBatch(new RE_PersonRoleGroupBatch(Trigger.newMap.keySet()), 10);                
            } 
            Trigger_On_Off__c settings = Trigger_On_Off__c.getInstance('Switch Off');
            if(settings!=NULL && !settings.Off__c){
                DPM_PersonRoleTriggerHelper.handlePrimaryPersonRoleCreation(Trigger.New);
            }
        }
        if(Trigger.isUpdate) {
            RE_Person_Role_TriggerHelper.shareAccounts(Trigger.new);
            RE_Person_Role_TriggerHelper.updateDefaultAccount(Trigger.new,Trigger.OldMap);
            if (!System.isBatch() && !Test.isRunningTest()) {
                Database.executeBatch(new RE_PersonRoleGroupBatch(Trigger.newMap.keySet()), 10);                
            }             
            Trigger_On_Off__c settings = Trigger_On_Off__c.getInstance('Switch Off');
            if(settings!=NULL && !settings.Off__c){
                DPM_PersonRoleTriggerHelper.populateCDSIDOnContact(Trigger.New,Trigger.OldMap);
                DPM_PersonRoleTriggerHelper.handleIDMRequests(Trigger.New,Trigger.OldMap);
            }
        }
        DPM_PersonRoleTriggerHelper.setPSNonActiveDateOnContact(Trigger.isInsert,Trigger.isUpdate,Trigger.New,Trigger.oldMap);
    }
    }
}