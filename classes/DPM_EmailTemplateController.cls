global class DPM_EmailTemplateController {
    /*
* Name      : DPM_EmailTemplateController
* Purpose   : Used to send DPM emails  
* Author    : Krishna Singh
* Date      : 29-Sept-2020
* 
* */
    public static Id idDPMEmployee {get; set;}
    public List<Account> acc;
    public string strLink {get;set;}
    
    private static final String strPSCorpAdmin = 'DPM_Corporate_Digital_Admin';
    private static final List<String> lstEmailTemplates = new List<String>{
        'DPM_Notify_to_Guest_Emp_after_4_days','DPM_Notif_Guest_Emp_RetAdm_after_8_days','DPM_Notify_RetAdm_Profile_Sub_Take_Act',
        'DPM_Rem_Notif_RetaAdm_to_take_Action','DPM_Notify_RetEmp_Profile_Creation','DPM_Duplicate_Not_Confirmed_Email','DPM_Duplicate_Confirmed_Email','DPM_Pending_Retailer_Admin_Action_Email'
        };
    
    public DPM_EmailTemplateController() {
    }    
    public List<Account> getAccountAddress() {
        if(idDPMEmployee!=NULL) {
            String sobjectType = idDPMEmployee.getSObjectType().getDescribe().getName();
            Id idAccount;
            if(sobjectType == 'contact') {
                idAccount = [SELECT Id,AccountId FROM Contact WHERE Id = :idDPMEmployee].AccountId;
            } else {
                idAccount = [SELECT Id,DPM_Account__c FROM DPM_Employee__c WHERE Id = :idDPMEmployee].DPM_Account__c;
            }
            acc = [SELECT Id,Name ,ShippingStreet,ShippingCity,ShippingState,ShippingCountry,ShippingPostalCode from account where id=:idAccount];
        }        
        return acc;
    }    
    public String getLink() {
        return DPM_PersonnelMasterServices.encryptRecordIdAndGenerateLink(idDPMEmployee);
    }    
    public class NotifyUsers {
        @InvocableVariable(required=true)
        public String strEmailType;
        @InvocableVariable(required=true)
        public Id idDPMEmployee;
    }
    @InvocableMethod(label='Send Notification Emails for DPM' description='Sending mails to DPM guest employee and Retailer Admins')
    public static void sendNotificationMails(NotifyUsers[] notifyRequests) {
        try{
            Map<String,Id> mapEmailTemplateNameToId = new Map<String,Id>();
            for(EmailTemplate emailTemplateToUse : [SELECT Id,DeveloperName FROM EmailTemplate WHERE DeveloperName IN :lstEmailTemplates]) {
                mapEmailTemplateNameToId.put(emailTemplateToUse.DeveloperName,emailTemplateToUse.Id);
            }
            Map<Id,String> mapDPMEmpIdToEmailType = new Map<Id,String>();
            Map<Id,List<String>> mapDPMEmpIdToListRecipients = new Map<Id,List<String>>();
            for(NotifyUsers emailRequest:notifyRequests){
                mapDPMEmpIdToEmailType.put(emailRequest.idDPMEmployee,emailRequest.strEmailType);
                mapDPMEmpIdToListRecipients.put(emailRequest.idDPMEmployee,new List<String>());
            }
            if(!mapDPMEmpIdToEmailType.isEmpty()) {
                Map<Id,String> mapDPMEmpIdToAccountId = new Map<Id,String>();
                Map<Id,DPM_Employee__c> mapDPMEmpIdToEmpRecord = new Map<Id,DPM_Employee__c>();
				Map<Id,RE_Person_Role__c> mapAccountIdToPersonRole=new Map<Id,RE_Person_Role__c>();
                Map<Id,List<String>> mapDPMAccIdToAdminEmails = new Map<Id,List<String>>();
                Set<String> setCorporateAdminEmails = new Set<String>();
                List<DPM_Employee__c> lstDPMEmployees = [SELECT Id, DPM_Account__c, CreatedDate, CreatedBy.Email, DPM_Email__c, DPM_Record_Origin__c,CreatedById,LastmodifiedBy.Email,DPM_Contact__r.Email,DPM_Contact__r.Name,CreatedBy.Name
				FROM DPM_Employee__c WHERE Id IN :mapDPMEmpIdToEmailType.keyset()];
                Set<Id> createdByIds=new Set<Id>();
				for(DPM_Employee__c dpmEmployee : lstDPMEmployees) {
                    mapDPMEmpIdToAccountId.put(dpmEmployee.Id,dpmEmployee.DPM_Account__c);
                    mapDPMEmpIdToEmpRecord.put(dpmEmployee.Id,dpmEmployee);
					createdByIds.add(dpmEmployee.CreatedById);
                }
				//prepare personrole map
                for(RE_Person_Role__c personroleObj:[SELECT Id,RE_Account__c,DPM_Work_Email__c,RE_Contact__r.Name,RE_Contact__r.Email,RE_Contact__c
                                                     FROM RE_Person_Role__c
                                                     WHERE RE_User__c IN:createdByIds
                                                     AND RE_Account__c IN:mapDPMEmpIdToAccountId.values()
                                                     AND RE_Psn_Active__c=true]){
                                                         if(personroleObj.RE_Account__c!=null){
                                                             mapAccountIdToPersonRole.put(personroleObj.RE_Account__c,personroleObj);
                                                         }
                                                     }
                Boolean blnFromPortal = false;
                Boolean blnFromCorporate = false;
                for(DPM_Employee__c dpmEmployee : mapDPMEmpIdToEmpRecord.values()) {
                    blnFromPortal = (dpmEmployee.DPM_Record_Origin__c == 'Portal');
                    blnFromCorporate = (dpmEmployee.DPM_Record_Origin__c == 'Corporate');
                }
                if(blnFromPortal) {
                    List<RE_Person_Role__c> lstPersonRole=[SELECT Id,DPM_Work_Email__c,RE_User__c,RE_User__r.Email,RE_Account__c FROM RE_Person_Role__c 
                                                           WHERE RE_Account__c IN :mapDPMEmpIdToAccountId.values() AND RE_IsAdmin__c=true 
                                                           AND RE_Persona__c !='President’s Office' AND RE_Psn_Active__c=true AND RE_Position_Active__c=true
                                                           AND RE_User__c!=NULL];
                    for(RE_Person_Role__c personRole : lstPersonRole) {
                        if(!mapDPMAccIdToAdminEmails.containsKey(personRole.RE_Account__c)) {
                            mapDPMAccIdToAdminEmails.put(personRole.RE_Account__c,new List<String>());
                        }
                        String strEmail = (personRole.DPM_Work_Email__c!=NULL?personRole.DPM_Work_Email__c:personRole.RE_User__r.Email);
                        mapDPMAccIdToAdminEmails.get(personRole.RE_Account__c).add(strEmail);
                    }
                }
                if(blnFromCorporate) {
                    List<PermissionSetAssignment> lstPSA = [SELECT Id, Assignee.Email FROM PermissionSetAssignment WHERE PermissionSet.Name=:strPSCorpAdmin];
                    for(PermissionSetAssignment PSA : lstPSA) {
                        setCorporateAdminEmails.add(PSA.Assignee.Email);
                    }
                }
                List<Messaging.SingleEmailMessage> lstMailsToSend = new List<Messaging.SingleEmailMessage>();
                OrgWideEmailAddress owea = new OrgWideEmailAddress();
                owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'sfdc@volvocars.com' LIMIT 1];
                for(NotifyUsers emailRequest:notifyRequests) {
                    Messaging.SingleEmailMessage mail;
                    Id idAccount = mapDPMEmpIdToAccountId.get(emailRequest.idDPMEmployee);
                    String strRecordOrigin = mapDPMEmpIdToEmpRecord.get(emailRequest.idDPMEmployee).DPM_Record_Origin__c;
                    Set<String> setRecipients = new Set<String>();
                    Set<String> setCCAddresses = new Set<String>();
                    List<String> lstRetailerAdminEmails = new List<String>();
                    if(idAccount != NULL) {
                        switch on emailRequest.strEmailType {
                            when '4days','8days','Submit','Duplicate Not Confirmed','Duplicate Confirmed','SubmitRem','Approve','Pending Retailer Admin Action' {
                                Id idTemplateToUse = (emailRequest.strEmailType == '4days'?mapEmailTemplateNameToId.get('DPM_Notify_to_Guest_Emp_after_4_days')
                                                      :emailRequest.strEmailType == '8days'?mapEmailTemplateNameToId.get('DPM_Notif_Guest_Emp_RetAdm_after_8_days')
                                                      :emailRequest.strEmailType == 'Submit'?mapEmailTemplateNameToId.get('DPM_Notify_RetAdm_Profile_Sub_Take_Act')
                                                      :emailRequest.strEmailType == 'Duplicate Not Confirmed'?mapEmailTemplateNameToId.get('DPM_Duplicate_Not_Confirmed_Email')
                                                      :emailRequest.strEmailType == 'Duplicate Confirmed'?mapEmailTemplateNameToId.get('DPM_Duplicate_Confirmed_Email')
                                                      :emailRequest.strEmailType == 'SubmitRem'?mapEmailTemplateNameToId.get('DPM_Rem_Notif_RetaAdm_to_take_Action')
													  :emailRequest.strEmailType == 'Pending Retailer Admin Action'?mapEmailTemplateNameToId.get('DPM_Pending_Retailer_Admin_Action_Email')
                                                      :mapEmailTemplateNameToId.get('DPM_Notify_RetEmp_Profile_Creation'));
                                if(idTemplateToUse!=NULL) {
                                    //Add the DPM Employee email
                                    if(emailRequest.strEmailType != 'Submit' && emailRequest.strEmailType != 'Duplicate Not Confirmed' && emailRequest.strEmailType != 'Duplicate Confirmed' && emailRequest.strEmailType != 'Pending Retailer Admin Action') {
                                    	setRecipients.add(mapDPMEmpIdToEmpRecord.get(emailRequest.idDPMEmployee).DPM_Email__c);
                                    }                                    
                                    // Removing CC from the Email template:6 , Task# 2171748
                                    if(emailRequest.strEmailType !='Approve'){
                                        if(strRecordOrigin == 'Portal') {
                                            lstRetailerAdminEmails = mapDPMAccIdToAdminEmails.get(idAccount);
                                            //Add all Retailer Admins
                                            setCCAddresses.addAll(lstRetailerAdminEmails);
                                        } else if(strRecordOrigin == 'Corporate') {
                                            //Add all Corporate Digital Admins
                                            setCCAddresses.addAll(setCorporateAdminEmails);
                                        }                                   
                                        //Add the Creator Email and remove from CC addresses
                                        setRecipients.add(mapDPMEmpIdToEmpRecord.get(emailRequest.idDPMEmployee).CreatedBy.Email);
                                        setCCAddresses.remove(mapDPMEmpIdToEmpRecord.get(emailRequest.idDPMEmployee).CreatedBy.Email); 
										
										//Add Retailer Admin Email   
                                        if(emailRequest.strEmailType =='Pending Retailer Admin Action'){                                                                               
                                           if(strRecordOrigin == 'Portal'){ 
                                                RE_Person_Role__c personRoleObj=mapAccountIdToPersonRole.get(idAccount);
                                                String strEmail=(personRoleObj.DPM_Work_Email__c!=NULL?personRoleObj.DPM_Work_Email__c:personRoleObj.RE_Contact__r.Email);
                                                setRecipients.add(strEmail);
                                            }else if(strRecordOrigin == 'Corporate') {
                                                String strEmail=mapDPMEmpIdToEmpRecord.get(emailRequest.idDPMEmployee).CreatedBy.Email;
                                                setRecipients.add(strEmail);
                                            }
                                        }
                                    }
                                    //All are added in a set to remove duplicates
                                    if(setRecipients != NULL && !setRecipients.isEmpty()) {
                                        mail = Messaging.renderStoredEmailTemplate(idTemplateToUse, null, emailRequest.idDPMEmployee);
                                        List<String> lstRecipients = new List<String>();
                                        lstRecipients.addAll(setRecipients);
                                        mail.setToAddresses(lstRecipients);
                                    }
                                    if(setCCAddresses != NULL && !setCCAddresses.isEmpty()) {
                                        List<String> lstCCRecipients = new List<String>();
                                        lstCCRecipients.addAll(setCCAddresses);
                                        mail.setCcAddresses(lstCCRecipients);
                                    }
                                    if(owea != null){
                                        mail.setOrgWideEmailAddressId(owea.Id);
                                    }
									if(emailRequest.strEmailType =='Pending Retailer Admin Action'){                                          
                                        String strEmailBody = mail.getHtmlBody();   
										if(strRecordOrigin == 'Portal') {
                                            strEmailBody = strEmailBody.replace('{Retailer_Admin}',mapAccountIdToPersonRole.get(idAccount).RE_Contact__r.Name);
                                        }else if(strRecordOrigin == 'Corporate') {
                                            strEmailBody = strEmailBody.replace('{Retailer_Admin}',mapDPMEmpIdToEmpRecord.get(emailRequest.idDPMEmployee).CreatedBy.Name);
                                        }
										mail.setHtmlBody(strEmailBody);
                                        mail.setBccAddresses(new String[]{mapDPMEmpIdToEmpRecord.get(emailRequest.idDPMEmployee).LastModifiedBy.Email});  
                                    }
                                }
                            }
                            when else {
                                System.debug('default');
                            }
                        }
                        if(mail != NULL) {
                            mail.setSaveAsActivity(false);
                            lstMailsToSend.add(mail);
                        }
                    }
                }
                if(!lstMailsToSend.isEmpty()) {
                    Messaging.sendEmail(lstMailsToSend); 
                }
            }
        } catch(Exception ex) {
            System.debug(ex);
        }
    }    
}