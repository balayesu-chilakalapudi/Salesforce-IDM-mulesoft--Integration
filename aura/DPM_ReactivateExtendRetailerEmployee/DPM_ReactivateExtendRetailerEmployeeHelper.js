({
    getSuffixList : function(component, event, helper) {
        helper.getPicklistValuesFromDPM(component, helper, 'DPM_Suffix__c');
    },
    getCurrentDealership : function(component, event, helper) {
        var accountAction = component.get("c.getCurrentAccount");
        accountAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let currentAccount = response.getReturnValue();
                component.set('v.account',currentAccount);
                component.set('v.DPMEmployee.DPM_Account__c',currentAccount.Id);
                helper.hideSpinner(component);
            }
        });
        $A.enqueueAction(accountAction);
    },
    getDealershipOptions : function(component, event, helper) {
        var accountAction = component.get('c.getAllDealerships');
        accountAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let varDealerships = response.getReturnValue();
                let picklistOptions = [];
                picklistOptions.push({text:'--None--',value:''});
                if(!$A.util.isEmpty(varDealerships)) {
                    for(let dealership of varDealerships) {
                        picklistOptions.push(
                            {
                                text:dealership.Name+' - '+dealership.Retailer__c,
                                value:dealership.Id
                            }
                        );
                    }
                }                
                component.set('v.dealershipsList',picklistOptions);
                helper.hideSpinner(component);
            }
        });
        $A.enqueueAction(accountAction);
    },
    getPicklistValuesFromDPM : function(component, helper, strAPIName) {
        var initAction = component.get('c.getPicklistValues');
        initAction.setParams({strFieldName:strAPIName});
        initAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let picklistValues = response.getReturnValue();
                switch(strAPIName) {                    
                    case 'DPM_Suffix__c':
                        component.set('v.suffixList',helper.generatePicklistOptions(picklistValues));                        
                        break;
                    default:
                        break;
                }
            }
        });
        $A.enqueueAction(initAction);
    },
    generatePicklistOptions : function(lstPicklistValues) {
        let picklistOptions = [];
        for(let picklistValue of lstPicklistValues) {
            picklistOptions.push(
                {
                    text:picklistValue,
                    value:(picklistValue=='--None--'?'':picklistValue)
                }
            );
        }
        return picklistOptions;
    },
    showSpinner : function(component) {
        $A.util.removeClass(component.find('idSpinner'),'slds-hide');
    },
    hideSpinner : function(component) {
        $A.util.addClass(component.find('idSpinner'),'slds-hide');
    },
    closeModal : function(component) {
        component.destroy();
    },  
    validateFields:function(component,event,helper){
        let blnAllow = true;
       // let requiredInputs = ["firstName","preferredName","lastName","suffix","email","phoneNumber"];
        let requiredInputs =[];        
        if(component.get("v.fromPortal")){
        	requiredInputs=["firstName","preferredName","lastName","suffix","email","phoneNumber"];
        }else{
            requiredInputs=["firstName","preferredName","lastName","suffix","email","phoneNumber","idAccount"];
        }
        for (let idInput of requiredInputs) {
            let input = component.find(idInput);
            if (input && !input.checkValidity()) {
                input.showHelpMessageIfInvalid();
                blnAllow = false;
            }
        }
        return blnAllow;
    },
    fetchMatchingProfiles : function(component,event,helper) {
        let fetchProfilesAction = component.get('c.findMatchingProfilesForReactivation');
        fetchProfilesAction.setParams({strDPMEmployee:JSON.stringify(component.get("v.DPMEmployee"))});
        fetchProfilesAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let varMatchingProfiles = response.getReturnValue();
                //console.log(JSON.stringify(varMatchingProfiles));
                component.set("v.showPopup",false); 
                helper.hideSpinner(component);
                if(varMatchingProfiles && varMatchingProfiles.length > 0) {
                    let sortedProfiles = helper.sortMatchingProfiles(component,event,helper,varMatchingProfiles);
                    helper.viewMatchingProfileListModal(component,event,helper,sortedProfiles);                    
                } else {
                    let parameters = {"aura:id":"idAlert",
                                      "strModalHeader":"No Matching Profiles Found",
                                      "strModalBody":"Our system could not find any record matching those fields. Please verify your entry, and check with the future employee before trying again.",
                                      "strModalType":"alert_styletwo"};
                    helper.createModal(component,'c:DPM_NotificationModal',parameters);
                }
            } else {
                let errors = response.getError();
                let message = 'Unknown error'; // Default error message
                // Retrieve the error message sent by the server
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                // Display the message
                helper.showToast('error',message);
                helper.hideSpinner(component);
            }   
        });
        $A.enqueueAction(fetchProfilesAction);
    },
    viewMatchingProfileListModal : function(component,event,helper,sortedProfiles) {
       // console.log('asd1 '+ component.get('v.DPMEmployee'));
        let parameters = {"aura:id":"idMatchingProfileList","fromPortal":component.get('v.fromPortal'),"profileList":sortedProfiles,"dpmEmployee":component.get('v.DPMEmployee'),"account":component.get('v.account')};
        let dpmNextEvent = component.getEvent("nextModalEvent"); 
        dpmNextEvent.setParams({"blnNext":true,"modalName":"c:DPM_MatchingProfileList","modalParams":JSON.stringify(parameters)});
        dpmNextEvent.fire();
        component.destroy();
    },
    createModal : function(component,componentName,parameters) {
        $A.createComponent(componentName, parameters, function(modal,status,errorMessage) {
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
    sortMatchingProfiles : function(component,event,helper,varMatchingProfiles) {
        let varActiveProfiles = [];
        let varInactiveProfiles = [];
        for(let varProfile of varMatchingProfiles) {
            if(varProfile.Person_Roles__r && varProfile.Person_Roles__r.length>0) {
                //varProfile.Person_Roles__r = (helper.sortList(varProfile.Person_Roles__r,'date')).reverse();
                let varActivePersonRoles = [];
                let varInactivePersonRoles = [];
                let blnActive = false;
                for(let varPersonRole of varProfile.Person_Roles__r) {                    
                    if(!$A.util.isEmpty(varPersonRole.RE_Psn_Active_Date__c)) {
                        varPersonRole.hireYear = (new Date(varPersonRole.RE_Psn_Active_Date__c)).getFullYear();
                    }
                    if(!$A.util.isEmpty(varPersonRole.RE_Psn_NonActive_Date__c)) {
                        varPersonRole.terminationYear = (new Date(varPersonRole.RE_Psn_NonActive_Date__c)).getFullYear();
                    }
                    if(varPersonRole.RE_Psn_Active__c) {
                        blnActive = true;
                        varActivePersonRoles.push(varPersonRole);
                    } else {
                        varInactivePersonRoles.push(varPersonRole);
                    }
                }  
                varActivePersonRoles = (helper.sortList(varActivePersonRoles,'RE_Psn_Active_Date__c')).reverse();
                varInactivePersonRoles = (helper.sortList(varInactivePersonRoles,'RE_Psn_NonActive_Date__c')).reverse();
                varProfile.Person_Roles__r = varActivePersonRoles.concat(varInactivePersonRoles);
                if(blnActive) {
                    varActiveProfiles.push(varProfile);
                } else {
                    varInactiveProfiles.push(varProfile);
                }
            }            
        }
        return varActiveProfiles.concat(varInactiveProfiles);
    },
    sortList : function(lstToBeSorted,field) {
        return lstToBeSorted.sort(function(a,b) {
            return new Date(a[field]) - new Date(b[field]);
        });
    },
})