({
	cancel : function(component, event, helper) {
		component.destroy();
	},
    yesClicked : function(component, event, helper) {
		helper.fireNotificationEvent(component, 'yes - '+component.get('v.varOrigin'), 'matchingProfile');
        component.destroy();
	},
    noClicked : function(component, event, helper) {
		helper.fireNotificationEvent(component, 'no', 'matchingProfile');
        component.destroy();
	}
})