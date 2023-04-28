global class DPM_MetricsPresidentsOfficeLogins implements Database.Batchable<sObject>,Database.Stateful,schedulable {
    global Map<Id,Integer> userIdLoginMap=new Map<Id,Integer>();
    global Map<String,Set<Id>> countryUsersMap=new Map<String,Set<Id>>();
    global void execute(SchedulableContext sc){
        DPM_MetricsPresidentsOfficeLogins batch=new DPM_MetricsPresidentsOfficeLogins();        
        Id batchprocessid=Database.executeBatch(batch);         
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String retailer_recordtypeName='Retailer';        
            Set<String> countries=new Set<String>{'USA','CAN'};
                Set<Id> userIds=new Set<Id>();
        String personrole_query = 'select RE_User__r.isActive,RE_Account__r.country__r.Name,RE_Account__c,RE_Account__r.DPM_Global_Retailer_Code__c,RE_Account__r.Name,'+
            ' id,RE_User__c,RE_Employee_Position__c'+
            ' from RE_Person_Role__c'+
            ' WHERE RE_Position_Active__c=true'+
            ' AND RE_Persona__c=\'President’s Office\''+   
            ' AND RE_Psn_Active__c=true'+      
            ' AND RE_Pos_NonActive_Date__c=NULL'+
            ' AND RE_Psn_NonActive_Date__c=NULL'+            
            ' AND RE_Account__c!=NULL'+
            ' AND RE_User__c!=NULL'+
            ' AND RE_Account__r.country__r.Name IN:countries'+
            ' AND RE_Account__r.Org_non_activated__c=null'+
            ' AND RE_Account__r.RecordType.Name=:retailer_recordtypeName';
          //  ' AND RE_Account__r.DPM_Global_Retailer_Code__c!=NULL';       
        System.debug('personrole_query: '+personrole_query);
        List<RE_Person_Role__c> personRoles;
        try{
            personRoles=(List<RE_Person_Role__c>)Database.query(personrole_query);
        }catch(Exception ex){
            personRoles=new List<RE_Person_Role__c>();
            system.debug(ex);
        }
        Set<Id> dupIdfilter=new Set<Id>();
        for(RE_Person_Role__c personRole:personRoles){                           
            //collect all person role users to fetch login history of them            
            if(!countryUsersMap.containsKey(personRole.RE_Account__r.country__r.Name)){
                countryUsersMap.put(personRole.RE_Account__r.country__r.Name,new Set<Id>());                
            }
            if(personRole.RE_User__c!=null){
                userIds.add(personRole.RE_User__c);
                if(personRole.RE_User__r.isActive){
                    countryUsersMap.get(personRole.RE_Account__r.country__r.Name).add(personRole.RE_User__c);
                }
            }
    }
    system.debug('countryUsersMap:'+countryUsersMap);
    String loginhistory_soql='';       
        Date dateField=system.today();
        Integer previus_month=dateField.month()-1;
        Integer previus_month_year=dateField.year();
        if(previus_month==0){
            previus_month=12;
            previus_month_year--;
        }        
        Integer numberOfDays = Date.daysInMonth(previus_month_year, previus_month);
        system.debug('numberOfDays:'+numberOfDays);
        system.debug('userIds:'+userIds);
        loginhistory_soql='SELECT Id, UserId, SourceIp, LoginUrl, Browser, Status, Application, LoginTime, LoginType, Platform, ApiType'+ 
            ' FROM LoginHistory'+            
            ' WHERE userId IN:userIds'+
            ' AND userId!=NULL'+
            ' AND LoginTime!=NULL'+
            ' AND LoginTime=LAST_N_DAYS:'+numberOfDays+' order by userId,loginTime';
        System.debug('loginhistory_soql:'+loginhistory_soql);
        
        return Database.getQueryLocator(loginhistory_soql);
        
}
global void execute(Database.BatchableContext BC, List<LoginHistory> scope) {
    Map<String,LoginHistory> userUniqueLoginPerDayMap=new Map<String,LoginHistory>();       
    for(LoginHistory loginObj:scope){
        if(loginObj.userId!=null && loginObj.LoginTime!=null){ 
            //count monthly unique logins only                
            String loginhistory_key=loginObj.userId+'_'+loginObj.LoginTime.month()+'_'+loginObj.LoginTime.year();
            // process unique login history entries only
            if(!userUniqueLoginPerDayMap.containsKey(loginhistory_key)){
                userUniqueLoginPerDayMap.put(loginhistory_key,loginObj);   
                system.debug('loginhistory_key:'+loginhistory_key);
                String userId=loginObj.userId; 
                if(!userIdLoginMap.containsKey(userId)){
                    userIdLoginMap.put(userId,0);
                }
                Integer Logins=userIdLoginMap.get(userId)+1;
                userIdLoginMap.put(userId,Logins);
            }
        }
    }
}
global void finish(Database.BatchableContext BC) { 
    sendReportEmail();
}  
public void sendReportEmail(){
    //prepare csv file
    string header = 'Country,Total # of unique active president\'s office persona users ,Total # of unique logins by the active president\'s office users \n';
    String finalstr=header;
    String country_label='';
    for(String country:countryUsersMap.keyset()){        
        if(country.equals('USA')){
            country_label='US';
        }
        if(country.equals('CAN')){
            country_label='CA';
        }
        string recordString = country_label+','+countryUsersMap.get(country).size()+','+getLogins(country)+'\n';
        finalstr = finalstr +recordString;
    }
    OrgWideEmailAddress owea;
        try{
            owea=[SELECT Id FROM OrgWideEmailAddress WHERE Address = 'sfdc@volvocars.com' LIMIT 1];
        }catch(Exception ex){
            System.debug('sfdc email not set in OWD');
        }
        if(owea!=null){
            Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
            blob csvBlob = Blob.valueOf(finalstr);
            Date today=system.today();
            Integer MM=today.month();
            Integer DD=today.day();
            Integer YYYY=today.year();
            String finishday=String.valueOf(MM)+String.valueOf(DD)+String.valueOf(YYYY);
            string csvname= 'Presidents Office personnel portal usage metrics_'+finishday+'.csv';
            system.debug('csvname:'+csvname);
            csvAttc.setFileName(csvname);
            csvAttc.setBody(csvBlob);
            
            Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
            String[] toAddresses = new list<string>();
            String recipients=system.Label.DPM_MetricsPresidentsOfficeLogins_Recepients+',';        
            for(String recEmail:recipients.split(',')){
                toAddresses.add(recEmail);
            }
            String subject ='President\'s Office personnel portal usage metrics';
            email.setSubject(subject);
            email.setOrgWideEmailAddressId(owea.Id);
            email.setToAddresses( toAddresses );
            Date dateField=system.today();
        Integer previus_month=dateField.month()-1;
        Integer previus_month_year=dateField.year();
        if(previus_month==0){
            previus_month=12;
            previus_month_year--;
        }        
       // Integer numberOfDays = Date.daysInMonth(previus_month_year, previus_month);
           // Date fromdate=Date.newInstance(previus_month_year, previus_month, 1);
           // Date todate=Date.newInstance(previus_month_year, previus_month, numberOfDays);
            email.setPlainTextBody('Please find attached the US and CA retailer President\'s Office persona portal usage metrics for '+previus_month+'/'+previus_month_year+''+
                                   '\nSignature can be "Provided by your Digital DPM Team'+
                                   '\n\nThanks'+
                                   '\n\nVCUSA Digital DPM Team'+
                                   '\nVOLVO'
                                  );
            email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
            Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        }
}
global Integer getLogins(String country){
    Integer country_wise_logins=0;
    for(Id userId:countryUsersMap.get(country)){
        if(userIdLoginMap.containsKey(userId)){
            country_wise_logins+=userIdLoginMap.get(userId);
        }
    }
    return country_wise_logins;
}

}