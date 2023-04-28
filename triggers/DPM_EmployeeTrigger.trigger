trigger DPM_EmployeeTrigger on DPM_Employee__c (before insert,before update) {
    if(trigger.isBefore){
        DPM_EmployeeTriggerHelper.assignSoundex(trigger.isinsert, trigger.isupdate, trigger.new, trigger.oldmap, trigger.newmap);
    }
}