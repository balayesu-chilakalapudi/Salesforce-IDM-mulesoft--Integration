global class DPM_UtilBatch implements Database.Batchable<sObject> {
   private static final Id retailerEmployeeRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Retailer Employee').getRecordTypeId();
    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT DPM_Firstname_Soundex__c,DPM_Lastname_Soundex__c,DPM_Preferred_FirstName_Soundex__c,'+
            'Firstname,Lastname,DPM_Preferred_First_Name__c,RecordTypeId,'+
            '(SELECT DPM_Firstname_Soundex__c,DPM_Lastname_Soundex__c,DPM_Preferred_FirstName_Soundex__c,DPM_Legal_First_Name__c,DPM_Last_Name__c,DPM_Preferred_First_Name__c FROM DPM_Employee_Registrations__r)'+
            ' FROM Contact WHERE RecordtypeId = :retailerEmployeeRecordTypeId AND (DPM_Firstname_Soundex__c=NULL OR DPM_Lastname_Soundex__c=NULL OR DPM_Preferred_FirstName_Soundex__c=NULL)';
        system.debug('query:'+query);
        return Database.getquerylocator(query);
    }
    global void execute(Database.BatchableContext BC, List<Contact> existingContacts){
        List<Contact> lstContactsToUpdate=new List<Contact>();
        List<DPM_Employee__c> lstDpmEmployeesToUpdate=new List<DPM_Employee__c>();        
        for(Contact conObject:existingContacts){
            //update contacts
            conObject.DPM_Firstname_Soundex__c=DPM_Soundex.toSoundex(conObject.Firstname);
            conObject.DPM_Lastname_Soundex__c=DPM_Soundex.toSoundex(conObject.Lastname);
            conObject.DPM_Preferred_FirstName_Soundex__c=DPM_Soundex.toSoundex(conObject.DPM_Preferred_First_Name__c);
            lstContactsToUpdate.add(conObject);
            
            //updates dpmemployees
            for(DPM_Employee__c empObj:conObject.DPM_Employee_Registrations__r){
                empObj.DPM_Firstname_Soundex__c=DPM_Soundex.toSoundex(empObj.DPM_Legal_First_Name__c);
                empObj.DPM_Lastname_Soundex__c=DPM_Soundex.toSoundex(empObj.DPM_Last_Name__c);
                empObj.DPM_Preferred_FirstName_Soundex__c=DPM_Soundex.toSoundex(empObj.DPM_Preferred_First_Name__c);
                lstDpmEmployeesToUpdate.add(empObj);
            }
        }
        if(!lstContactsToUpdate.isEmpty()){
        	update lstContactsToUpdate;
        }
        if(!lstDpmEmployeesToUpdate.isEmpty()){
        	update lstDpmEmployeesToUpdate;
        }
    }
    global void finish(Database.BatchableContext BC){
        system.debug('Batch completed successfully');
    }
}