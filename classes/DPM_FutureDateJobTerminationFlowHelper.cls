public with sharing class DPM_FutureDateJobTerminationFlowHelper{    
    public DPM_FutureDateJobTerminationFlowHelper() { 
        
    }
    
    @InvocableMethod
    public static void getJobPositionIds(List<String> positionIds) {        
        Set<Id> personRoleIds = new Set<Id>(); 
        Set<String> positionIdset=new Set<String>();
        for(String positionId:positionIds){
            positionIdset.add(positionId);
        }
        //query existing schedules 
        Set<String> existingSchedules=new Set<String>(); 
        for(CronTrigger schedule:[SELECT Id, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType FROM CronTrigger ORDER BY CreatedDate ASC]){
            existingSchedules.add(schedule.CronJobDetail.Name);
        }   
        Set<Id> queuedPersonRoleIds=new Set<Id>(); 
        for (DPM_EmployeeJobPosition__c job : [SELECT Id, Name, DPM_Position_Title__c, DPM_Primary_Position__c,DPM_Person_Role__c,DPM_Person_Role__r.DPM_CDS_Id__c,DPM_Position_End_Date__c,DPM_Person_Role__r.RE_Employee_Position__c 
                                               FROM DPM_EmployeeJobPosition__c WHERE Id in :positionIdset
                                              ]) {
                                                  if(job.DPM_Person_Role__c!=null &&
                                                     job.DPM_Person_Role__r.DPM_CDS_Id__c!=null){    
                                                         //future date checking                                            
                                                         if(job.DPM_Position_End_Date__c!=null &&
                                                            job.DPM_Position_End_Date__c>System.TODAY() &&
                                                            !existingSchedules.contains('DPM_FutureDateJobTerminationFlow_'+job.Name)){  
                                                                Date scheduled_date=job.DPM_Position_End_Date__c+1;
                                                                System.schedule('DPM_FutureDateJobTerminationFlow_'+job.Name,
                                                                                '0 0 0 '+scheduled_date.day()+' '+scheduled_date.month()+' ? '+scheduled_date.year(),
                                                                                new DPM_ScheduleJobTermination(job.DPM_Person_Role__r.DPM_CDS_Id__c,job.DPM_Person_Role__r.RE_Employee_Position__c ,job.DPM_Person_Role__r.RE_Employee_Position__c,'title',job.DPM_Person_Role__c));                                                        
                                                            }
                                                         //present day checking
                                                         if(job.DPM_Position_End_Date__c!=null &&
                                                            (job.DPM_Position_End_Date__c).day()==(System.TODAY()).day() &&
                                                            (job.DPM_Position_End_Date__c).month()==(System.TODAY()).month() &&
                                                            (job.DPM_Position_End_Date__c).year()==(System.TODAY()).year() &&
                                                            !existingSchedules.contains('DPM_FutureDateJobTerminationFlow_'+job.Name)){
                                                                //schedule it for next day
                                                                Date scheduled_date=job.DPM_Position_End_Date__c+1;
                                                                System.schedule('DPM_FutureDateJobTerminationFlow_'+job.Name,
                                                                                '0 0 0 '+scheduled_date.day()+' '+scheduled_date.month()+' ? '+scheduled_date.year(),
                                                                                new DPM_ScheduleJobTermination(job.DPM_Person_Role__r.DPM_CDS_Id__c,job.DPM_Person_Role__r.RE_Employee_Position__c ,job.DPM_Person_Role__r.RE_Employee_Position__c ,'title',job.DPM_Person_Role__c));                                                        
                                                                
                                                            }
                                                         // end date not given, update personrole immediately for 1 time
                                                         if(job.DPM_Position_End_Date__c==null){
                                                             if(!queuedPersonRoleIds.contains(job.DPM_Person_Role__c)){
                                                                 queuedPersonRoleIds.add(job.DPM_Person_Role__c);
                                                                 System.enqueueJob(new DPM_JobPositionUpdateQueue(job.DPM_Person_Role__r.DPM_CDS_Id__c,job.DPM_Person_Role__r.RE_Employee_Position__c ,job.DPM_Person_Role__r.RE_Employee_Position__c ,'title',job.DPM_Person_Role__c));                                                        
                                                             }
                                                         }
                                                     }
                                              }      
    }   
    
    
    
}