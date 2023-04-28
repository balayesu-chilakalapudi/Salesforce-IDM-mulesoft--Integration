({
	next : function(component,event,helper){
        helper.viewEditEmployeeModal(component, event, helper);
    },
    back : function(component,event,helper){
       // console.log('asd '+component.get('v.dpmEmployee'));
        let parameters = {"aura:id":"idReactivateExtendEmployeeCmp","fromPortal":component.get('v.fromPortal'),"DPMEmployee":component.get('v.dpmEmployee')};
        let dpmNextEvent = component.getEvent("nextModalEvent"); 
        dpmNextEvent.setParams({"blnNext":true,"modalName":"c:DPM_ReactivateExtendRetailerEmployee","modalParams":JSON.stringify(parameters)});
        dpmNextEvent.fire();
        component.destroy();        
    },
    cancel : function(component) {
        component.set('v.blnConfirmCancel',true);
        component.set('v.showPopup',false);
        component.set('v.strModalHeader','Cancel Confirmation');
        component.set('v.strModalBody','You will lose your data. Do you confirm you want to cancel this action?');
        component.set('v.strModalType','confirmation');
    }, 
    handleNotificationEvent : function(component,event,helper) {
        let varType = event.getParam("type");
        if(varType == 'confirmation') {
            if(event.getParam("message") == 'yesClicked') {
                let cmpEvent = component.getEvent("DPM_MatchingProfileListCancelEvent");  
                cmpEvent.fire();
                component.destroy();
            } else {
                component.set("v.blnConfirmCancel",false);  
                component.set("v.showPopup",true);
            }
        }
    },
    rowSelected : function(component,event,helper){
        let profileId = event.target.id;
        let selected = document.getElementById(profileId).checked;
        if(selected && helper.checkIfSelectionIsValid(component,event,helper,profileId)) {
        	component.set('v.selectedProfile',profileId);            
        } else {
            component.set('v.selectedProfile','');
            helper.showToast('warning','This employee is already active in your store, please correct your data or select another employee.');
        }
    }
})