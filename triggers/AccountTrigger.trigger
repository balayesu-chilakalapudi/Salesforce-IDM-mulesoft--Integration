/**
* --------------------------------------------------------------------------------
* @Name         AccountTrigger.grigger
* @Author       Sivasankar
* @CreatedDate  07-March-2019
* @LastModifiedDate  13-January-2021, LastModifiedBy Vikrant 
* --------------------------------------------------------------------------------
* @Description
*   Trigger for any Account business logic
* --------------------------------------------------------------------------------
* @Changes
* CH00# DT-1404961 # 07-March-2019 # Siva # Design Task to disable Partner or Retailer Users based upon Retailer's Org. Non Activation Date. 
* CH00# 10-September-2020 # Vikrant# Added logic for the External ID creation.  
* CH00# 13-January-2021 # Vikrant# Added Consent Management Logic. 

* --------------------------------------------------------------------------------
**/

trigger AccountTrigger on Account (after update,after insert, before insert, before update) {
    //GenericTriggerDispatcher.Run('AccountTriggerHandler');
    System.debug('SOQL Count:Account:Before Handler: ' + Limits.getQueries());
    TriggerDispatcher.Run('Account');
    System.debug('SOQL Count:Account:After Handler: ' + Limits.getQueries());
    /*if(trigger.isAfter && trigger.isUpdate){
        TM_AccountTriggerHelper.prepareRetailerPartnerstoDeactivate(trigger.new, trigger.oldMap);
        RE_AccountTriggerHelper.reassignRetailersToPublicGroups(trigger.new, trigger.oldMap);
        RE_AccountTriggerHelper.reassignAccountToMarketTerritory(trigger.new, trigger.oldMap);
        System.debug('-----first time---');
        //Handle Consent Management when email/phone/address is changed for a person account with personIndividualId                 
        Volvo_ProcessConsentManagement.handlePersonAccountConsentMgmt(trigger.oldMap, trigger.new); 
        if(Volvo_ConsumerRulesHelper.isfirsttime){
            Volvo_ConsumerRulesHelper.isfirsttime = false;
            Volvo_ConsumerRulesHelper.handlepaccountupdation( trigger.new,trigger.oldMap); 
            
        }
        
        
        
    } else if(trigger.isAfter && trigger.isInsert){
        RE_AccountTriggerHelper.reassignAccountToMarketTerritory(trigger.new, NULL);
        //Handle Consent Management when email/phone/address is changed for a person account with personIndividualId          
        Volvo_ProcessConsentManagement.handlePersonAccountConsentMgmt(null, trigger.new);  
        Volvo_ConsumerHistory.createconhisrec(null, trigger.new); 
    }
    if(trigger.isBefore){
        for(Account acc: Trigger.new){             
            if(acc.herokuExternalID__c == null || acc.herokuExternalID__c =='')           
                acc.herokuExternalID__c = UUIDHandlerClass.getUUID();               
            
            
            if(trigger.isInsert){
                //Handle Consent Management when email/phone/address is changed for person account without IndividualId
                Volvo_ProcessConsentManagement.assignPersonIndividualId(null, trigger.new);
                Volvo_ConsumerHistory.createconhisrec(null, trigger.new); 
            }  
            if(trigger.isUpdate){
                //Handle Consent Management when email/phone/address is changed for a person account without personIndividualId
                Volvo_ProcessConsentManagement.assignPersonIndividualId(trigger.oldMap, trigger.new);   
                Volvo_ConsumerHistory.createconhisrec(trigger.oldMap, trigger.new);
                
            }
            
        }
    }
    // if (trigger.isAfter && trigger.isUpdate) {
    //            System.debug('-----second time---');
    //	  Volvo_ProcessConsentManagement.handlePersonAccountConsentMgmt(trigger.oldMap,trigger.new );
    // }
    if (trigger.isAfter && trigger.isUpdate) {
        Volvo_ProcessConsentManagement.AccConsumer(trigger.oldMap, trigger.new);
    }*/
}