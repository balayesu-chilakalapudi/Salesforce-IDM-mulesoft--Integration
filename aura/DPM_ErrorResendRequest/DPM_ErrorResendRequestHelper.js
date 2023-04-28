({
	closeQuickAction : function() {
        $A.get("e.force:closeQuickAction").fire();
    },
    showSpinner : function(component) {
        $A.util.removeClass(component.find('idSpinner'),'slds-hide');
    },
    hideSpinner : function(component) {
        $A.util.addClass(component.find('idSpinner'),'slds-hide');
    },
    resendRequest : function(component, event, helper) {
        let resendAction = component.get('c.resendRequestFromLog');
        resendAction.setParams({'logId':component.get('v.recordId')});
        resendAction.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let DPMLogData = response.getReturnValue();
              //  console.log(JSON.stringify(DPMLogData));
                component.set('v.successMessage',DPMLogData.strResponse);
                helper.hideSpinner(component);
            } 
            helper.hideSpinner(component);
        });
        $A.enqueueAction(resendAction);
    },
})