({
    doInit : function(component, event, helper) {  
        if($A.util.isEmpty(component.get('v.DPMEmployee.DPM_Gender__c'))){
            component.set('v.isGenderDisable', true);
        }
        if($A.util.isEmpty(component.get('v.DPMEmployee.DPM_Prefix__c'))) {
            component.set('v.isPrefixDisable', true);
        }
        if(($A.util.isEmpty(component.get('v.DPMEmployee.DPM_Other_Gender__c')) && !component.get('v.fromPortal') )|| (component.get('v.DPMEmployee.DPM_Gender__c') =='Non-binary' && component.get('v.fromPortal'))) {
            component.set('v.isOtherGenderDisable', true);
        }
        component.set("v.showPopup",true);
        helper.showSpinner(component);
        helper.getGenderList(component, event, helper);
        helper.getPrefixList(component, event, helper);
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
            helper.getPositionsList(component, event, helper);                
        }
       
        if(component.get('v.strActivationType') == '') {
            component.set('v.blnDuplicateCheckRequired',true);
        }
        if(!component.get('v.blnReadOnly')) {
            helper.setJobPositions(component, event, helper);
        }   
        if(!$A.util.isEmpty(component.get('v.DPMEmployee.DPM_Status__c')) 
           && (component.get('v.DPMEmployee.DPM_Status__c')).includes('Submitted')) {
            component.set('v.strStatus','Submitted');
        } else {
            component.set('v.strStatus',component.get('v.DPMEmployee.DPM_Status__c'));
        }
        if($A.util.isEmpty(component.get('v.DPMEmployee.DPM_Request_Type__c'))) {
            component.set('v.DPMEmployee.DPM_Request_Type__c','New');
        } else {
            if(component.get('v.DPMEmployee.DPM_Request_Type__c') != 'New') {
                component.set('v.strActivationType',component.get('v.DPMEmployee.DPM_Request_Type__c')); 
            }            
        }    
        component.set('v.lastHireDate',helper.getMaxHireDate());
        console.log('status-->'+component.get('v.strStatus'));
        
        if(component.get("v.IsSupplier")){
            component.set('v.DPMEmployee.DPM_Retailer_Admin__c', false);
        }
    },
    
    submit : function(component, event, helper) {
        helper.showSpinner(component);
        if(helper.validateFields(component,event,helper)) {            
            let varfromPortal=component.get("v.fromPortal");
            if(varfromPortal){//updated By Gaurav for userstory 1873167
                try{
                    //check for duplicate requests
                    let dpmEmployee=component.get("v.DPMEmployee");
                    let varDupDPMEmployee=null;
                    let varmapDPMEmployee=component.get("v.mapDPMEmployee");
                    let lstExistingEmployeesDB=[];
                    if(varmapDPMEmployee!=null){
                        let lstInitiated=varmapDPMEmployee.initiated;
                        let lstSubmitted=varmapDPMEmployee.submitted;       
                        //add initiated and submitted to a single list               
                        if(lstInitiated!=null){
                            lstExistingEmployeesDB=lstExistingEmployeesDB.concat(lstInitiated);
                        }
                        if(lstSubmitted!=null){
                            lstExistingEmployeesDB=lstExistingEmployeesDB.concat(lstSubmitted);
                        }
                    } 
                    if(lstExistingEmployeesDB!=null && 
                       lstExistingEmployeesDB.length>0){
                        for(let existingEmployee of lstExistingEmployeesDB){
                            if((dpmEmployee.DPM_Legal_First_Name__c==existingEmployee.DPM_Legal_First_Name__c &&
                                dpmEmployee.DPM_Last_Name__c==existingEmployee.DPM_Last_Name__c) ||
                               dpmEmployee.DPM_Email__c==existingEmployee.DPM_Email__c 
                              ){                    
                                varDupDPMEmployee=existingEmployee;
                                break;
                            }
                        }
                    }
                    if(varDupDPMEmployee==null){
                        if(component.get('v.blnDuplicateCheckRequired')) {
                            helper.duplicateCheckRecord(component, event, helper, 'admin');
                        } else {
                            helper.submitRecord(component, event, helper);
                        }
                    }else{                
                        if(varDupDPMEmployee.DPM_Legal_First_Name__c==null){
                            varDupDPMEmployee.DPM_Legal_First_Name__c='';
                        }
                        if(varDupDPMEmployee.DPM_Last_Name__c==null){
                            varDupDPMEmployee.DPM_Last_Name__c='';
                        }
                        if(varDupDPMEmployee.DPM_Email__c==null){
                            varDupDPMEmployee.DPM_Email__c='';
                        }
                        let alertBody = 'This request for '+varDupDPMEmployee.DPM_Legal_First_Name__c+' '+
                            varDupDPMEmployee.DPM_Last_Name__c+', '+varDupDPMEmployee.DPM_Email__c+
                            ' already exists in your store. Please confirm if you want to submit your request, or cancel';                       
                        let parameters = {"aura:id":"idAlertModal","strModalHeader":"Duplicate Request","strModalBody":alertBody,
                                          "strModalType":"confirmation_stylefour"}; //, "strModalType":"duplicate"
                        helper.createNewComponent(component, event, helper,'c:DPM_NotificationModal',parameters);
                    }
                }catch(err){
                    console.log('Exception:'+err.stack);
                }
            } else {
                if(component.get('v.blnDuplicateCheckRequired')) {
                    if(component.get('v.IsSupplier')){
                        helper.duplicateCheckOnApproval(component, event, helper,component.get('v.IsSupplier'));
                    }else{
                        helper.duplicateCheckRecord(component, event, helper, 'admin');
                    }
                } else {
                    helper.submitRecord(component, event, helper);
                }
            }            
        } else {
            helper.hideSpinner(component);
        }
    },
    close : function(component, event, helper) {
        helper.closeModalSupplier(component,helper);
    },
    save : function(component, event, helper) {
        helper.showSpinner(component);
        if(helper.validateFields(component,event,helper)) {
            helper.saveDPMRecord(component, event, helper);
        }
        else {
            helper.hideSpinner(component);
        }
    },
    approve : function(component, event, helper) {       
        helper.showSpinner(component);
        if(helper.validateFields(component,event,helper)) {           
            helper.approveDPMRecord(component, event, helper);
        }
        else {
            helper.hideSpinner(component);
        }       
    },
    checkDateInput : function(component, event, helper) {
        helper.hireDateInput(component,event);
    },
    capitalizeInput : function(component,event,helper) {
        let strText = event.getSource().get("v.value");
        if(!$A.util.isEmpty(strText)) {
            event.getSource().set("v.value",helper.capitalize(strText));
        }        
    },
    addNewPosition : function(component,event,helper) {
        let varDPMJobPositions = component.get('v.DPMJobPositions');
        component.set('v.DPMJobPositions',helper.addJobPosition(varDPMJobPositions));
    },
    ownerSelected : function(component,event,helper) {
        if(!component.get('v.DPMEmployee.DPM_Owner__c')) {
            component.set('v.DPMEmployee.DPM_Owner_Title__c','');
        }
    },
    backToNewEmployee : function(component,event,helper) {
        component.set('v.blnShowDuplicatePopup',false);
        //#1857927,  7/Jan/2021, Balayesu Chilakalapudi   
        // Show Confirm Button     
        component.set("v.blnConfirmedBtn",false);
        component.set("v.blnDupeEmailMatch",false);                                
    },
    reactivateEmployee : function(component,event,helper) {
        //#1857927,  7/Jan/2021, Balayesu Chilakalapudi  
        component.set('v.blnShowDuplicatePopup',false);
        component.set("v.showPopup",false);        
        let DPMEmployee=component.get("v.DPMEmployee");
        var reactivateEvt=component.getEvent("reactivationDPMEvent");
        reactivateEvt.setParams({"DPMEmployee":DPMEmployee});
        reactivateEvt.fire();
        component.destroy();
    },
    createNewEmployee : function(component,event,helper) {
        helper.showSpinner(component);
        component.set('v.blnShowDuplicatePopup',false);
        if(helper.validateFields(component,event,helper)) {
            helper.submitRecord(component, event, helper);
        } else {
            helper.hideSpinner(component);
        }        
    },
    deleteRecord : function(component,event,helper) {
        let varBody = '';
        if(component.get('v.strStatus') != 'Submitted' && component.get('v.DPMEmployee.CreatedById') != component.get('v.DPMEmployee.LastModifiedById')) {
            varBody = 'Self-Registration by employee is in process for this request. Are you sure you want to delete this record permanently?';
        } else {
            varBody = 'Are you sure you want to delete this record permanently?';
        }
        let parameters = {"aura:id":"idAlert",
                          "strModalHeader":"Delete Confirmation",
                          "strModalBody":varBody,
                          "strModalType":"confirmation"};
        helper.createModal(component,'c:DPM_NotificationModal',parameters);
    },
    handleNotificationEvent : function(component,event,helper) {
        let varType = event.getParam("type");
        if(!component.get('v.IsSupplier') && varType == 'confirmation') {
            if(event.getParam("message") == 'yesClicked') {
                component.find('idAlert').destroy();
                helper.deleteRetEmpRecord(component,event,helper);
            } else {
                component.find('idAlert').destroy();
            }
        }
        if(varType == 'confirmation_stylefour') {
            if(event.getParam("message") == 'submitClicked') {
                if(component.get('v.blnDuplicateCheckRequired')) {
                    helper.duplicateCheckRecord(component, event, helper, 'admin');
                } else {
                    helper.submitRecord(component, event, helper);
                }
                component.find('idAlertModal').destroy();
            } else if(event.getParam("message") == 'cancelClicked') {                
                component.find('idAlertModal').destroy();
                helper.hideSpinner(component);
            }
        }  
        if(varType == 'confirmation_styletwo') {
            if(event.getParam("message") == 'okClicked') {
                //name match
                helper.saveRecordToDB(component, event, helper, 'Pending Corporate Approval');
                helper.refreshDPM(component);
                component.destroy();
            }
            else if(event.getParam("message") == 'cancelClicked') {                
                component.find('idAlert').destroy();
                helper.hideSpinner(component);
            }
        }// updated by gaurav for supplier employee creation us: 2614342 
        if(component.get('v.IsSupplier') && varType == 'confirmation_btns_confirm_back') {
            if(event.getParam("message") == 'confirmClicked') {
                helper.saveRecordToDB(component, event, helper, 'Approved');
            }
            else if(event.getParam("message") == 'backClicked') {                
                component.find('idAlertSupplier').destroy();
                helper.hideSpinner(component);
            }
            else if(event.getParam("message") == 'cancelClicked') {                
                component.find('idAlertSupplier').destroy();
                helper.hideSpinner(component);
            }
        }
        if(component.get('v.IsSupplier') && varType == 'confirmation') {
            if(event.getParam("message") == 'yesClicked') {
                component.destroy();
            } else {
                component.find('idAlertSupplierCancel').destroy();
            }
            
        }
        event.stopPropagation();
    },
    backToMatchingProfiles : function(component,event,helper) {
        //  console.log('asdback');
        let parameters = {"aura:id":"idMatchingProfileList","fromPortal":component.get('v.fromPortal'),"profileList":component.get('v.profileList'),"dpmEmployee":component.get('v.DPMEmployee'),"account":component.get('v.account'),"mapDPMEmployee":component.get("v.mapDPMEmployee")};
        let dpmNextEvent = component.getEvent("nextModalEvent"); 
        dpmNextEvent.setParams({"blnNext":true,"modalName":"c:DPM_MatchingProfileList","modalParams":JSON.stringify(parameters)});
        dpmNextEvent.fire();
        component.destroy();
    },
    //#1857927,  7/Jan/2021, Balayesu Chilakalapudi
    confirmedBtn:function(component,event,helper){
        //hide Confirm Button
        component.set("v.blnConfirmedBtn",true);
    },    
    //Used to store Dealership
    selecteDealership : function(component,event,helper){
        try{            
        	var dealershipsList = component.get('v.storeAllDealershipsList');
        	var selectedDealershipId = component.find('idAccount').get("v.value");
        	if(!$A.util.isUndefinedOrNull(dealershipsList) && !$A.util.isEmpty(dealershipsList) && !$A.util.isUndefinedOrNull(selectedDealershipId))
                for(let dealership of dealershipsList) 
                    if(dealership.Id === selectedDealershipId && !$A.util.isUndefinedOrNull(dealership.Org_activated__c)){
                        component.set("v.storeDealership",dealership); 
                        break;
                    }                      
        }catch(ex){
            console.log('Error Message>>>>> '+ex.message);
        }
         //reset jobpositions after store change
         helper.getPositionsList(component, event, helper);
    },
    countryChanged : function(component, event, helper) {        
        helper.setStateList(component);
        var inpcity=component.find("citySup");
        inpcity.reportValidity();
        var inpPhone=component.find("cellphoneSup");
        inpPhone.reportValidity();
        var inpAddress=component.find("addressSup");
        inpAddress.reportValidity();
    },
    
   
})