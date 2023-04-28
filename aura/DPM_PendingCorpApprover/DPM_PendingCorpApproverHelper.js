({
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
    generateDPMLog : function(component, event, helper, parentAccountId,ErrorMessage) {
        let action = component.get("c.createDPMErrorNotification");
        action.setParams({accountId:parentAccountId,strExceptionMsg:ErrorMessage});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {  
                return true;
            }
        });
        $A.enqueueAction(action);
        return true;
    },
    hideSpinner : function(component) {
        $A.util.addClass(component.find('idSpinner'),'slds-hide');
    },
    showSpinner : function(component) {
        $A.util.removeClass(component.find('idSpinner'),'slds-hide');
    }
	,
    createNewComponent : function(component, event, helper, componentName, parameters) {
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
    notifyRejectEmail:function(component,event,helper){
        helper.showSpinner(component);
        let varDPMEmployee = component.get('v.DPMEmployee');
        let action = component.get("c.sendRejectEmailToRetailerAdmin");
        action.setParams({strRecordId:component.get("v.recordId")});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") { 
            helper.showToast('success','Record has been Successfully Rejected!');
            $A.get("e.force:closeQuickAction").fire();
            $A.get('e.force:refreshView').fire();
            return true;
            }else{
                let errors = response.getError();
                let message = $A.get("$Label.c.DPM_System_Error"); // Default error message
                // Retrieve the error message sent by the server
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    let systemErrorMessage = errors[0].message;
                    helper.generateDPMLog(component, event, helper,varDPMEmployee.DPM_Account__c,systemErrorMessage);
                }
                // Display the message                
                helper.showToast('error',message);
                $A.get("e.force:closeQuickAction").fire();
                $A.get('e.force:refreshView').fire();
            }
            helper.hideSpinner(component);
        });
        $A.enqueueAction(action);
        return true;
    }
})