public class DPM_CorporateUsersAccessController {
    public static void getUserAccessMap(){
        Organization orgObj=[SELECT Id, Name, IsSandbox FROM Organization LIMIT 1];        
        Map<String,Map<String,String>> userMainMap=new Map<String,Map<String,String>>();
        for(User userObj:[SELECT id,name,username,title,contactId,contact.name,contact.PsnId__c,
            (select id,PermissionSet.Name from PermissionSetAssignments where PermissionSet.Name like 'DPM%')
            FROM User
            WHERE isactive=true            
            ]){
                Map<String,String> usermap=new Map<String,String>();
                usermap.put('Employee Full Name',userObj.Name);
                usermap.put('User Name',userObj.UserName);
                usermap.put('Psn ID',userObj.contact.psnId__c);
                if(orgObj.IsSandbox){
                    usermap.put('Org_type','Sandbox');
                }else{
                    usermap.put('Org_type','Production');
                }
                usermap.put('Org_Idn',orgObj.Id);
                usermap.put('Title',userObj.Title);
                String psets='';
                for(PermissionSetAssignment pset:userObj.PermissionSetAssignments){
                    if(pset.PermissionSet.Name.startsWith('DPM')){
                        psets+=pset.PermissionSet.Name+'; ';
                    }
                }  
                psets=psets.removeEnd('; ');
                psets=psets.trim();
                usermap.put('DPM Permission Sets',psets);
                userMainMap.put(userObj.Id,usermap);
            }
            //fill groups and queues
            Map<String,Set<String>> groupMap=new Map<String,Set<String>>();
            Map<String,Set<String>> queueMap=new Map<String,Set<String>>();
            for(Group gp:[select name,type,DeveloperNAME,
            (select id,userorgroupId from groupmembers
            where userorgroupId IN:userMainMap.keyset()) 
            from group where developername like 'DPM%']){
                for(GroupMember member:gp.groupmembers){
                if(gp.type.equals('Queue')){
                    if(!queueMap.containsKey(member.userorgroupId)){
                        queueMap.put(member.userorgroupId,new Set<String>());
                    }
                    queueMap.get(member.userorgroupId).add(gp.DeveloperName);
                }else{
                    if(!groupMap.containsKey(member.userorgroupId)){
                        groupMap.put(member.userorgroupId,new Set<String>());
                    }
                    groupMap.get(member.userorgroupId).add(gp.DeveloperName);
                }
            }
            }
            //populate main map
            for(String userId:userMainMap.keyset()){
                String groups='';
                String queues='';
                if(groupMap.containsKey(userId)){
                    for(String g:groupMap.get(userId)){
                        groups+=g+'; ';
                    }
                }
                if(queueMap.containsKey(userId)){
                    for(String q:queueMap.get(userId)){
                        queues+=q+'; ';
                    }
                }
                groups=groups.removeEnd('; ');
                queues=queues.removeEnd('; ');
                groups=groups.trim();
                queues=queues.trim();
                userMainMap.get(userId).put('DPM Public Groups',groups);
                userMainMap.get(userId).put('DPM Queues',queues);
            }
            //prepare csv attachment
            String header='Employee Full Name,User Name,Psn ID,Org_type,Org_Idn,Title,DPM Permission Sets,DPM Public Groups,DPM Queues\n';
            String finalstr=header;
            for(String userId:userMainMap.keyset()){
                Map<String,String> usermap=userMainMap.get(userId);
                finalstr+=usermap.get('Employee Full Name')+','+
                usermap.get('User Name')+','+
                usermap.get('Psn ID')+','+
                usermap.get('Org_type')+','+
                usermap.get('Org_Idn')+','+
                usermap.get('Title')+','+
                usermap.get('DPM Permission Sets')+','+
                usermap.get('DPM Public Groups')+','+
                usermap.get('DPM Queues')+'\n';
            }
            //send email
            OrgWideEmailAddress owea;
        try{
            owea=[SELECT Id FROM OrgWideEmailAddress WHERE Address = 'sfdc@volvocars.com' LIMIT 1];
        }catch(Exception ex){
            System.debug('sfdc email not set in OWD');
        }
        if(owea!=null){
            Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
            blob csvBlob = Blob.valueOf(finalstr);
            string csvname= 'Corporate DPM user access.csv';
            csvAttc.setFileName(csvname);
            csvAttc.setBody(csvBlob);
        
            Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
            String[] toAddresses = new list<string>();
            String recipients='balayesu.chilakakapudi@volvocars.com,gaurav.saxena@volvocars.com';
            for(String recEmail:recipients.split(',')){
                toAddresses.add(recEmail);
            }
            String subject ='Corporate DPM user access';
            email.setSubject(subject);
            email.setOrgWideEmailAddressId(owea.Id);
            email.setToAddresses( toAddresses );
            email.setPlainTextBody('Please find attached the csv that shows the Corporate DPM user access of retailer users '+
            ' Signature can be "KPI provided by your Digital DPM Team"');
            email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
            Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});      
        }
    }
    @AuraEnabled
    public static List<CorporateUserAccessWrapper> getCorporateUserAccessReport(){
        List<CorporateUserAccessWrapper> corpObjList=new List<CorporateUserAccessWrapper>();
        try {
            Organization orgObj=[SELECT Id, Name, IsSandbox FROM Organization LIMIT 1];
            set<Id> userIds=new Set<Id>();
            for(User userObj:[SELECT id,name,title,contactId,contact.name,contact.PsnId__c,
            (select id,PermissionSet.Name from PermissionSetAssignments where PermissionSetId!=null)
            FROM User
            WHERE isactive=true
            and contactid!=null
            ]){
                CorporateUserAccessWrapper corpObj=new CorporateUserAccessWrapper();
                corpObj.Employee_Full_Name=userObj.contact.name;
                corpObj.User_Name=userObj.Name;
                corpObj.Psn_ID=userObj.contact.psnId__c;
                if(orgObj.IsSandbox){
                    corpObj.Org_type='Sandbox';
                }else{
                    corpObj.Org_type='Production';
                }
                corpObj.Org_Idn=orgObj.Id;
                corpObj.Title=userObj.Title;
                corpObj.DPM_Permission_Sets='';
                for(PermissionSetAssignment pset:userObj.PermissionSetAssignments){
                    corpObj.DPM_Permission_Sets+=pset.PermissionSet.Name;
                }                
                corpObjList.add(corpObj);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return corpObjList;
    }
    class CorporateUserAccessWrapper{
        @AuraEnabled 
        public String Employee_Full_Name;
        @AuraEnabled
        public String User_Name;
        @AuraEnabled
        public String Psn_ID;
        @AuraEnabled
        public String Org_type;
        @AuraEnabled
        public String Org_Idn;
        @AuraEnabled
        public String Title;
        @AuraEnabled
        public String DPM_Permission_Sets;
        @AuraEnabled
        public String DPM_Public_Groups;
        @AuraEnabled
        public String DPM_Queues;
    }
}