public with sharing class DPM_EarlyHireDateEmployeeNotifyFlow { 
    @InvocableMethod
    public static void getAccountIds(List<String> accountIds) {
        string strVolvoCorporateAccountName = 'Volvo Car USA LLC';
        List<String> lstNamesToIgnore = new List<String>{'Blueprism'};
    
        List<RE_Person_Role__c> earlyHiredEmployeelist=new List<RE_Person_Role__c>();
        //query accounts
        for(Account accountObj:[select Id,Name,org_activated__c,
        (select id,Name,DPM_HireDate_EarlierThan_Org_Actiivation__c,DPM_Country__c,DPM_Retailer_ID__c,DPM_Retailer_DBA_Name__c,RE_Account__r.org_activated__c,
        DPM_Contact_Name__c,RE_Psn_Active_Date__c,RE_Psn_NonActive_Date__c,DPM_Contact_RecordType_Name__c,
        RE_Account__r.Owner.Name,DPM_Contact_PSN_ID__c
         from Person_Roles__r
         where DPM_HireDate_EarlierThan_Org_Actiivation__c=true
         AND RE_Contact__c!=null
         AND RE_Contact__r.FirstName NOT IN :lstNamesToIgnore 
         AND RE_Contact__r.Account.Name!=:strVolvoCorporateAccountName
         order by DPM_Contact_Name__c)
         From Account
        where Id IN:accountIds
        AND Name!=:strVolvoCorporateAccountName]){
                //filter early hired employees
                for(RE_Person_Role__c personRoleObj:accountobj.Person_Roles__r){
                    if(personRoleObj.RE_Psn_Active_Date__c!=null &&
                        accountObj.org_activated__c > personRoleObj.RE_Psn_Active_Date__c &&
                        personRoleObj.RE_Psn_NonActive_Date__c==null &&
                        personRoleObj.DPM_Contact_RecordType_Name__c!=null &&
                        personRoleObj.DPM_Contact_RecordType_Name__c.equals('Retailer Employee')
                    ){
                        earlyHiredEmployeelist.add(personRoleObj);
                    }
                }
        }
        //Send Email Alert to Queue
        try{
            if(!earlyHiredEmployeelist.isEmpty()){
                caseCreationSSNPurgeJobEmail(earlyHiredEmployeelist);
            }
        }catch(Exception ex){
            system.debug('Exception:'+ex+'\n'+ex.getStackTraceString());
        }
    }
    public static void caseCreationSSNPurgeJobEmail(List<RE_Person_Role__c> personRoles){
        String baseUrl = URL.getOrgDomainUrl().toExternalForm()+'/'; 
        Map<Id,RE_Person_Role__c> personRolesMap=new Map<Id,RE_Person_Role__c>(personRoles);
        String strdescription='The Notification of empls with early hire date.  Please review the data related to the impacted employees and take the necessary steps to rectify the situation.'; 
        	strdescription+='\n . Country: '+personRoles[0].DPM_Country__c;
            strdescription+='\n . Retailer Id: '+personRoles[0].DPM_Retailer_ID__c;
            strdescription+='\n . Account Name: '+personRoles[0].DPM_Retailer_DBA_Name__c;
            strdescription+='\n . Retailer Organization Activation Date: '+Date.valueOf(personRoles[0].RE_Account__r.org_activated__c).format();
        for(RE_Person_Role__c personRoleObj:personRolesMap.values()){
            strdescription+='\n . Contact full name: '+personRoleObj.DPM_Contact_Name__c;
            strdescription+='\n . Account Owner: '+personRoleObj.RE_Account__r.Owner.Name;
            strdescription+='\n . Person Role Name: '+personRoleObj.Name+ ' '+baseUrl+personRoleObj.Id+'\n';
            strdescription+='\n . Psn Id: '+personRoleObj.DPM_Contact_PSN_ID__c;
            strdescription+='\n . Psn Active Date: '+personRoleObj.RE_Psn_Active_Date__c;           
        }
        Id recordTypeId = Schema.SObjectType.case.getRecordTypeInfosByName().get('Digital Personnel Management').getRecordTypeId();
        String groupId = [select Id, name from Group where  Type = 'Queue' AND DeveloperNAME = 'DPM_Corporate_Digital_Admins'].Id;
        List<Case> caselist=new List<Case>(); 
        //Fetching the assignment rules on case
            AssignmentRule AR = new AssignmentRule();
            AR = [select id from AssignmentRule where SobjectType = 'Case' and name = 'CCPA & Appointment Case Assignment' ];
            //Creating the DMLOptions for "Assign using active assignment rules" checkbox
            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            dmlOpts.assignmentRuleHeader.assignmentRuleId= AR.id;
        	dmlOpts.EmailHeader.triggerAutoResponseEmail = true;
			dmlOpts.EmailHeader.triggerUserEmail = true;
        if(strdescription.length()<=32000){     
            Case caseObj = new Case();
            caseObj.Description = strdescription;
            caseObj.Subject = 'The Notification of empls with early hire date';
            caseObj.RecordTypeId = recordTypeId;
            caseObj.origin = 'Email';
            //Setting the DMLOption on Case instance
            caseObj.setOptions(dmlOpts);
            caselist.add(caseObj); 
        }else{        
            Case caseObj = new Case();
            caseObj.Description = strdescription.substring(0,32000);
            caseObj.Subject = 'The Notification of empls with early hire date';
            caseObj.RecordTypeId = recordTypeId;
            caseObj.origin = 'Email';
            //Setting the DMLOption on Case instance
            caseObj.setOptions(dmlOpts);
            caselist.add(caseObj);      
            Case caseObj2 = new Case();
            String content=strdescription.substring(32000,strdescription.length());    
            if(content.length()<=32000){
                caseObj2.Description = content;
            }else{
                caseObj2.Description = content.substring(0,32000);
            }
            caseObj2.Subject = 'The Notification of empls with early hire date';
            caseObj2.RecordTypeId = recordTypeId;
            caseObj2.origin = 'Email';
            //Setting the DMLOption on Case instance
            caseObj2.setOptions(dmlOpts);
            caselist.add(caseObj2);     
        }
        if(!caselist.isEmpty()){
            Database.insert(caselist, dmlOpts);
        }
        
    }
}