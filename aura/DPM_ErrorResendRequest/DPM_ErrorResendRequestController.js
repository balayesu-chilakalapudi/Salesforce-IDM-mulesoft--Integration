({
	handleCancel : function(component, event, helper) {
        helper.closeQuickAction();
    },
    doInit : function(component, event, helper) {
        helper.showSpinner(component);
        component.set('v.successMessage','Do you want to send this request again?');
    },
    handleReSend : function(component, event, helper) {
        helper.showSpinner(component);
        helper.resendRequest(component, event, helper);
    },
})