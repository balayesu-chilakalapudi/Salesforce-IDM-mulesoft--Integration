({
	cancel : function(component, event, helper) {
        console.log('cancellll');
		component.destroy();
	},
    submitClicked : function(component, event, helper) {
        let dpmEvent = component.getEvent("dpmNotificationEvt"); 
        dpmEvent.setParams({"message":component.get('v.strSelectedRecordId'),"type":component.get('v.strModalType')});
        dpmEvent.fire();
        component.destroy();
    },
    recordSelected : function(component, event, helper) {
        component.set('v.strSelectedRecordId',event.currentTarget.id);
    },
    okClicked : function(component, event, helper) {
        helper.handleClick(component, event, helper,'okClicked');
    },
    cancelClicked : function(component, event, helper) {
        helper.handleClick(component, event, helper,'cancelClicked');
    },
    yesClicked : function(component, event, helper) {
        helper.handleClick(component, event, helper,'yesClicked');
    },
    backClicked : function(component, event, helper) {
        helper.handleClick(component, event, helper,'backClicked');
    },
    saveClicked : function(component, event, helper) {
        helper.handleClick(component, event, helper,'saveClicked');
    },
    submitClickedNew : function(component, event, helper) {
       helper.handleClick(component, event, helper,'submitClicked');
    },  
    confirmClicked : function(component, event, helper) {
        if(component.get("v.strModalType") =='confirmation_btns_confirm_back'){
            component.set("v.isSupplier",true);
        }
        helper.handleClick(component, event, helper,'confirmClicked');
    } 
})