({
    doInit : function(component, event, helper) {
        console.log('mode:'+component.get('v.mode'));
        console.log('isRetailerAdmin:'+component.get("v.isRetailerAdmin"));
        
        console.log('country:'+(component.get('v.personRole.RE_Contact__r.Account_Country__c')));        
        console.log('editDMSId:'+component.get("v.corporatePermissions.editDMSId"));
        console.log('fromPortal:'+component.get("v.fromPortal"));
        if(component.get("v.fromPortal")){
            helper.getCurrentDealership(component,event,helper);
        }
        helper.getCurrentPersonRole(component,event,helper);
        helper.getW9FlagValues(component, event, helper);
        if(component.get('v.mode') != 'view') {
            helper.showSpinner(component);
            helper.getGenderList(component, event, helper);
            helper.getPrefixList(component, event, helper);
            helper.getSuffixList(component, event, helper);
            helper.getStateCountryValues(component, event, helper);
            helper.getProficiencyValues(component, event, helper);
            if(component.get('v.mode') == 'edit') {
                helper.getDiversityDataOptions(component, event, helper);
            }            
        }
        if(component.get('v.mode') == 'admin') {
            helper.getPositionsList(component, event, helper);
        }
        if(component.get('v.personRole.RE_Contact__r.MailingCountry') == 'Canada') {
            component.set('v.SSNBtnLabel','Show SIN');
            component.set('v.corporatePermissions.viewW9',false);
            component.set('v.corporatePermissions.viewW9ForFireFighter',false);
        } else {
            component.set('v.SSNBtnLabel','Show SSN');
        }
        if(component.get('v.personRole.RE_Contact__r.MailingCountry') == 'Mexico') {
            component.set('v.corporatePermissions.viewW9',false);
            component.set('v.corporatePermissions.viewW9ForFireFighter',false);
        }
        if (component.get("v.personRole.RE_Contact__r.RecordType.Name") == "Supplier Employee") {
            component.set("v.IsShowSSNSupplier", false);
            component.set('v.corporatePermissions.viewW9',false);
            component.set('v.corporatePermissions.viewW9ForFireFighter',false);
            if(component.get("v.corporatePermissions.editSuppliers") && component.get("v.corporatePermissions.manageSuppliers")) {
                component.set("v.positionEditable",true);
                component.set("v.homeAddressEditable",true);
            }
        } else {
            if(component.get("v.corporatePermissions.editJobPositions")) {
                component.set("v.positionEditable",true);
            }
            if(component.get("v.corporatePermissions.editPersonalData")) {
                component.set("v.homeAddressEditable",true);
            }
        }
         console.log(JSON.stringify(component.get('v.personRole')));
         console.log('blnEditDMSID:'+component.get("v.blnEditDMSId"));
        
    },    
    addNewPosition : function(component, event, helper) {
        let lstJobPositions = component.get('v.personRole.DPM_Job_Positions__r');
        lstJobPositions.push({DPM_Position_Title__c:'',DPM_Position_Start_Date__c:null,DPM_Position_End_Date__c:null,DPM_Primary_Position__c:false,showPrimary:false});
        component.set('v.personRole.DPM_Job_Positions__r',lstJobPositions);
    },
    checkHireDate : function(component, event, helper) {
        let userSelectedDate = component.find('idHireDate').get('v.value');
        let selecteddate = $A.localizationService.formatDate(userSelectedDate, "yyyy MM dd ");
        var orgActiveDate = component.get("v.personRole.RE_Account__r.Org_activated__c");
        let maxDate = new Date();
        maxDate.setDate(maxDate.getDate() + 60)
        let minDate = new Date();
        minDate.setDate(maxDate.getDate() - 15)
        let blnShowMessage = false;
        //alert(selecteddate < $A.localizationService.formatDate(minDate, "yyyy MM dd ")); //F --T --T
        //alert(selecteddate <$A.localizationService.formatDate(orgActiveDate, "yyyy MM dd ")); //F -- F --T
        //alert(selecteddate >$A.localizationService.formatDate(orgActiveDate, "yyyy MM dd ")); //T  --T --F
        //alert(selecteddate);
        //alert($A.localizationService.formatDate(orgActiveDate, "yyyy MM dd "));
        
        if(selecteddate < $A.localizationService.formatDate(minDate, "yyyy MM dd ") && selecteddate > $A.localizationService.formatDate(orgActiveDate, "yyyy MM dd ")){
            helper.showToast('warning','Hire date more than 15 days ago, please verify the hire date');
            blnShowMessage = true;
        } 
        if(!blnShowMessage && (selecteddate > $A.localizationService.formatDate(maxDate, "yyyy MM dd "))){
            helper.showToast('warning','Hire date more than 2 months ahead, please verify the hire date');
        }
        if(selecteddate < $A.localizationService.formatDate(orgActiveDate, "yyyy MM dd ") && selecteddate < $A.localizationService.formatDate(minDate, "yyyy MM dd ")){
            helper.showToast('error','The Hire date cannot be earlier than the Store activation date. Please change the Hire date');
            helper.showToast('warning','Hire date more than 15 days ago, please verify the hire date');
            blnShowMessage = true;
        }
    },
    addressChange : function(component,event,helper) {
        let changedComponent = event.getSource();
        let changedComponentId = changedComponent.getLocalId();
        helper.checkCustomValidity(component,changedComponentId,changedComponent);
        helper.setStateList(component,changedComponentId);        
    },
    countryChangeHandler : function(component,event,helper) {
        if(component.get('v.mode') == 'edit') {
            helper.clearDiversityData(component);
            helper.setDiversityDataByCountry(component,event,helper);
            helper.clearSSNData(component);
            helper.clearLangData(component,event,helper);
        } 
    },
    checkTerminationDate : function(component,event,helper) {
        if(component.get('v.personRole.RE_Psn_NonActive_Date__c') == component.get('v.personRole.RE_Psn_Active_Date__c')) {
            helper.showToast('warning','Termination date is the same as Hire date. Please verify your entry');
        }
        if($A.localizationService.formatDate(component.get('v.personRole.RE_Psn_NonActive_Date__c'), "yyyy MM dd ") < $A.localizationService.formatDate(component.get('v.personRole.RE_Psn_Active_Date__c'), "yyyy MM dd ")) {
            helper.showToast('error','Termination date is earlier than the Hire date. Please verify your entry');
        }
        //8/Feb/2021, Temination date messages
        let terminationdate=$A.localizationService.formatDate(component.get('v.personRole.RE_Psn_NonActive_Date__c'), "yyyy MM dd ");
        let todaydate = $A.localizationService.formatDate(new Date(), "yyyy MM dd ");
        let personRole=component.get("v.personRole");
        let employeeName=personRole.RE_Contact__r.FirstName+' '+personRole.RE_Contact__r.LastName;
        let storeName=personRole.RE_Account__r.Name;
        let message='';
        if(terminationdate > todaydate){
            //future date given
            message=employeeName+' will not have access to Volvo Cars Portal or any Volvo applications '+
                'for '+storeName+' starting on '+$A.localizationService.formatDate(terminationdate, "MM/dd/yyyy")+'. If '+employeeName+' will be working that day, '+
                'please set the following day as the termination date.';
            helper.viewTerminationMessageModal(component,event,helper,message);
        }
        else if(terminationdate <= todaydate){
            // today's date given
            message=employeeName+' will lose access to the Volvo Cars Portal and all Volvo applications for '+
                storeName+' immediately. If '+employeeName+' needs access today, please set tomorrow as the termination date.';
            helper.viewTerminationMessageModal(component,event,helper,message);  
        }
        var enddate = component.get('v.personRole.RE_Psn_NonActive_Date__c');
        // get the returned list of records and put in a new variable
        var myList = component.get('v.personRole.DPM_Job_Positions__r');
        
        // check to make sure the list isn't null
        if (myList != null) {
            // get the length of the list (in this case number of rows/records)
            var listLength = myList.length;
            // loop through the list of records and stop once you are at the list length
            for (var i=0; i < listLength; i++) {
                myList[i].DPM_Position_End_Date__c = enddate;
            }
            component.set('v.personRole.DPM_Job_Positions__r',myList);
        }
    },
    checkW9Date : function(component, event, helper) {
        let w9date=$A.localizationService.formatDate(component.get('v.personRole.RE_Contact__r.DPM_W9_Date__c'), "yyyy MM dd ");
        let todaydate = $A.localizationService.formatDate(new Date(), "yyyy MM dd ");
        
        var result = new Date();
        result.setDate(result.getDate() - 14);
        var priordate = $A.localizationService.formatDate(result, "yyyy MM dd ");
        
        var tomorror = new Date();
        tomorror.setDate(tomorror.getDate() + 1);
        var futureDate = $A.localizationService.formatDate(tomorror, "yyyy MM dd ");
        
        console.log('w9date'+w9date);
        console.log('priordate'+priordate);
        console.log('futureDate'+futureDate);
        
        var strtoday = new Date();
        strtoday.setDate(strtoday.getDate());
        var w9MaxDate = $A.localizationService.formatDate(strtoday, "yyyy-MM-dd ");
        component.set("v.w9MaxDate",w9MaxDate);
        let message='';
        if(w9date < priordate){
            //message='You have entered a W9 Date prior to two weeks from today, please confirm you want to proceed with this W9 Date';
            //helper.viewTerminationMessageModal(component,event,helper,message);
            let varBody="You have entered a W9 Date prior to two weeks from today, please confirm you want to proceed with this W9 Date";
            let parameters = {"aura:id":"idAlertSupplierCancel",
                              "strModalHeader":"Confirmation",
                              "strModalBody":varBody,
                              "strModalType":"confirmation_btns_confirm_W9"};
            helper.createModal(component,'c:DPM_NotificationModal',parameters); 
        }
    },
    showHideSSN : function(component, event, helper) {
        let country = component.get('v.personRole.RE_Contact__r.MailingCountry');
        if(country == 'Canada') {
            if(component.get('v.showSSN')) {
                component.set('v.SSNBtnLabel','Show SIN');
            } else {
                component.set('v.SSNBtnLabel','Hide SIN');
            }            
        } else {
            if(component.get('v.showSSN')) {
                component.set('v.SSNBtnLabel','Show SSN');
            } else {
                component.set('v.SSNBtnLabel','Hide SSN');
            } 
        }
        component.set('v.showSSN',!component.get('v.showSSN'));
    },
    modeChangeHandler : function(component, event, helper) {
        if(component.get('v.mode') != 'view') {
            helper.getGenderList(component, event, helper);
            helper.getPrefixList(component, event, helper);
            helper.getSuffixList(component, event, helper);
            helper.getStateCountryValues(component, event, helper);
            helper.getPositionsList(component, event, helper);
            helper.getAccounts(component,event,helper);
            helper.getProficiencyValues(component, event, helper);
            if(component.get('v.mode') != 'admin') {
                helper.getDiversityDataOptions(component, event, helper);
            } 
        }
    },
    ownerCheck : function(component, event, helper) {
        if(!component.get('v.personRole.DPM_Owner__c')) {
            let alertBody = 'You are about to remove the Ownership status of this person for this store.  Please confirm that you want to proceed with this action.';
            let parameters = {"aura:id":"idAlertModal","strModalHeader":"Owner Unchecked Confirmation","strModalBody":alertBody,"strModalType":"confirmation_styletwo"};
            helper.createNewComponent(component, event, helper,'c:DPM_NotificationModal',parameters);
        }
    },
    handleNotificationEvent : function(component, event, helper) {        
        let varType = event.getParam("type");
        if(varType == 'confirmation_styletwo') {
            let notificationCmp = component.find('idAlertModal');
            if(event.getParam("message") == 'okClicked') {   
                notificationCmp.destroy();                
            } else {
                component.set('v.personRole.DPM_Owner__c',true)
                notificationCmp.destroy();
            }
        }
        if(varType == 'confirmation_btns_confirm_W9') {
            let notificationCmp = component.find('idAlertSupplierCancel');
            if(event.getParam("message") == 'confirmClicked') {
                notificationCmp.destroy();
            }
            else {                
                notificationCmp.destroy();
            }
        }
        event.stopPropagation();
    },
    handleWorkAddress : function(component, event, helper) {
        if(component.get('v.personRole.DPM_Work_Address_Same_as_Store_Address__c')) {
            //alert(component.get('v.personRole.DPM_Work_Address_Same_as_Store_Address__c'));
            component.set('v.personRole.DPM_Work_Address_Country__c',component.get('v.personRole.RE_Account__r.BillingCountry'));
            let changedComponentId = 'idWorkAddress';
            helper.setStateList(component,changedComponentId);
            component.set('v.personRole.DPM_Work_Address_Street__c',component.get('v.personRole.RE_Account__r.BillingStreet'));
            component.set('v.personRole.DPM_Work_Address_City__c',component.get('v.personRole.RE_Account__r.BillingCity'));
            component.set('v.personRole.DPM_Work_Address_Zip_Postal_Code__c',component.get('v.personRole.RE_Account__r.BillingPostalCode'));
            component.set('v.personRole.DPM_Work_Address_State__c',component.get('v.personRole.RE_Account__r.BillingState'));
        }
    },
})