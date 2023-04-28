trigger DPM_EmployeeJobPositionTrigger on DPM_EmployeeJobPosition__c (after insert,after update) {
    if (Trigger.isBefore) {
        //STUB
    } 
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
              DPM_EmployeeJobPositionTriggerHelper.updatePrimaryPositionOnPersonRole(Trigger.New);
        }
        if(Trigger.isUpdate) {
             DPM_EmployeeJobPositionTriggerHelper.updatePrimaryPositionOnPersonRole(Trigger.New);
        }
    }
}