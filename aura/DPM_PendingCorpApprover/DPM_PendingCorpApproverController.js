({
    doInit : function(component, event, helper) {
        helper.showSpinner(component);
        var action = component.get("c.getStatusValue");
        action.setParams({ strRecordId : component.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            //alert(component.get("v.recordId"));
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set("v.DPMEmployee",result);
                component.set("v.DPMJobPositions",result.DPM_Job_Positions__r);
                helper.hideSpinner(component);
            }
            else if (state === "INCOMPLETE") {
                // do something
                helper.hideSpinner(component);
            }
                else if (state === "ERROR") {
                    helper.hideSpinner(component);
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + 
                                        errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }
        });
        $A.enqueueAction(action);
    },
    handleExit : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire() 
    },
    handleApprove : function(component, event, helper) {
        let varDPMEmployee = component.get('v.DPMEmployee');
        helper.showSpinner(component);
        varDPMEmployee.DPM_Status__c = 'Approved';
        //Remove related lists (parent and child)
        delete varDPMEmployee['DPM_Job_Positions__r'];
        delete varDPMEmployee['DPM_Account__r'];
        var submitAction = component.get('c.submitDPMRecord');
        submitAction.setParams({strDPMEmployee:JSON.stringify(varDPMEmployee),strDPMJobPositions:JSON.stringify(component.get('v.DPMJobPositions')),strType:varDPMEmployee.DPM_Status__c});
        submitAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                helper.hideSpinner(component);
                helper.showToast('success','Record has been Successfully Approved!');
                $A.get("e.force:closeQuickAction").fire();
                $A.get('e.force:refreshView').fire();
            } else {
                let errors = response.getError();
                let message = $A.get("$Label.c.DPM_System_Error"); // Default error message
                // Retrieve the error message sent by the server
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    let systemErrorMessage = errors[0].message;
                    helper.generateDPMLog(component, event, helper,varDPMEmployee.DPM_Account__c,systemErrorMessage);
                }
                // Display the message
                helper.hideSpinner(component);
                helper.showToast('error',message);
                $A.get("e.force:closeQuickAction").fire();
                $A.get('e.force:refreshView').fire();
            }  
        });
        $A.enqueueAction(submitAction);
    },
    handleReject:function(component,event,helper){
        let confirmBody = 'Do you confirm that this is a returning Volvo employee?  An email will be sent to the retailer admin requesting them to add the employee using the reactivate/extend an employee feature';
        let parameters = {"aura:id":"idConfirmModal","strModalHeader":"Reject Confirmation","strModalBody":confirmBody,
                      "strModalType":"confirmation_btns_confirm_cancel"};
        helper.createNewComponent(component, event, helper,'c:DPM_NotificationModal',parameters);
    },
    handleNotificationEvent:function(component,event,helper){
        let varType = event.getParam("type");
        if(varType == 'confirmation_btns_confirm_cancel') {
            if(event.getParam("message") == 'confirmClicked') {
                component.find('idConfirmModal').destroy();
                //send email to retailer admin
                helper.notifyRejectEmail(component,event,helper);                
            } else {
                component.find('idConfirmModal').destroy();
                $A.get("e.force:closeQuickAction").fire();
                $A.get('e.force:refreshView').fire(); 
            }          
        }
    }
})