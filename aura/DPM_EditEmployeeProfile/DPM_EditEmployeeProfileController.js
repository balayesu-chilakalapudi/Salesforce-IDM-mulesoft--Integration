({
	close : function(component, event, helper) {
        helper.closeModal(component);
	},
    save : function(component, event, helper) {
        if(helper.validateRecord(component, event, helper)) {
            if( helper.checkTermination(component, event, helper)) {
                helper.showSpinner(component);
                if(helper.checkMissingSSN(component, event, helper)){
                    if(helper.checkW9Exempt(component, event, helper)){
                        helper.saveRecord(component, event, helper);
                    }
                }
            }
            
        }
    },
    handleNotificationEvent : function(component, event, helper) {
        let varType = event.getParam("type");
        if(varType == 'confirmation_styletwo') {
            if(event.getParam("message") == 'okClicked') {
                if(helper.checkMissingSSN(component, event, helper)){
                    helper.saveRecord(component, event, helper);
                } 
            } else if(event.getParam("message") == 'cancelClicked'){
                helper.closeModal(component);
            } else {
                component.set('v.showNotification',false);
            }
        }
        if(varType == 'confirmation_stylethree') {
            if(event.getParam("message") == 'saveClicked') {
                helper.showSpinner(component);
                helper.saveRecord(component, event, helper);
                //component.set('v.showNotification',false);
            } else {
                component.set('v.showNotification',false);
            }
        }
        if(varType == 'confirmation_btns_confirm_cancel'){
            if(event.getParam("message") == 'confirmClicked') {
                helper.showSpinner(component);
                helper.saveRecord(component, event, helper);
                event.stopPropagation();
            }
            else if(event.getParam("message") == 'cancelClicked'){
                let notificationCmp = component.find('idAlertW9Cancel');
                helper.hideSpinner(component);
                notificationCmp.destroy();
            }
                else {
                    component.set('v.showNotification',false);
                }
        }
        event.stopPropagation();
    },
    handlerCloseEditEmployee:function(component,event,helper){
        component.destroy();
        event.stopPropagation();
    },
    editProfile : function(component,event,helper) {
        component.set('v.mode','edit');
        component.set('v.searchMode','edit');
    },
    handleTerminationDateMsgEvent:function(component,event,helper){
        let editEmployeeParameters = {
            "aura:id":"idEditEmployeeCmp2",
            "personRole":component.get('v.personRole'),
            "account":component.get('v.personRole.RE_Account__r'),
            "contact":component.get('v.personRole.RE_Contact__r'),
            "jobPositions":component.get('v.personRole.DPM_Job_Positions__r'),
            "mode":component.get('v.mode'),
            "isRetailerAdmin":component.get('v.isRetailerAdmin')
        };         
        let strModalBody = event.getParam("strModalBody");    
        let parameters = {"aura:id":"idTerminationDateMessages","strModalBody":strModalBody,"empParams":editEmployeeParameters};
        helper.createModal(component, 'c:DPM_TerminationDateMessages',parameters);
        event.stopPropagation();       
    },
    doInit:function(component,event,helper){
        console.log('doInit running');
        if(!$A.util.isEmpty(component.get('v.personRole.RE_Psn_NonActive_Date__c'))) {
        	component.set("v.isTerminatedEmployee",true);
        }else{
            component.set("v.isTerminatedEmployee",false);
        }
        if(component.get('v.personRole.RE_Contact__r.DPM_W9_Exempt__c')){
            component.set("v.isW9Exempt",true);
        }else{
            component.set("v.isW9Exempt",false);
        }
        //helper.getCurrentPersonRole(component,event,helper);
       // console.log('isTerminatedEmployee:'+component.get("v.isTerminatedEmployee"));
    }
})