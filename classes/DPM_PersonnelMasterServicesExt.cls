public class DPM_PersonnelMasterServicesExt {
    /*
* Name      : DPM_PersonnelMasterServicesExt
* Purpose	: Extension class for DPM_PersonnelMasterServices.  
* Author	: Krishna Singh
* Date		: 04-Mar-2021
* 
* */
    public static final String strEmailMissingSSN = 'DPM_SSN_Not_Entered';
    public static final String strEmailMissingSSNCon = 'DPM_SSN_Not_Entered_Contact';
    public static final String strSystemError = 'System Error';
    public static final Id idOfDpmIntegrationErrorRecordType = Schema.SObjectType.DPM_Log__c.getRecordTypeInfosByName().get('Integration Log').getRecordTypeId();
    public static final Id idOfDpmSysErrorRecordType = Schema.SObjectType.DPM_Log__c.getRecordTypeInfosByName().get('System Error Log').getRecordTypeId();
    public static final Id idOfDpmCaseRecordType = Schema.SObjectType.case.getRecordTypeInfosByName()
        .get('Digital Personnel Management').getRecordTypeId();    
    
    public static void checkIncentiveEligibleRegistration(List<DPM_Job_Position__c> lstDPMPositions) {
        List<String> lstIncentiveEligiblePositions = getIncentiveEligiblePositions();
        for(DPM_Job_Position__c jobPosition:lstDPMPositions) {
            if(lstIncentiveEligiblePositions.contains(jobPosition.Name)) {
                sendEmail_MissingSSN(jobPosition.DPM_Employee_Registration__c,jobPosition.Name); 
                break;
            }
        }
    }
    public static void checkIncentiveEligibleProfile(List<DPM_EmployeeJobPosition__c> lstDPMPositions) {
        List<String> lstIncentiveEligiblePositions = getIncentiveEligiblePositions();
        for(DPM_EmployeeJobPosition__c jobPosition:lstDPMPositions) {
            if(lstIncentiveEligiblePositions.contains(jobPosition.DPM_Position_Title__c)) {
                sendEmail_MissingSSN(jobPosition.DPM_Person_Role__c,jobPosition.DPM_Position_Title__c); 
                break;
            }
        }
    }
    public static List<String> getIncentiveEligiblePositions() {
        List<String> lstPositions = new List<String>();
        for(RE_Job_to_Persona_map__mdt jobPersonaMap : [SELECT Id,MasterLabel,DPM_Incentive_Eligible__c FROM RE_Job_to_Persona_map__mdt WHERE DPM_Incentive_Eligible__c = TRUE]){
            lstPositions.add(jobPersonaMap.MasterLabel);
        }
        return lstPositions;
    } 
    public static void sendEmail_MissingSSN(Id idRecord,String strPosition) {
        String sobjectType = idRecord.getSObjectType().getDescribe().getName(); 
        String strCountry,strEmail;
        RE_Person_Role__c objPersonRole;
        EmailTemplate emailTemplate_MissingSSN;
        String storeName='';
        if(sobjectType == 'RE_Person_Role__c') {
            objPersonRole = [SELECT Id,RE_Contact__c,DPM_Work_Email__c,RE_Account__r.Name,RE_Account__r.ShippingStreet,RE_Account__r.ShippingCity,RE_Account__r.ShippingState,RE_Account__r.ShippingPostalCode,RE_Account__r.ShippingCountry,RE_Contact__r.MailingCountry,RE_Contact__r.Email FROM RE_Person_Role__c WHERE Id =:idRecord];
            strCountry = objPersonRole.RE_Contact__r.MailingCountry;
            if(strCountry != Null && String.isNotBlank(strCountry) && !String.valueOf(strCountry).equalsIgnoreCase('Mexico')){
                strEmail = (objPersonRole.DPM_Work_Email__c!=NULL?objPersonRole.DPM_Work_Email__c:objPersonRole.RE_Contact__r.Email);
                emailTemplate_MissingSSN = [SELECT Id, Body, DeveloperName, HTMLValue FROM EmailTemplate WHERE DeveloperName = :strEmailMissingSSNCon];
            }
            storeName=objPersonRole.RE_Account__r.Name;
        } else {
            DPM_Employee__c objDPMEmployee = [SELECT Id,DPM_Country__c,DPM_Email__c,DPM_Account__r.Name FROM DPM_Employee__c WHERE Id = :idRecord];
            strCountry = objDPMEmployee.DPM_Country__c;
            strEmail = objDPMEmployee.DPM_Email__c;
            emailTemplate_MissingSSN = [SELECT Id, Body, DeveloperName, HTMLValue FROM EmailTemplate WHERE DeveloperName = :strEmailMissingSSN];
            storeName=objDPMEmployee.DPM_Account__r.Name;
        }
        if(emailTemplate_MissingSSN != NULL) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail = Messaging.renderStoredEmailTemplate(emailTemplate_MissingSSN.Id, null, (sobjectType == 'RE_Person_Role__c'?objPersonRole.RE_Contact__c:idRecord));
            mail.setWhatId(idRecord);
            String strEmailBody = mail.getHtmlBody();   
            strEmailBody = strEmailBody.replace('{position}',strPosition);
            strEmailBody = strEmailBody.replace('{SSN}',(strCountry == 'United States'?'SSN':'SIN'));
            if(sobjectType == 'RE_Person_Role__c') {
                strEmailBody = strEmailBody.replace('{AccountName}',objPersonRole.RE_Account__r.Name).replace('{AccountName}',objPersonRole.RE_Account__r.Name);
                String strAddress = (objPersonRole.RE_Account__r.ShippingStreet!=NULL?objPersonRole.RE_Account__r.ShippingStreet+'<br/>':'')
                    +(objPersonRole.RE_Account__r.ShippingCity!=NULL?objPersonRole.RE_Account__r.ShippingCity+',&nbsp;':'')
                    +(objPersonRole.RE_Account__r.ShippingState!=NULL?objPersonRole.RE_Account__r.ShippingState+'&nbsp;':'')
                    +(objPersonRole.RE_Account__r.ShippingPostalCode!=NULL?objPersonRole.RE_Account__r.ShippingPostalCode+'&nbsp;'+'<br/>':'')
                    +(objPersonRole.RE_Account__r.ShippingCountry!=NULL?objPersonRole.RE_Account__r.ShippingCountry+'<br/>':'');
                strEmailBody = strEmailBody.replace('{AccountAddress}',strAddress);   
                mail.setWhatId(objPersonRole.RE_Contact__c);
            }            
            List<String> strSendTo = new List<String>();
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            strSendTo.add(strEmail);             
            mail.setToAddresses(strSendTo);
            mail.setSaveAsActivity(false);    
            mail.setHtmlBody(strEmailBody);
            mail.setSubject('Request to update your information in DPM for '+storeName);
            OrgWideEmailAddress owea = [SELECT Id, Address, DisplayName FROM 
                                        OrgWideEmailAddress WHERE DisplayName='no_reply_salesforce@volvocars.com'];
            mail.setOrgWideEmailAddressId(owea.Id);
            
            mails.add(mail);
            if(!mails.isEmpty()){
                Messaging.SendEmail(mails);
            }   
        }
    }
    //Duplicate Check for Retailer Employee when Admin Approves a request
    public static List<RE_Person_Role__c> retailerEmpDupCheck_Approval(String strDPMEmployee) {
        DPM_Employee__c dpmEmployee = (DPM_Employee__c) JSON.deserialize(strDPMEmployee, DPM_Employee__c.class);
        List<RE_Person_Role__c> lstRetailerEmployees = new List<RE_Person_Role__c>();
        lstRetailerEmployees = [SELECT Id,RE_Account__r.Name,DPM_Work_Email__c,RE_Psn_Active__c,RE_Contact__r.Email,RE_Contact__r.Lastname,RE_Contact__r.Firstname,RE_Contact__r.Suffix,RE_Contact__r.DPM_Preferred_First_Name__c,RE_Contact__r.DPM_SSN__c,RE_Contact__c
                                FROM RE_Person_Role__c
                                WHERE RE_Contact__r.RecordType.Name IN ('Retailer Employee','Supplier Employee')
                                AND (
                                    (RE_Psn_Active__c = TRUE AND (RE_Contact__r.Email=:dpmEmployee.DPM_Email__c OR DPM_Work_Email__c=:dpmEmployee.DPM_Email__c))
                                    OR (RE_Contact__r.DPM_SSN__c!=null AND RE_Contact__r.DPM_SSN__c=:dpmEmployee.DPM_SSN_SIN__c)
                                    OR (
                                        (RE_Contact__r.LastName=:dpmEmployee.DPM_Last_Name__c) 
                                        AND (RE_Contact__r.FirstName=:dpmEmployee.DPM_Legal_First_Name__c) 
                                        AND RE_Contact__r.Suffix=:dpmEmployee.DPM_Suffix__c
                                    ) 
                                    OR (
                                        (RE_Contact__r.LastName=:dpmEmployee.DPM_Last_Name__c)
                                        AND RE_Contact__r.DPM_Preferred_First_Name__c!= NULL 
                                        AND (RE_Contact__r.DPM_Preferred_First_Name__c=:dpmEmployee.DPM_Preferred_First_Name__c) 
                                        AND RE_Contact__r.Suffix=:dpmEmployee.DPM_Suffix__c
                                    )
                                )];        
        return lstRetailerEmployees;
    }
    
    public static string createDPMErrorNotification(string accountId,String strExceptionMsg){ 
        DPM_Log__c logObj = new DPM_Log__c();
        logObj.DPM_Error_Message__c = strExceptionMsg;
        logObj.DPM_Store__c = accountId; 
        logObj.RecordTypeId = idOfDpmSysErrorRecordType;
        logObj.DPM_type__c = strSystemError;
        //database.insert(logObj,false);
        try{
            insert logObj;
            system.debug('-=-==logObj-=-'+logObj);
            return JSON.serialize(logObj);
        }
        catch(exception e){
            return e.getMessage();
        }
    }
    @future
    public static void deactivatePortalBuysellUser(set<Id> lstUserIdsForDeactivation){
        list<id> setOfUserIds = new list<id>();
        setOfUserIds.addAll(lstUserIdsForDeactivation);
        deactivateUsers(setOfUserIds);  
    }
    public static void deactivateUsers(List<Id> lstUserIdsForDeactivation) {
        List<User> lstUsersForDeactivation = new List<User>();
        for(User u : [SELECT Id,UserName,FederationIdentifier,CommunityNickname,Alias FROM User WHERE Id IN :lstUserIdsForDeactivation]) {
            lstUsersForDeactivation.add(
                new User(
                    Id = u.Id,
                    FederationIdentifier = '',
                    Username = u.Username+Math.round(Math.random()*100),
                    CommunityNickname = u.CommunityNickname+Math.round(Math.random()*100),
                    Alias = (u.Alias.length()>5?u.Alias.substring(0,5):u.alias)+Math.round(Math.random()*100),
                    IsActive = false
                )
            );                    
        }
        if(!lstUsersForDeactivation.isEmpty()) {
            update lstUsersForDeactivation;
        }
    }    
    public static void caseCreationBuySell( string strSubject, string strdescription, string sellerStoreId, string buyingStoreId,map<id,Account> accountMap){
        system.debug('strdescription-=-='+strdescription);
        Id recordTypeId = idOfDpmCaseRecordType;
        //Schema.SObjectType.case.getRecordTypeInfosByName()
        //.get('Digital Personnel Management').getRecordTypeId();
        String groupId = [select Id, name from Group where  Type = 'Queue' AND DeveloperNAME = 'DPM_Corporate_Digital_Admins'].Id;
        Case caseObj = new Case();
        caseObj.Description = strdescription;
        caseObj.Subject = strSubject;
        caseObj.RecordTypeId = recordTypeId;
        caseObj.ownerId = groupId;
        caseObj.origin = 'Web';
        insert caseObj;
        if(caseObj != null && sellerStoreId != null && buyingStoreId == NULL){
            sendSuccessErrorBuySellMailTermination('Error',sellerStoreId,buyingStoreId,caseObj.id,accountMap,strSubject);
        }
        else if(caseObj != null && sellerStoreId != null && buyingStoreId != NULL){
            sendSuccessErrorBuySellMail('Error',sellerStoreId,buyingStoreId,caseObj.id,accountMap,strSubject,new list<RE_Person_Role__c>());
        }
    }
    public static void sendSuccessErrorBuySellMailTermination(String strStatus, string sellerStoreId, string buyingStoreId, string caseIdStr, map<Id,Account> accountMap,string strSubject){
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        String salesforceLinkDPM = Label.DPM_Instance;
        set<id> userid = new set<id>();
        String groupId = [select Id, name from Group where  Type = 'Queue' AND DeveloperNAME = 'DPM_Corporate_Digital_Admins'].Id;
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
        //string userEmail1=[select id, email from user where id =:m[0].UserOrGroupId].email;
        //system.debug(userEmail1);
        String body = '';
        if(strStatus == 'Success'){
            body = 'Hi Team ,</br>'+'All employees have been successfully terminated in  '+ accountMap.get(sellerStoreId).Name+' ('+accountMap.get(sellerStoreId).Retailer__c +')</br></br>Thanks</br></br>'; 
            body +='<img src='+Label.DMT_VolvoLogoURL+'></img>';
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(userEmailList);
            mail.setSubject('DPM Buy/Sell - selling store employee termination successful');
            mail.setHtmlBody(body);
            mails.add(mail);                
        } else {
            for(case caseObj : [select id,CaseNumber from case  where id =:caseIdStr]){
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(userEmailList);
                mail.setSubject('DPM Buy/Sell - Termination Contain Error'+strSubject.replace('Termination Request','#'));
                String strErrorbody = 'Hi Team ,</br>Termination unsuccessful, case has been created Case No.'+caseObj.CaseNumber+'</br> To view your case <a href='+salesforceLinkDPM+caseObj.Id+'>click here.</a> </br><br>Thanks</br><br>';
                strErrorbody +='<img src='+Label.DMT_VolvoLogoURL+'></img>';
                //body = body.replace('{statusMessage}','complete, but contains errors:'+strErrorbody);
                mail.setHtmlBody(strErrorbody);
                mails.add(mail);
            }
        }
        system.debug('mails-=-'+mails);
        if(!mails.isEmpty()){
            Messaging.sendEmail(mails); 
        }
    }
    public static void sendSuccessErrorBuySellMail(String strStatus, string sellerStoreId, string buyingStoreId, string caseIdStr, map<Id,Account> accountMap, string strSubject,list<RE_Person_Role__c> personRoleInserted){
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        String salesforceLinkDPM = Label.DPM_Instance;
        String vcpLink = Label.DPM_VCP_Link+'employee-profile';
        set<id> userid = new set<id>();
        String groupId = [select Id, name from Group where  Type = 'Queue' AND DeveloperNAME = 'DPM_Corporate_Digital_Admins'].Id;
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
        String body = 'Hi Team ,</br>'+'The Transfer of employees from '+ accountMap.get(sellerStoreId).Name +' to '+ accountMap.get(buyingStoreId).Name +' {statusMessage} </br></br>'+'Thanks</br></br>';
        body +='<img src='+Label.DMT_VolvoLogoURL+'></img>';
        if(strStatus == 'Success'){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(userEmailList);
            mail.setSubject('DPM Buy/Sell - Transfer result');
            mail.setHtmlBody(body.replace('{statusMessage}','has been successfully completed.'));
            mails.add(mail);
            if(!personRoleInserted.IsEmpty()){
                for(RE_Person_Role__c prObj : personRoleInserted){//[select id,DPM_Work_Email__c,RE_Contact__r.FirstName,RE_Contact__r.LastName from RE_Person_Role__c where id IN : personRoleInserted]){
                    Messaging.SingleEmailMessage mailPrWorkMail = new Messaging.SingleEmailMessage();
                    List<String> sendTo = new List<String>();
                    if(prObj.DPM_Work_Email__c != null){
                        if(prObj.DPM_Work_Email__c.endsWith('.invalid')){
                            sendTo.add(prObj.DPM_Work_Email__c.replace('.invalid',''));
                        }else{
                            sendTo.add(prObj.DPM_Work_Email__c);
                        }
                    }
                    if(!sendTo.IsEmpty()){
                    mailPrWorkMail.setToAddresses(sendTo);
                    mailPrWorkMail.setSubject('Your Personnel profile is created in '+accountMap.get(buyingStoreId).Name);
                    String bodyPr = 'Dear ' +prObj.RE_Contact__r.FirstName+' '+prObj.RE_Contact__r.LastName+ ',</br></br>';
                    bodyPr += 'You are now created in our Personnel Management system in ' +accountMap.get(buyingStoreId).Name+'. You may review your</br>';
                    bodyPr += 'profile at any time, to make sure your new work email and phone number are updated.</br></br>';
                    bodyPr += '<a href='+vcpLink+'>click here</a> </br></br>';
                    bodyPr += 'Thank you. </br>';
                    bodyPr += accountMap.get(buyingStoreId).Name+'</br>';
                    bodyPr += accountMap.get(buyingStoreId).ShippingStreet+'</br>';
                    bodyPr += accountMap.get(buyingStoreId).ShippingState+' '+accountMap.get(buyingStoreId).ShippingPostalCode+'</br>';
                    bodyPr += accountMap.get(buyingStoreId).ShippingCountry+'</br></br>'; 
                    bodyPr +='<img src='+Label.DMT_VolvoLogoURL+'></img>';
                    mailPrWorkMail.setHtmlBody(bodyPr);
                    mails.add(mailPrWorkMail); 
                    }
                }
            }
                           
        } else {
            for(case caseObj : [select id,CaseNumber from case  where id =:caseIdStr]){
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(userEmailList);
                mail.setSubject('DPM Buy/Sell - Transfer Contain Error'+strSubject.replace('Transfer Request','#'));
                String strErrorbody = '<br>Case No.'+caseObj.CaseNumber+' <br>To view your case <a href='+salesforceLinkDPM+caseObj.Id+'>click here.</a> </br>';
                body = body.replace('{statusMessage}',' is complete, but contains errors:'+strErrorbody);
                mail.setHtmlBody(body);
                mails.add(mail);
            }
        }
        if(!mails.isEmpty()){
            Messaging.sendEmail(mails); 
        }
    }
    public static DPM_Employee__c getStatusVal(string strRecordId){             
        
        DPM_Employee__c employeeObj = [SELECT Id, CreatedById, LastModifiedById, DPM_Account__r.Name, DPM_Account__r.Org_activated__c,DPM_Account__r.Retailer__c, DPM_Email__c, DPM_Legal_First_Name__c, DPM_Status__c,
                                       DPM_Gender__c,DPM_Other_Gender__c, DPM_Prefix__c, DPM_Middle_Name__c, DPM_Last_Name__c, DPM_Suffix__c, DPM_Preferred_First_Name__c,DPM_Personal_Email__c,
                                       DPM_Hire_Date__c,DPM_Owner__c,DPM_SSN_SIN__c,DPM_Owner_Title__c,DPM_Canadian_State__c,DPM_Cell_Phone__c,DPM_City__c,DPM_Country__c,DPM_Home_Address_Street__c,
                                       DPM_Home_Phone__c,DPM_US_State__c,DPM_Contact__c,DPM_Zipcode__c,DPM_Home_Address_Street_2__c,DPM_Submitted_DateTime__c,DPM_Retailer_Admin__c,DPM_Request_Type__c, 
                                       (SELECT Id, DPM_End_Date__c, DPM_Primary__c, Name, DPM_Start_Date__c FROM DPM_Job_Positions__r)FROM DPM_Employee__c where id=:strRecordId];  
        
        return employeeObj;
    }  
    
    public static void createTier2Case(DPM_Employee__c dpmEmployee){  
        List<Contact> matchingContacts = new List<Contact>();       
        matchingContacts=[SELECT Id,DPM_SSN__c,PsnId__c,Lastname,FirstName,Suffix,DPM_Preferred_First_Name__c
                          FROM Contact
                          WHERE RecordType.Name IN ('Retailer Employee','Supplier Employee')
                          AND (
                              (
                                  (LastName=:dpmEmployee.DPM_Last_Name__c) 
                                  AND (FirstName=:dpmEmployee.DPM_Legal_First_Name__c) 
                                  AND (Suffix=:dpmEmployee.DPM_Suffix__c)
                              ) 
                              OR (
                                  (LastName=:dpmEmployee.DPM_Last_Name__c) 
                                  AND DPM_Preferred_First_Name__c!= NULL 
                                  AND (DPM_Preferred_First_Name__c=:dpmEmployee.DPM_Preferred_First_Name__c) 
                                  AND Suffix=:dpmEmployee.DPM_Suffix__c
                              )
                          ) ORDER BY PsnId__c ASC];
        
        if(matchingContacts!=null &&
           !matchingContacts.isEmpty()) {
               //Fetching the assignment rules on case
               AssignmentRule AR = new AssignmentRule();
               AR = [select id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];
               
               //Creating the DMLOptions for "Assign using active assignment rules" checkbox
               Database.DMLOptions dmlOpts = new Database.DMLOptions();
               dmlOpts.assignmentRuleHeader.assignmentRuleId= AR.id;
               dmlOpts.EmailHeader.TriggerUserEmail = true;
               //create a case
               Id recordTypeId = idOfDpmCaseRecordType;
               
               Case caseObj=new Case(
                   RecordTypeId=recordTypeId,
                   origin = 'Web',
                   subject='Possible Duplicate Request for '+dpmEmployee.DPM_Legal_First_Name__c+' '+dpmEmployee.DPM_Last_Name__c,
                   Description='Please review the data and as per your determination, either contact the retailer admin to delete the request and re-create the employee as an extension/reactivation in DPM OR proceed with the employee creation approval.\n'            
               );
               
               String baseUrl = URL.getOrgDomainUrl().toExternalForm()+'/';
               caseObj.Description+='Self-registration form details: '+baseUrl+dpmEmployee.Id+'\n';
               caseObj.Description+='Listed below are the details of all possible matches within SAFE schools or other retailers:\n';
               Integer counter=1;
               for(Contact exactMatch:matchingContacts){
                   caseObj.Description+='Contact #:'+counter+' '+baseUrl+exactMatch.Id+'\n';
                   counter++;
               }       
               caseObj.setOptions(dmlOpts);
               insert caseObj; 
           }
    } 
    
    public static Map<Id,String> getASMMIdMap(Set<Id> setAccIds){
        Map<Id,String> mapAccountIdToMarket = new Map<Id,String>();
        Map<String,Id> mapMarketToAMM = new Map<String,Id>();
        Map<Id,String> accountIdASMMIdMap = new Map<Id,String>();
        for(Account a : [SELECT Id,Market__r.Market__c FROM Account WHERE Id IN :setAccIds]){
            mapAccountIdToMarket.put(a.Id,a.Market__r.Market__c);           
        }
        //prepare asmmId map
        for(UserTerritory2Association userTerrAssociation : [SELECT Id,UserId,Territory2Id,Territory2.Name
                                                             from UserTerritory2Association
                                                             WHERE RoleInTerritory2 = 'AfterSales Market Manager'
                                                             AND Territory2.Name IN :mapAccountIdToMarket.values()]) {
                                                                 mapMarketToAMM.put(userTerrAssociation.Territory2.Name,userTerrAssociation.UserId);
                                                             }
        for(Id accountId : setAccIds){
            String asmmId=mapMarketToAMM.get(mapAccountIdToMarket.get(accountId));
            if(asmmId!=null){
                accountIdASMMIdMap.put(accountId,asmmId);
            }
        }
        return accountIdASMMIdMap;
    }
    public static void setRegistrationStatus(String strRecordId){
        try{
            //get registration record
            DPM_Employee__c DPMEmployeeObj=[SELECT Id,createdbyId,lastmodifiedby.Email,DPM_Account__c,DPM_Status__c
                                            FROM DPM_Employee__c
                                            WHERE Id=:strRecordId];
            
            //set registration record status
            DPMEmployeeObj.DPM_Status__c='Pending Retailer Admin Action';
            update DPMEmployeeObj;
        }catch(Exception ex){
            System.debug(ex+'\n'+ex.getStackTraceString());
        }
    } 
    public static List<Account> getValidDealershipsForDPM() {
        List<String> lstRetailerCodes = new List<String>();
        List<String> lstPermSets = new List<String>();
        List<Account> lstDealershipsWithoutActiveRetailers = new List<Account>();
        DPM_Configuration__mdt dpmConfig = DPM_PersonnelMasterServices.getDPMConfigCustomMetadata(); 
        String strAllCodes=dpmConfig.DPM_Retailer_Codes_for_Access__c+';'+dpmConfig.DPM_Additional_Accounts_for_Search__c;
        Set<String> recordTypes=new Set<String>{'Retailer','Partner'};
        lstRetailerCodes = strAllCodes.split(';'); 
        for(PermissionSetAssignment psa : [SELECT Id,PermissionSetId,PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSet.Name =:'DPM_Corp_Incentive']) {
            lstPermSets.add(psa.PermissionSet.Name);
        }
        if(!lstPermSets.isEmpty()) {  
            if(lstPermSets.contains('DPM_Corp_Incentive')) {
                if(!lstRetailerCodes.isEmpty()) {
                    return [SELECT Id,Name,Retailer__c,Org_activated__c,country__c 
                            FROM Account WHERE Org_non_activated__c = NULL AND Org_activated__c <> NULL AND RecordType.Name IN:recordTypes AND Retailer__c IN :lstRetailerCodes
                            AND country__r.name =: 'USA' AND RecordType.Name <> 'Partner' ORDER BY Name];
                }
                return [SELECT Id,Name,Retailer__c,Org_activated__c,country__c  
                        FROM Account WHERE Org_non_activated__c = NULL AND Org_activated__c <> NULL AND RecordType.Name IN:recordTypes
                        AND country__r.name =: 'USA' AND RecordType.Name <> 'Partner' ORDER BY Name];
            }
        }
        if(!lstRetailerCodes.isEmpty()) {
            return [SELECT Id,Name,Retailer__c,Org_activated__c 
                    FROM Account WHERE Org_non_activated__c = NULL AND Org_activated__c <> NULL AND RecordType.Name IN:recordTypes AND Retailer__c IN :lstRetailerCodes
                    ORDER BY Name];
        }
        return [SELECT Id,Name,Retailer__c,Org_activated__c  
                FROM Account WHERE Org_non_activated__c = NULL AND Org_activated__c <> NULL AND RecordType.Name IN:recordTypes
                ORDER BY Name];
    }
    public static Map<String,List<String>> getCorpCountryStatesMap() {
        Map<String,List<String>> mapCountryToStates = new Map<String,List<String>>();
        DPM_Configuration__mdt dpmConfig = DPM_PersonnelMasterServices.getDPMConfigCustomMetadata();
        List<String> lstPermSets = new List<String>();
        for(PermissionSetAssignment psa : [SELECT Id,PermissionSetId,PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSet.Name IN ('DPM_Corp_Incentive')]) {
            lstPermSets.add(psa.PermissionSet.Name);
        }        
        if(!lstPermSets.isEmpty() &&
           lstPermSets.contains('DPM_Corp_Incentive')
          ){
              mapCountryToStates.put('United States',DPM_PersonnelMasterServices.getPicklistValuesFromObject('DPM_US_State__c','DPM_Employee__c',false));     
          }else{              
              mapCountryToStates.put('United States',DPM_PersonnelMasterServices.getPicklistValuesFromObject('DPM_US_State__c','DPM_Employee__c',false));
              mapCountryToStates.put('Canada',DPM_PersonnelMasterServices.getPicklistValuesFromObject('DPM_Canadian_State__c','DPM_Employee__c',false));
              mapCountryToStates.put('Mexico',DPM_PersonnelMasterServices.getPicklistValuesFromObject('DPM_Mexican_State__c','DPM_Employee__c',false));
          }
        return mapCountryToStates;
    }
    public static DPM_PersonnelMasterServices.DPM_SearchResults searchEmployeeCreationStatusAction(String strSessionSettings, String strSearchFields){
        DPM_PersonnelMasterServices.DPM_SearchResults dpmSearchResults = new DPM_PersonnelMasterServices.DPM_SearchResults();
        DPM_PersonnelMasterServices.DPM_SessionSettings objsessionSettings = (DPM_PersonnelMasterServices.DPM_SessionSettings) JSON.deserialize(strSessionSettings, DPM_PersonnelMasterServices.DPM_SessionSettings.class);
        DPM_PersonnelMasterServices.DPM_SearchEmployee objsearchFields = (DPM_PersonnelMasterServices.DPM_SearchEmployee) JSON.deserialize(strSearchFields, DPM_PersonnelMasterServices.DPM_SearchEmployee.class);
        system.debug('objsearchFields-=-'+objsearchFields);
        system.debug('objsessionSettings-=-'+objsessionSettings);
        system.debug('objsessionSettings.sortBy-----'+objsessionSettings.sortBy);
        try{
            String completedStatus='Completed';
        //Set<String> statusSet=new Set<String>{'Initiated','Submitted','Approved','Pending Corporate Approval','Pending Retailer Admin Action'};
        String strQuery = 'SELECT id,DPM_Account__c,DPM_Account__r.DPM_Global_Retailer_Code__c,'+
        'DPM_Contact__r.MailingCity,DPM_Proficiency_1__c, DPM_Proficiency_2__c, DPM_Proficiency_3__c, DPM_Language_1__c, DPM_Language_2__c, DPM_Language_3__c,'+
                          'CreatedById, DPM_Account__r.Name,DPM_Account__r.Org_activated__c, DPM_Account__r.Retailer__c, DPM_Email__c, DPM_Legal_First_Name__c, DPM_Status__c,'+
                          'DPM_Gender__c,DPM_Other_Gender__c, DPM_SSN_SIN__c, DPM_Prefix__c, DPM_Middle_Name__c, DPM_Last_Name__c, DPM_Suffix__c, DPM_Preferred_First_Name__c,'+
                          'DPM_Hire_Date__c, DPM_Race__c, DPM_Ethnicity__c, DPM_Owner__c,DPM_Contact__c,DPM_Contact__r.DPM_SSN__c,DPM_Owner_Title__c,DPM_Canadian_State__c,DPM_Mexican_State__c,DPM_Cell_Phone__c,DPM_City__c,DPM_Country__c,DPM_Home_Address_Street__c,'+
                          'DPM_Home_Phone__c,DPM_US_State__c,DPM_Zipcode__c,DPM_Home_Address_Street_2__c,DPM_Retailer_Admin__c,DPM_Request_Type__c,DPM_Personal_Email__c,DPM_Employee_Type__c,DPM_US_Military__c,'+                          
        '(SELECT Id, DPM_End_Date__c, DPM_Primary__c, Name, DPM_Start_Date__c FROM DPM_Job_Positions__r)'+
        ' FROM DPM_Employee__c';
        strQuery+=' WHERE DPM_Status__c!=:completedStatus';// IN:statusSet';
        List<String> whereClauseList=new List<String>();
        if(!String.isEmpty(objsearchFields.firstName)) {
            whereClauseList.add('DPM_Legal_First_Name__c=\''+String.escapeSingleQuotes(objsearchFields.firstName)+'\'');
        }
        if(!String.isEmpty(objsearchFields.lastName)) {
            whereClauseList.add('DPM_Last_Name__c=\''+String.escapeSingleQuotes(objsearchFields.lastName)+'\'');
        }
        if(!String.isEmpty(objsearchFields.email)) {
            whereClauseList.add('DPM_Email__c=\''+String.escapeSingleQuotes(objsearchFields.email)+'\'');
        }
        if(!String.isEmpty(objsearchFields.store_SFId)) {
            whereClauseList.add('DPM_Account__c=\''+String.escapeSingleQuotes(objsearchFields.store_SFId)+'\'');
            dpmSearchResults.RetailerId=[SELECT Retailer__c FROM ACCOUNT 
            WHERE Id=:objsearchFields.store_SFId].Retailer__c;
        }
        if(!whereClauseList.isEmpty()){          
            for(integer x=0;x<whereClauseList.size();x++){
                strQuery+=' AND '+whereClauseList[x];
            }
        }
        strQuery+=' ORDER BY Lastmodifieddate asc';
        dpmSearchResults.intTotalDPMEmployeeResults=((List<DPM_Employee__c>)Database.query(strQuery)).size();
        if(!objsessionSettings.skipOffset && 
               objsessionSettings.showViewMoreDPMEmployees) {
                strQuery+= ' Limit '+objsessionSettings.intLimit+' OFFSET '+objsessionSettings.intOffset;
               }
               
        system.debug('strQuery:'+strQuery);
        
            dpmSearchResults.lstDPMEmployees=(List<DPM_Employee__c>)Database.query(strQuery);           
            
        }catch(Exception ex){
            system.debug('Query Exception:'+ex+'\n'+ex.getStackTraceString());
        }
        return dpmSearchResults;
    }
}