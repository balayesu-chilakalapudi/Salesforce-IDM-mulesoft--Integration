public class DPM_EmployeeTriggerHelper { 
    public static void assignSoundex(Boolean isinsert,Boolean isupdate,List<DPM_Employee__c> dpmEmployeeList,Map<Id,DPM_Employee__c> oldmap,Map<Id,DPM_Employee__c> newmap){
        for(DPM_Employee__c dpmEmployeeObj:dpmEmployeeList){
            if((dpmEmployeeObj.DPM_Firstname_Soundex__c==null ||
                dpmEmployeeObj.DPM_Lastname_Soundex__c==null ||
                dpmEmployeeObj.DPM_Preferred_Firstname_Soundex__c==null) ||
               (isinsert || 
                (isupdate && 
                 (oldmap.get(dpmEmployeeObj.Id).DPM_Legal_First_Name__c!=newmap.get(dpmEmployeeObj.Id).DPM_Legal_First_Name__c || 
                  oldmap.get(dpmEmployeeObj.Id).DPM_Last_Name__c!=newmap.get(dpmEmployeeObj.Id).DPM_Last_Name__c || 
                  oldmap.get(dpmEmployeeObj.Id).DPM_Preferred_First_Name__c!=newmap.get(dpmEmployeeObj.Id).DPM_Preferred_First_Name__c
                 )
                ))){
                    if(dpmEmployeeObj.DPM_Legal_First_Name__c!=null){
                        dpmEmployeeObj.DPM_Firstname_Soundex__c=DPM_Soundex.toSoundex(dpmEmployeeObj.DPM_Legal_First_Name__c);
                    }
                    if(dpmEmployeeObj.DPM_Last_Name__c!=null){
                        dpmEmployeeObj.DPM_Lastname_Soundex__c=DPM_Soundex.toSoundex(dpmEmployeeObj.DPM_Last_Name__c);  
                    }
                    if(dpmEmployeeObj.DPM_Preferred_First_Name__c!=null){
                        dpmEmployeeObj.DPM_Preferred_Firstname_Soundex__c=DPM_Soundex.toSoundex(dpmEmployeeObj.DPM_Preferred_First_Name__c); 
                    }
                }
        }
    }
}