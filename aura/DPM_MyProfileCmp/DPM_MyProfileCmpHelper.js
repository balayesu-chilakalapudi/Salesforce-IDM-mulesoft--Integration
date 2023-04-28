({
    getProfile : function(component,event,helper) {
        let varCurrentURLParam = window.location.search.substring(1);        
        let varParamNameValuePair = varCurrentURLParam.split('=');
        let varId = '';
        if (varParamNameValuePair[0] == 'id') {
            varId = varParamNameValuePair[1]; 
        } 
        if(varId=='') {
        	component.set('v.isRetailerAdmin',false);       
        }
        let fetchAction = component.get('c.getCurrentUserProfile');
        fetchAction.setParams({'strPersonRoleId':varId});
        fetchAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
              //  console.log(JSON.stringify(response.getReturnValue()));
                let varPersonRole = response.getReturnValue();                
                let varJobPositions = varPersonRole.DPM_Job_Positions__r;
                let varJobPositionsToShow = [];
                if(!$A.util.isEmpty(varJobPositions)) {
                    for(let position of varJobPositions) {
                        if(!$A.util.isEmpty(position.DPM_Position_End_Date__c)) {
                            position.blnAlreadyTerminated = true;
                        }                        
                        if(position.DPM_Position_Start_Date__c != position.DPM_Position_End_Date__c) {
                            varJobPositionsToShow.push(position);
                        }
                    }
                }
                varPersonRole.DPM_Job_Positions__r = varJobPositionsToShow;
                if(!$A.util.isEmpty(varPersonRole.RE_Contact__r.DPM_SSN__c)) {                    
                    let varLastFourSSN = (varPersonRole.RE_Contact__r.DPM_SSN__c).substring(5,9);
                    if(varPersonRole.RE_Contact__r.MailingCountry == 'Canada') {
                        varLastFourSSN = (varPersonRole.RE_Contact__r.DPM_SSN__c).substring(6,9);
                        varPersonRole.RE_Contact__r.DPM_SSNLastFour = '***-***-'+varLastFourSSN;
                    } else {
                        varLastFourSSN = (varPersonRole.RE_Contact__r.DPM_SSN__c).substring(5,9);
                        varPersonRole.RE_Contact__r.DPM_SSNLastFour = '***-**-'+varLastFourSSN;
                    }                    
                    varPersonRole.RE_Contact__r.DPM_SSN__c = helper.formatSSN(varPersonRole.RE_Contact__r.DPM_SSN__c,varPersonRole.RE_Contact__r.MailingCountry);
                }                 
                component.set('v.personRole',varPersonRole);
                if(varId == '') {
                    component.set('v.mode','edit');
                    component.set('v.blnSuccess',true);
                    //21/Dec/2020, Task #1896770, check admin or user from employee profile
                if(varPersonRole.RE_IsAdmin__c){
                    component.set("v.adminView",true);
                }
                else{
                    component.set("v.adminView",false);
                }
                } else {
                    //Check if the user is retailer admin
                    helper.adminCheck(component,event,helper);
                }
            } else if (state === "ERROR") {
                // Process error returned by server
                let errors = response.getError();
                let message = 'Unknown error'; // Default error message
                // Retrieve the error message sent by the server
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                if(message.includes('List has no rows')) {
                    message = 'Employee does not exists or the information is not available.';
                }
                // Display the message
                helper.showToast('error',message);
                component.set('v.errorMessage',message);
            } else {
                // Handle other reponse states
            } 
        });
        $A.enqueueAction(fetchAction);
    },
    viewNewEmployeeModal : function(component, event, helper) {
        let parameters = {
            "aura:id":"idEditEmployeeCmp",
            "personRole":component.get('v.personRole'),
            "account":component.get('v.personRole.RE_Account__r'),
            "contact":component.get('v.personRole.RE_Contact__r'),
            "jobPositions":component.get('v.personRole.DPM_Job_Positions__r'),
            "mode":component.get('v.mode'),
            "isRetailerAdmin":component.get('v.isRetailerAdmin'),
            "incentivePositionsList":component.get('v.incentivePositionsList'),
             "fromPortal":true
        };
        helper.createModal(component, 'c:DPM_EditEmployeeProfile',parameters);        
    },	
    createModal : function(component, componentName, parameters) {
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
    adminCheck : function(component,event,helper) {
        let checkAdminAction = component.get('c.currentPersonRole');
        checkAdminAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let currentPersonRole = response.getReturnValue();
                let employeePersonRole = component.get('v.personRole');
              //  console.log('employeePersonRole:'+JSON.stringify(employeePersonRole));
               // console.log('currentPersonRole:'+JSON.stringify(currentPersonRole));
                //21/Dec/2020, Task #1896770, check admin or user from My Profile
                if(currentPersonRole.RE_IsAdmin__c){
                    component.set("v.adminView",true);
                }
                else{
                    component.set("v.adminView",false);
                }
                if(currentPersonRole.RE_Account__c != employeePersonRole.RE_Account__c) {
                    console.error("You are not authorized to see this Employee's data");
                } else {
                    if(currentPersonRole.Id == employeePersonRole.Id) {
                        component.set('v.mode','edit');
                        component.set('v.blnSuccess',true);
                    } else {
                        component.set('v.mode','admin');
                        component.set('v.blnSuccess',true);                        
                    }   
                }                
            } else if (state === "ERROR") {
                // Process error returned by server
                    let errors = response.getError();
                let message = 'Unknown error'; // Default error message
                // Retrieve the error message sent by the server
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                if(message.includes('List has no rows')) {
                    message = 'Employee does not exists or the information is not available.';
                }
                // Display the message
                helper.showToast('error',message);
                component.set('v.errorMessage',message);
            } else {
                // Handle other reponse states
            } 
        });
        $A.enqueueAction(checkAdminAction);
    },
    showToast : function(type,message) {
        let toastEvent = $A.get("e.force:showToast");
        let title = (type=='error'?'Error!':(type=='success'?'Success!':'Warning!'));
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type":type,
            "mode":"sticky"
        });
        toastEvent.fire();        
    },
    formatSSN : function(varSSN,varCountry) {
        if(varCountry == 'Canada') {
            varSSN = varSSN.substring(0,3)+'-'+varSSN.substring(3,6)+'-'+varSSN.substring(6,9);
        } else {
            varSSN = varSSN.substring(0,3)+'-'+varSSN.substring(3,5)+'-'+varSSN.substring(5,9);
        }
        //console.log('ssn123 '+varSSN);
        return varSSN;
    },
    getPositionsList : function(component, event, helper) {
        helper.getPicklistValuesForPositions(component, helper);
    },
    getPicklistValuesForPositions : function(component, helper) {
        //get Account from personRole
        let IdAccount=null;
        try{
            IdAccount=component.get('v.personRole').RE_Account__c;
        }catch(err){
            console.log(err.stack);
        }	
        console.log('IdAccount:'+IdAccount);
        let params={'retailer_storeId':IdAccount};
        var initPositionAction = component.get('c.getAllJobPositions');
        initPositionAction.setParams(params);
      //  console.log('herer');
        initPositionAction.setCallback(this, function(response) {
            var state = response.getState();
          //  console.log(state);
            if (state === "SUCCESS") {
                let varIncentiveEligiblePositions = [];
                let varAllJobPositions = response.getReturnValue();
                for(let jobPosition of varAllJobPositions) {					
                    if(jobPosition.DPM_Incentive_Eligible__c) {
                        varIncentiveEligiblePositions.push(jobPosition.MasterLabel);
                    }
                }
             //   console.log(varIncentiveEligiblePositions);
                component.set('v.incentivePositionsList',varIncentiveEligiblePositions);
            }
        });
        $A.enqueueAction(initPositionAction);
    },
})