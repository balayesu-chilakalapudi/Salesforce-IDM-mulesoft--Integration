({
    doInit : function(component, event, helper) {
        if($A.util.isEmpty(window.location.search)) {
            component.set('v.errorMessage','The URL is invalid.');
        } else {
            helper.showSpinner(component);
            helper.decryptIdAndCheckLinkExpiry(component, event, helper);
            helper.getGenderList(component, event, helper);
            helper.getPrefixList(component, event, helper);
            helper.getSuffixList(component, event, helper);
            helper.getPositionsList(component, event, helper); 
            helper.getProficiencyValues(component, event, helper);
        }        
    },    
    capitalizeInput : function(component,event,helper) {
        let strText = event.getSource().get("v.value");
        if(!$A.util.isEmpty(strText)) {
            event.getSource().set("v.value",helper.capitalize(strText));
        }        
    },
    save : function(component, event, helper) {
        if(helper.compareSSN(component,event,helper,'fromSave')) {
            if(helper.checkMissingSSN(component, event, helper, false)) {
                helper.showPrompt(component, event, helper, 'savePrompt', 'Your data will be saved. If you want to submit your profile, please click on submit.', 'Save Profile');
            }
        }        
    },
    submit : function(component, event, helper) {
        if(helper.validateFields(component, event, helper)) {  //22/Feb/2021, check validation before showing prompt
            if(helper.compareSSN(component,event,helper,'fromSubmit')) {
                if(helper.checkMissingSSN(component, event, helper, true)) {
                    helper.showPrompt(component, event, helper, 'submitPrompt', 'You are about to submit your profile. No data can be changed after submission, please confirm.', 'Submit Profile');
                }                
            }     
        }
    },
    handlePromptEvent : function(component, event, helper) {
        let varMessage = event.getParam("message");
        let varType = event.getParam("type");
        if(varMessage == 'ok') {
            helper.showSpinner(component);
            if(varType == 'savePrompt') {
                if(helper.validateSaveOnlyFields(component, event, helper)) {
                    helper.saveRecordToDB(component, event, helper, 'Saved');
                }                
            } else if(varType == 'submitPrompt') {
                if(helper.validateFields(component, event, helper)) {
                    //console.log('#####1');
                      if(component.get('v.DPMEmployee.DPM_Request_Type__c') == 'New') {
                        //console.log('#####2');
                        helper.checkDuplicates(component,event,helper);
                    } else {
                        //console.log('#####3');
                        helper.saveRecordToDB(component, event, helper, 'Submitted'); 
                    }
                }
            } else {
                helper.hideSpinner(component);
            }          
        }
        event.stopPropagation();
    },
    handleNotificationEvent : function(component, event, helper) {        
        let varType = event.getParam("type");
        if(varType == 'matchingProfile') {
            let varMessage = event.getParam("message");
            if(varMessage == 'no') {
                component.set('v.hasAccess',false);
                component.set('v.errorMessage','Your data will not be saved. Please contact your Store Admin to confirm the information we have on file for your profile.');
            }
            if(varMessage.includes('yes')) {
                if(varMessage.includes('fromSave')) {
                    helper.saveRecordToDB(component, event, helper, 'Saved - SSN Mismatch');
                } else if(varMessage.includes('fromSubmit')) {
                    helper.saveRecordToDB(component, event, helper, 'Submitted - SSN Mismatch');
                }                
            }            
        }
        if(varType == 'duplicate') {
            let varRecId = event.getParam("message");
            let lstDupRecords = component.get('v.lstDuplicateRecords');
            for(let dupRecord of lstDupRecords) {
                if(varRecId == dupRecord.recordId) {
                    helper.showSpinner(component);
                    if(dupRecord.blnPlacebo || varRecId == 'None') {
                        helper.saveRecordToDB(component, event, helper, 'Submitted - Duplicate Not Confirmed');
                    } else {
                        helper.saveRecordToDB(component, event, helper, 'Submitted - Duplicate Confirmed');
                    }
                    break;
                }
            }
        }
        if(varType == 'confirmation_stylethree') {
            let notificationCmp = component.find('idAlertModal');
            if(event.getParam("message") == 'saveClicked') {   
                notificationCmp.destroy();
                if(component.get('v.blnSSNMissingSubmit')) {
                    helper.showPrompt(component, event, helper, 'submitPrompt', 'You are about to submit your profile. No data can be changed after submission, please confirm.', 'Submit Profile');
                } else {
                    helper.showPrompt(component, event, helper, 'savePrompt', 'Your data will be saved. If you want to submit your profile, please click on submit.', 'Save Profile');
                }
            } else {
                notificationCmp.destroy();
                component.set('v.showNotification',false);
            }
        }
        event.stopPropagation();
    },
    handleContext : function(component, event, helper) {
        event.preventDefault();
    },
    handlePaste : function(component, event, helper) {
        event.preventDefault();
    },
    checkConfirmation : function(component, event, helper) {
        helper.checkConfirmationHelper(component, event, helper);
    },
    countryChanged : function(component, event, helper) {        
        helper.setStateList(component);
        helper.clearDiversityData(component);
        helper.setDiversityDataByCountry(component, event, helper); 
        let country = component.get('v.DPMEmployee.DPM_Country__c');
        if(country == 'Canada') {
            component.set('v.SSNBtnLabel',(component.get('v.SSNBtnLabel')).replace('SSN','SIN'));                       
        } else {
            component.set('v.SSNBtnLabel',(component.get('v.SSNBtnLabel')).replace('SIN','SSN')); 
        }
        if(country == 'Mexico') {
        	helper.clearSSNData(component);
        }
    },
    showHideSSN : function(component, event, helper) {
        helper.showHideSSNHelper(component, event, helper);
    },    
})