({
    doInit : function(component, event, helper) {
        component.set("v.showPopup",true);  
        helper.getSuffixList(component, event, helper);
        if(component.get('v.fromPortal')) {
            helper.getCurrentDealership(component, event, helper);
            if($A.util.isEmpty(component.get('v.DPMEmployee.Id'))) {
                component.set('v.DPMEmployee.DPM_Record_Origin__c','Portal');
            } 
        } else {
            helper.getDealershipOptions(component, event, helper);
            if($A.util.isEmpty(component.get('v.DPMEmployee.Id'))) {
                component.set('v.DPMEmployee.DPM_Retailer_Admin__c',true);
                component.set('v.DPMEmployee.DPM_Record_Origin__c','Corporate');
            }                
        }     
        if($A.util.isEmpty(component.get('v.DPMEmployee.DPM_Request_Type__c'))) {
            component.set('v.DPMEmployee.DPM_Request_Type__c','Activation');
        } 
    },
    next : function(component, event, helper) {
       // console.log('DPMEmployee:'+JSON.stringify(component.get("v.DPMEmployee")));
        helper.showSpinner(component);       
        if(helper.validateFields(component,event,helper)) { 
            helper.fetchMatchingProfiles(component,event,helper);                   
        } else {
            helper.hideSpinner(component);        
        }
    },
    close : function(component, event, helper) {
        helper.closeModal(component);
    },
    matchingProfileListBackPressed:function(component,event,helper){
       // console.log('matchingProfileListBackPressed success');
        component.set("v.showPopup",true);  
    },
    matchingProfileListCancelPressed:function(component,event,helper){
       // console.log('matchingProfileListCancelPressed success');
        component.destroy(); 
    },
    handleNotificationEvent : function(component, event, helper) {
        let varType = event.getParam("type");
        if(varType == 'alert_styletwo') {
            if(event.getParam("message") == 'cancelClicked') {
                component.find('idAlert').destroy();
                component.set("v.showPopup",true);
            } 
        }
        event.stopPropagation();
    },
})