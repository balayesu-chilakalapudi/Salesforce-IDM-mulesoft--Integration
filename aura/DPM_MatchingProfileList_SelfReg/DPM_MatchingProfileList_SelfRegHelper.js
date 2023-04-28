({
	fireNotificationEvent : function(component,message,type) {
		let dpmEvent = component.getEvent("dpmNotificationEvt"); 
        dpmEvent.setParams({"message":message,"type":type});
        dpmEvent.fire();
	}
})