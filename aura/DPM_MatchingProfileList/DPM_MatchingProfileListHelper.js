({
    viewEditEmployeeModal : function(component, event, helper) {
        helper.createDPMEmployee(component,event,helper); 
    },
    createModal : function(component, componentName, parameters) {
       // console.log('createModal running');
        $A.createComponent(componentName, parameters, function(modal, status, errorMessage) {
            if (status === 'SUCCESS') {
                var body = component.get('v.body');
                body.push(modal);
                component.set('v.body', body);
            } else if (status === "INCOMPLETE") {
                console.warn("No response from server or client is offline.")
            }
                else if (status === "ERROR") {
                    console.error("Error: " + errorMessage);
                }
        });
    },
    createDPMEmployee : function(component,event,helper) {
        let selectedContact;
        let profileList = component.get('v.profileList');
        for(let contact of profileList) {
            if(contact.Id == component.get('v.selectedProfile')) {
                selectedContact = contact;
                break;
            }
        }
        let dpmEmployee = {};        
        dpmEmployee.DPM_Contact__c = selectedContact.Id;
        dpmEmployee.DPM_Prefix__c = selectedContact.Salutation;
        dpmEmployee.DPM_Suffix__c = selectedContact.Suffix;
        dpmEmployee.DPM_Legal_First_Name__c = selectedContact.FirstName;
        dpmEmployee.DPM_Preferred_First_Name__c = selectedContact.DPM_Preferred_First_Name__c;
        dpmEmployee.DPM_Middle_Name__c = selectedContact.MiddleName;
        dpmEmployee.DPM_Last_Name__c = selectedContact.LastName;
        dpmEmployee.DPM_Email__c = component.get('v.dpmEmployee.DPM_Email__c');
        dpmEmployee.DPM_Personal_Email__c = selectedContact.DPM_Personal_Email__c;
        dpmEmployee.DPM_Gender__c = selectedContact.DPM_Gender__c;
        dpmEmployee.DPM_Other_Gender__c = selectedContact.DPM_Other_Gender__c;
        dpmEmployee.DPM_Last_Name__c = selectedContact.LastName;
        dpmEmployee.DPM_Request_Type__c = 'Activation';
        // for user story 2301241 
        dpmEmployee.DPM_Hire_Date__c = selectedContact.Employee_Hired_Date__c; 
        dpmEmployee.DPM_Cell_Phone__c = selectedContact.Phone; 
        if(selectedContact.MailingStreet != null){
            var strSplitMailStreet = selectedContact.MailingStreet.split('\r\n');
            dpmEmployee.DPM_Home_Address_Street__c = strSplitMailStreet[0]; 
            if(strSplitMailStreet.length > 0 && strSplitMailStreet[1] != null){
            	dpmEmployee.DPM_Home_Address_Street_2__c = strSplitMailStreet[1];
            }
        }
        dpmEmployee.DPM_City__c =selectedContact.MailingCity; 
        dpmEmployee.DPM_Country__c =selectedContact.MailingCountry;
        if(selectedContact.MailingCountry == 'United States') {
            dpmEmployee.DPM_US_State__c =selectedContact.MailingState;
        } else if(selectedContact.MailingCountry == 'Canada') {
            dpmEmployee.DPM_Canadian_State__c =selectedContact.MailingState;
        }
        else{
            dpmEmployee.DPM_Mexican_State__c =selectedContact.MailingState;
        }       
        dpmEmployee.DPM_Zipcode__c =selectedContact.MailingPostalCode;
        if(component.get('v.dpmEmployee.DPM_Record_Origin__c')=='Corporate') {
            dpmEmployee.DPM_Account__c = component.get('v.dpmEmployee.DPM_Account__c');
        }
        for(let varPersonRole of selectedContact.Person_Roles__r) {
            if(varPersonRole.RE_Psn_Active__c) {
                dpmEmployee.DPM_Request_Type__c = 'Extension';
                break;
            }
        }        
        let parameters = {"aura:id":"idActivationRequestFinal","fromPortal":component.get('v.fromPortal'),"DPMEmployee":dpmEmployee,"profileList":component.get('v.profileList'),"strActivationType":dpmEmployee.DPM_Request_Type__c,"blnBackBtn":true};
        let dpmNextEvent = component.getEvent("nextModalEvent"); 
        dpmNextEvent.setParams({"blnNext":true,"modalName":"c:DPM_NewRetailerEmployeeCmp","modalParams":JSON.stringify(parameters)});
        dpmNextEvent.fire();
        component.destroy();
    },
    checkIfSelectionIsValid : function(component,event,helper,selectedContactId) {
        let selectedContact;
        let profileList = component.get('v.profileList');
        let currentAccountId;
       // console.log(JSON.stringify(component.get('v.dpmEmployee')));
        if(component.get('v.dpmEmployee.DPM_Record_Origin__c')=='Corporate') {
            currentAccountId = component.get('v.dpmEmployee.DPM_Account__c');
        } else {
            currentAccountId = component.get('v.account.Id');
        }
        for(let contact of profileList) {
            if(contact.Id == selectedContactId) {
                selectedContact = contact;
                break;
            }
        }
        for(let personRole of selectedContact.Person_Roles__r) {
            if(personRole.RE_Account__c == currentAccountId && personRole.RE_Psn_Active__c) {
                return false;
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
})