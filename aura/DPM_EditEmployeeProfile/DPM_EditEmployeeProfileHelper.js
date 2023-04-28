({
    closeModal : function(component) {
        component.destroy();
    },
        validateRecord : function(component, event, helper) {
        //console.log(JSON.stringify(component.get('v.personRole')));
        let blnAllow = true;
        try{
        let varPersonRole = component.get('v.personRole');
        let cmpEmployeeForm = component.find('idEmployeeForm');
        let ssnComponent = cmpEmployeeForm.find('idSSNcmpEdit');
        if(!$A.util.isEmpty(cmpEmployeeForm)) {
            //Required Validations
            let requiredInputs = [];
            if(component.get('v.mode') == 'edit') {
                requiredInputs = ["idPrefix","idFirstName","idLastName","idGender","idMainEmail","idHomeAddress","idOtherPhone1","idOtherPhone2","idPersonalPhone","idWorkPhone","idWorkEmail","idPersonalEmail","idOtherEmail1","idOtherEmail2","idWorkAddress","idHomeAddress"];
            }
            if(component.get('v.mode') == 'admin' || component.get('v.corporatePermissions.editJobPositions')) {
                requiredInputs = ["idPrefix","idFirstName","idLastName","idGender","idHireDate","idOwnerTitle","idWorkPhone","idWorkEmail","idWorkAddress"];
                let varJPPositions = cmpEmployeeForm.find('idJPCmp').find('idPosition');
                let varJPStartDates = cmpEmployeeForm.find('idJPCmp').find('idStartDate');
                let arrRequiredInputs = [];
                if(Array.isArray(varJPPositions)) {
                    arrRequiredInputs.push(...varJPPositions);
                } else {
                    arrRequiredInputs.push(varJPPositions);
                }
                if(Array.isArray(varJPStartDates)) {
                    arrRequiredInputs.push(...varJPStartDates);
                } else {
                    arrRequiredInputs.push(varJPStartDates);
                }
                for(let inputPosition of arrRequiredInputs) {
                    if (!inputPosition.checkValidity()) {
                        inputPosition.showHelpMessageIfInvalid();
                        blnAllow = false;
                    }
                }
            }
            for (let idInput of requiredInputs) {
                let input = cmpEmployeeForm.find(idInput);
                if (input && !input.checkValidity()) {
                    input.showHelpMessageIfInvalid();
                    blnAllow = false;
                }
            }
            if(blnAllow) {
                let orgActiveDate = component.get('v.personRole.RE_Account__r.Org_activated__c');
                let hireDate = component.get('v.personRole.RE_Psn_Active_Date__c');
                if($A.localizationService.formatDate(hireDate, "yyyy MM dd ") < $A.localizationService.formatDate(orgActiveDate, "yyyy MM dd ")){
                    helper.showToast('error','The Hire date cannot be earlier than the Store activation date. Please change the Hire date.');
                    blnAllow = false;
                } 
            }
            if(ssnComponent) {
                let inputSSN;
                if(component.get('v.personRole.RE_Contact__r.MailingCountry') == 'Canada') {
                    inputSSN = ssnComponent.find('idSSNCan')
                } else {
                    inputSSN = ssnComponent.find('idSSN')
                }
                if (inputSSN && !inputSSN.checkValidity()) {
                    inputSSN.showHelpMessageIfInvalid();
                    blnAllow = false;
                }
            }
            if(!blnAllow) {
                helper.showToast('warning','Please verify your entries');
            }
            if(component.get('v.personRole.RE_Contact__r.MailingCountry') == 'Mexico'){
                let varStreetAddress = component.get('v.personRole.RE_Contact__r.MailingStreet');
                let varCity = component.get('v.personRole.RE_Contact__r.MailingCity');
                let varMexicanState = component.get('v.personRole.RE_Contact__r.MailingState');
                let varZipcode = component.get('v.personRole.RE_Contact__r.MailingPostalCode');
                let intFilledFields = 0;
                if(!$A.util.isEmpty(varStreetAddress)) {
                    intFilledFields++;
                }
                if(!$A.util.isEmpty(varCity)) {
                    intFilledFields++;
                }
                if(!$A.util.isEmpty(varMexicanState)) {
                    intFilledFields++;
                }
                if(!$A.util.isEmpty(varZipcode)) {
                    intFilledFields++;
                }
                if(intFilledFields !=0 && intFilledFields !=4){ 
                    helper.showToast('error','Please fill in all address fields among Street, Postal code, City, State',component);
                    blnAllow = false;                
                }             
            }
            if(blnAllow && component.get('v.mode') == 'edit' && component.get('v.personRole.RE_Contact__r.MailingCountry') != 'Mexico' && !component.get('v.corporatePermissions.viewW9')) {
                if($A.util.isEmpty(component.get('v.personRole.RE_Contact__r.Phone')) && 
                   $A.util.isEmpty(component.get('v.personRole.DPM_Work_Phone__c'))) {
                    helper.showToast('error','Please indicate at least one phone number.');
                    blnAllow = false;
                }
            }
            //Not required validations
            //Job Position Validations
            if(blnAllow && (component.get('v.mode') == 'admin' || (component.get('v.isSearchModal') && component.get('v.mode') == 'edit'))) {
                let lstJobPositions = component.get('v.personRole.DPM_Job_Positions__r');
                let hireDate = component.get('v.personRole.RE_Psn_Active_Date__c');
                let hasPrimary = false;
                let varJobTitle = [];
                for(let jobPosition of lstJobPositions) {
                    if($A.localizationService.formatDate(jobPosition.DPM_Position_Start_Date__c, "yyyy MM dd ") < $A.localizationService.formatDate(hireDate, "yyyy MM dd ")) {
                        helper.showToast('error','Start Date cannot be earlier than the Hire Date.');
                        blnAllow = false;
                        break;
                    }
                    if($A.localizationService.formatDate(jobPosition.DPM_Position_Start_Date__c, "yyyy MM dd ") > $A.localizationService.formatDate(jobPosition.DPM_Position_End_Date__c, "yyyy MM dd ")) {
                        helper.showToast('error','End Date cannot be earlier than the Start Date.');
                        blnAllow = false;
                        break;
                    }
                    if(!hasPrimary) {                    
                        if(jobPosition.DPM_Primary_Position__c && jobPosition.DPM_Position_End_Date__c == null) {
                            hasPrimary = jobPosition.DPM_Primary_Position__c;
                        }
                    }    
                    if(jobPosition.DPM_Position_End_Date__c == null){  //25/Feb/2021, skip terminated positions
                    	varJobTitle.push(jobPosition.DPM_Position_Title__c);
                    }
                }
                 if(blnAllow && !component.get('v.corporatePermissions.viewW9') && varPersonRole.RE_Psn_NonActive_Date__c==null) {
                    //Check for active primary positions
                    if(!hasPrimary) {
                        helper.showToast('error','One active Primary position should be assigned to the Retailer Employee.');
                        blnAllow = false; 
                    }
                }
                if(blnAllow && varPersonRole.RE_Psn_NonActive_Date__c==null) {
                    //Check for active primary positions
                    if(!hasPrimary) {
                        helper.showToast('error','One active Primary position should be assigned to the Retailer Employee.');
                        blnAllow = false; 
                    }
                }
                if(blnAllow) {
                    //Check for duplicate job titles
                    if(varJobTitle.length != new Set(varJobTitle).size) {
                        helper.showToast('error','Duplicate positions are selected, please select unique positions for the Retailer Employee.');
                        blnAllow = false; 
                    }
                }
            }
            if(blnAllow) {
                if($A.localizationService.formatDate(component.get('v.personRole.RE_Psn_NonActive_Date__c'), "yyyy MM dd ") < $A.localizationService.formatDate(component.get('v.personRole.RE_Psn_Active_Date__c'), "yyyy MM dd ")) {
                    helper.showToast('error','Termination date is earlier than the Hire date. Please verify your entry');
                    blnAllow = false;
                }
            }
        }
             //check DMSId validity
            let DMSEmployeeInput=cmpEmployeeForm.find('idDMSEmployee');
            if(DMSEmployeeInput.get('v.value')!=null){
                if (DMSEmployeeInput && !DMSEmployeeInput.checkValidity()) {
                    DMSEmployeeInput.showHelpMessageIfInvalid();
                    blnAllow = false;
                }
            }
        }catch(err){
            console.log(err.stack);
        }
        return blnAllow;
    },
    checkTermination : function(component, event, helper) {
        if(!$A.util.isEmpty(component.get('v.personRole.RE_Psn_NonActive_Date__c')) && !component.get("v.isTerminatedEmployee")) {
            component.set('v.strModalHeader','Confirm Termination');
            component.set('v.strModalBody','You are about to terminate this employee in your store. No data can be updated after saving. Also note that the employee will lose their access to the Portal and any Salesforce application in your store on that date. Do you confirm?');
            component.set('v.strModalType','confirmation_styletwo');
            let parameters = {"strModalBody": component.get("v.strModalBody"),"strModalHeader":component.get("v.strModalHeader"), "strModalType":component.get("v.strModalType")};
            helper.createModal(component,'c:DPM_NotificationModal',parameters);
        } else {
            return true;
        }
        return false;
    },
    checkW9Exempt : function(component, event, helper){
        if(component.get('v.personRole.RE_Contact__r.DPM_W9_Exempt__c') && !component.get("v.isW9Exempt")) {
            component.set('v.strModalHeader','Confirm W9 Exempt');
            component.set('v.strModalBody','The W9 Exempt checkbox has been selected!  Click the Confirm button, if this employee should not receive a DPM reminder email, when the W9 that exists with VCUSA is over 2 years old!');
            component.set('v.strModalType','confirmation_btns_confirm_cancel');
            let parameters = {"aura:id":"idAlertW9Cancel","strModalBody": component.get("v.strModalBody"),"strModalHeader":component.get("v.strModalHeader"), "strModalType":component.get("v.strModalType")};
            helper.createModal(component,'c:DPM_NotificationModal',parameters);
        }else {
            return true;
        }
        return false;
	},
    checkMissingSSN : function(component,event,helper) {
        if(component.get('v.personRole.RE_Contact__r.RecordType.Name') =='Supplier Employee'){
            return true;
        }
        if(component.get('v.mode') == 'admin') {
            return true;
        }
        let lstJobPositions = component.get('v.personRole.DPM_Job_Positions__r');
        let lstIncentiveEligiblePositions = component.get('v.incentivePositionsList');
        let lstVowels = ['a','e','i','o','u'];
        if(lstJobPositions!=null && lstJobPositions.length>0 && (component.get('v.personRole.RE_Contact__r.MailingCountry') != 'Mexico') && (component.get('v.personRole.RE_Contact__r.MailingCountry') != 'Canada'))
        {
            for(let jobPosition of lstJobPositions) {
                let varSSN = (component.get('v.personRole.RE_Contact__r.MailingCountry')=='United States'?'SSN':'SIN');
                if(lstIncentiveEligiblePositions.includes(jobPosition.DPM_Position_Title__c) && $A.util.isEmpty(component.get('v.personRole.RE_Contact__r.DPM_SSN__c'))) {
                    let alertHeader = 'Missing '+varSSN;
                    let firstCharacter = (jobPosition.DPM_Position_Title__c).charAt(0).toLowerCase;
                    let varArticle = (lstVowels.includes(firstCharacter)?'an':'a');
                    let alertBody = 'As '+varArticle+' '+jobPosition.DPM_Position_Title__c+ ' you may qualify for incentives. '+varSSN+' must be provided to receive incentive payments. Please go Back to update your '+varSSN+',or click on Save to save your data without '+varSSN+'.';
                    component.set('v.strModalType','confirmation_stylethree');
                    component.set('v.strModalHeader','Missing SSN');
                    component.set('v.strModalBody',alertBody);
                    component.set('v.showNotification',true);
                    helper.hideSpinner(component);
                    return false;
                }
            }
        }
        return true;
    },
    showToast : function(type,message) {
        let toastEvent = $A.get("e.force:showToast");
        let title = (type=='error'?'Error!':(type=='success'?'Success!':'Warning!'));
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type":type
        });
        toastEvent.fire();        
    },
    saveRecord : function(component, event, helper) {
        let saveAction = component.get('c.saveEmployeeProfile');
        let employeeProfile = component.get('v.personRole');
        //keep backup
        let fullPersonRole=JSON.parse(JSON.stringify(employeeProfile));
        
        let employeeContact = component.get('v.personRole.RE_Contact__r');
        if(employeeContact.DPM_Gender__c!='Non-binary'){
            employeeContact.DPM_Other_Gender__c='';
        }
        let employeeJobPositions = component.get('v.personRole.DPM_Job_Positions__r');
        delete employeeProfile['DPM_Job_Positions__r']; 
        delete employeeProfile['RE_Contact__r']; 
        delete employeeProfile['RE_Account__r']; 
        delete employeeProfile['Region__r']; 
        delete employeeProfile['Market__r']; 
        delete employeeContact['Cds_Id__c'];
        delete employeeContact['Email'];
        saveAction.setParams({strPersonRole:JSON.stringify(employeeProfile),strContact:JSON.stringify(employeeContact),strJobPositions:JSON.stringify(employeeJobPositions)});
        helper.showSpinner(component);
        saveAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                window.setTimeout( $A.getCallback(function() { 
                    helper.refreshDPM(component);
                    helper.hideSpinner(component);
                    helper.closeModal(component);
                    let message='The profile has been updated';
                    helper.showToast('success',message);
                }), 5000 );                
            } else {
                let errors = response.getError();
                let message = $A.get("$Label.c.DPM_System_Error"); // Default error message
                // Retrieve the error message sent by the server
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    let systemErrorMessage = errors[0].message;
                     if(systemErrorMessage.includes('DMS Employee#')){
                        message=systemErrorMessage;
                    }
                    helper.generateDPMLog(component, event, helper,employeeProfile.RE_Account__c,systemErrorMessage);
                }
               
                // Display the message
                if(message.includes('DMS Employee#')){
                    helper.showToast('warning',message,component);                    
                }else{
                    helper.showToast('error',message,component);
                }
                //put related lists as it is
                    component.set("v.personRole",fullPersonRole);
                helper.hideSpinner(component);                
                
            } 
        });
        $A.enqueueAction(saveAction);
    },
    generateDPMLog : function(component, event, helper, parentAccountId,ErrorMessage) {
        let action = component.get("c.createDPMErrorNotification");
        action.setParams({accountId:parentAccountId,strExceptionMsg:ErrorMessage});
        action.setCallback(this, function(response) {
            var state = response.getState();
            //alert(state);
            if (state === "SUCCESS") {  
                return true;
            }
        });
        $A.enqueueAction(action);
        return true;
    },
    showSpinner : function(component) {
        $A.util.removeClass(component.find('idSpinner'),'slds-hide');        
    },
    hideSpinner : function(component) {
        $A.util.addClass(component.find('idSpinner'),'slds-hide');
    },
    refreshDPM : function(component) {
        let terminationdate=$A.localizationService.formatDate(component.get('v.personRole.RE_Psn_NonActive_Date__c'), "yyyy MM dd ");
        let todaydate = $A.localizationService.formatDate(new Date(), "yyyy MM dd ");
        if(!component.get('v.isSearchModal') && terminationdate && terminationdate <= todaydate) {
            window.open('./digital-personnel-master','_top');
            return;
        }
        if(component.get('v.isSearchModal')) {
            component.getEvent("refreshDPMEvent").fire();
        } else {
            if(!$A.util.isEmpty(component.get('v.personRole.RE_Psn_NonActive_Date__c'))) {
                $A.get('e.force:refreshView').fire(); 
            } else {
                component.getEvent("refreshDPMEvent").fire();
            }  
        }     
    },
    createModal : function(component, componentName, parameters) {
        $A.createComponent(componentName, parameters, function(modal, status, errorMessage) {
            if (status === 'SUCCESS') {
                var body = component.get('v.body');
                body.push(modal);
                component.set('v.body', body);
            } else if (status === "INCOMPLETE") {
                console.warn("No response from server or client is offline.")
            } else if (status === "ERROR") {
                    console.error("Error: " + errorMessage);
            }
        });
    },
})