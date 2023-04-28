({
	handleUserSelection : function(component, event, helper, blnNew) {
        let cmpEvent = component.getEvent("existingEmpCheckEvent");
        cmpEvent.setParams({
            "isNew" : blnNew 
        });
        cmpEvent.fire();
    },
})