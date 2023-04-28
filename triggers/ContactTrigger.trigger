/**
* --------------------------------------------------------------------------------
* @Name         ContactTrigger.trigger
* @Author       Gary Hamilton
* @ModifiedBy   
* @Version      v1.0
* @CreatedDate  04-11-2018
* @UsedBy       Contact
* --------------------------------------------------------------------------------
* @Description
*  Trigger for Contact object 
* --------------------------------------------------------------------------------
* @Changes
* @Author       Dhiraj Kumar
* @ModifiedDate 06-28-2018   
@Description
*  Added code for Automate partner user creation

* @Changes
* @Author       Dhiraj Kumar
* @ModifiedDate 07-04-2018   
@Description
*  Added code for setting Contact as primary for a particular Retailer

* @Changes
* @Author       Dhiraj Kumar
* @ModifiedDate 11-12-2018   
@Description
*  Added code for Automate partner user creation on Contact record update based on certain criteria
* ---------------------------------------------------------------------------------------------
**/
trigger ContactTrigger on Contact (before insert, before update, after insert, after update) {
    try {
    	system.debug('*** ContactTrigger');
        if (Trigger.isBefore) {
            if(Trigger.isInsert) {                
                // Set Contact Recordtype based on parent Account
                RE_ContactTriggerHelper.setRecordtypeIds(Trigger.New);   
                DPM_ContactTriggerHelper.generateVPID(Trigger.New);
				DPM_ContactTriggerHelper.contactChangingOwnership(trigger.new);
            }
            DPM_ContactTriggerHelper.assignSoundex(trigger.isinsert, trigger.isupdate, trigger.new, trigger.oldmap, trigger.newmap);
			if(Trigger.isUpdate){
                DPM_ContactTriggerHelper.accountChangingOwnership(trigger.oldmap,trigger.newmap,trigger.new);
            }
        } 
        if(Trigger.isAfter) {
            if(Trigger.isInsert) {
                //Control the Boolean flag to make the trigger on/off on the fly 
                //This will help the Partner user creation logic NOT to execute whenever needed
                Trigger_On_Off__c settings = Trigger_On_Off__c.getInstance('Switch Off');
                if(!settings.Off__c){
                    Model_Contact.createPartnerUser(Trigger.New);
                }
                //RE_ContactTriggerHelper.setPersonRoles(Trigger.newMap);
                NRPP_CheckPrimaryContact.setPrimaryContact(Trigger.new);   
            }
            if(Trigger.isUpdate) {
                //RE_ContactTriggerHelper.setPersonRoles(Trigger.newMap);
                Trigger_On_Off__c settings = Trigger_On_Off__c.getInstance('Switch Off');
                if(!settings.Off__c){
                    Model_Contact.updateUserOnContactUpdation(Trigger.New,Trigger.OldMap);
                    DPM_ContactTriggerHelper.handleIDMRequests(Trigger.New,Trigger.OldMap);
                }
                NRPP_CheckPrimaryContact.setPrimaryContact(Trigger.new); 
            }
            //1/21/2021, After insert/update encrypt SSN
             if(DPM_PersonnelMasterServices.contexec==true){  
            	DPM_ContactTriggerHelper.doEncryptDecryptSSN(Trigger.New, trigger.isInsert, Trigger.OldMap);
             }
        }        
    }
    catch(exception e) {
        System.debug('** Error: ' + e.getMessage());
    }
    if(trigger.isBefore){
        for(Contact con: Trigger.new){            
            if(con.herokuExternalID__c == null || con.herokuExternalID__c  ==''){                
                String str = UUIDHandlerClass.getUUID();                
                System.debug('str: '+str);                
                con.herokuExternalID__c = str;                
            }            
        } 
    }
}