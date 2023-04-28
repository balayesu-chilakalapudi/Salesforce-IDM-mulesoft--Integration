public class DPM_ScheduleSSNPurgeJobFlowHelper {
    public class NotifyUsers {
        @InvocableVariable(required=true)
        public String contactId;    
        @InvocableVariable(required=true)
        public String errorMessage;
    }
    @InvocableMethod
    public static void sendNotificationMails(NotifyUsers[] notifyRequests) {
        Set<String> contactIds=new Set<String>();
        String errorString='';
        Set<String> msgs=new Set<String>();
        for(NotifyUsers emailRequest:notifyRequests){
            contactIds.add(emailRequest.contactId);
            if(!msgs.contains(emailRequest.errorMessage)){
                errorString+=emailRequest.errorMessage;
            }
        }
        caseCreationSSNPurgeJobEmail(contactIds,errorString);
    }
    public static void caseCreationSSNPurgeJobEmail(Set<String> contactIds,String errorMessage){
        String baseUrl = URL.getOrgDomainUrl().toExternalForm()+'/';        
        String job_run_date=(system.today()).format();
        Map<Id,Contact> contactsMap=new Map<Id,Contact>([select Id,psnid__c,name from contact where Id IN:contactIds]);
        /*Contact conObj=[select Id,psnid__c,name from contact where Id=:contactId];*/
        String strdescription='The DPM SSN Purge job scheduled to run on '+job_run_date+' has been unsuccessful.  Please review the data related to the error and take the necessary steps to rectify the situation.';
        strdescription+='\n . Error message: '+errorMessage;
        for(Contact conObj:contactsMap.values()){
            strdescription+='\n . Employee VPID: '+conObj.psnid__c;
            strdescription+='\n . Employee name: '+conObj.Name+ ' '+baseUrl+conObj.Id+'\n';
        }
        Id recordTypeId = Schema.SObjectType.case.getRecordTypeInfosByName().get('Digital Personnel Management').getRecordTypeId();
        String groupId = [select Id, name from Group where  Type = 'Queue' AND DeveloperNAME = 'DPM_Corporate_Digital_Admins'].Id;
        List<Case> caselist=new List<Case>();  
        if(strdescription.length()<=32000){     
            Case caseObj = new Case();
            caseObj.Description = strdescription;
            caseObj.Subject = 'DPM SSN Purge Job Error';
            caseObj.RecordTypeId = recordTypeId;
            caseObj.ownerId = groupId;
            caseObj.origin = 'Email';
            caselist.add(caseObj); 
        }else{        
            Case caseObj = new Case();
            caseObj.Description = strdescription.substring(0,32000);
            caseObj.Subject = 'DPM SSN Purge Job Error';
            caseObj.RecordTypeId = recordTypeId;
            caseObj.ownerId = groupId;
            caseObj.origin = 'Email';
            caselist.add(caseObj);      
            Case caseObj2 = new Case();
            String content=strdescription.substring(32000,strdescription.length());    
            if(content.length()<=32000){
                caseObj2.Description = content;
            }else{
                caseObj2.Description = content.substring(0,32000);
            }
            caseObj2.Subject = 'DPM SSN Purge Job Error';
            caseObj2.RecordTypeId = recordTypeId;
            caseObj2.ownerId = groupId;
            caseObj2.origin = 'Email';
            caselist.add(caseObj2);     
        }
        if(!caselist.isEmpty()){
            insert caselist;
        }
        //Notify with an email
        OrgWideEmailAddress orgWideEmailAddress = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'sfdc@volvocars.com' Limit 1];
        
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        set<id> userid = new set<id>();
        list<GroupMember> m = [Select Id, UserOrGroupId,GroupId,Group.type From GroupMember Where GroupId =:groupId];
        for(GroupMember grpObj : [Select Id, UserOrGroupId,GroupId,Group.type From GroupMember Where GroupId =:groupId]){
            if(string.valueOf(grpObj.UserOrGroupId).StartsWith('005')){
                userid.add(grpObj.UserOrGroupId);
            }
        }
        list<string> userEmailList = new list<string>();
        for(user userObj : [select id, email from user where id in: userid]) {
            if(userObj.email != null){
                userEmailList.add(userObj.email);
            }
        }
        //Case caseobj2=[select id,CaseNumber from Case where Id=:caseObj.Id];
        String body = 'Hi Team ,</br>'+'The DPM SSN Purge job scheduled to run on '+ (system.today()).format() +' has been unsuccessful. ';
        for(Case caseObj:[SELECT Id,CaseNumber from case where Id IN:caselist]){
            body+='<br /><a href="'+baseUrl+caseObj.Id+'">Click here</a> to view the details of Case#'+caseObj.CaseNumber;
        }
        body+='  <br /><br />'+'Thank you!<br /><br />';
        body +='<img src='+Label.DMT_VolvoLogoURL+'></img>';
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(userEmailList);
        mail.setSubject('DPM SSN Purge Job Error');
        mail.setHtmlBody(body); 
        mail.setOrgWideEmailAddressId(orgWideEmailAddress.Id);
        mails.add(mail);        
        if(!mails.isEmpty()){
            Messaging.sendEmail(mails); 
        }
    }
}