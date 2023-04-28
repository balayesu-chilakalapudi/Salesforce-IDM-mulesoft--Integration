({
	cancelClicked : function(component, event, helper) {
		component.destroy();
	},
    okayClicked : function(component, event, helper) {
        let dpmEvent = component.getEvent("dpmToastEvt"); 
        dpmEvent.setParams({"message":"ok","type":component.get('v.strPromptType')});
        dpmEvent.fire();
        component.destroy();
    },
})