({
    getGenderList : function(component, event, helper) {
        helper.getPicklistValuesFromDPM(component, helper, 'DPM_Gender__c');
    },
    getPrefixList : function(component, event, helper) {
        helper.getPicklistValuesFromDPM(component, helper, 'DPM_Prefix__c');
    },
    getSuffixList : function(component, event, helper) {
        helper.getPicklistValuesFromDPM(component, helper, 'DPM_Suffix__c');
    },
    getPositionsList : function(component, event, helper) {
        helper.getPicklistValuesForPositions(component, helper);
        helper.getStateCountryValues(component, event, helper);
    },
    getStateCountryValues : function(component, event, helper) {
        let countryStatesAction = component.get('c.getCountriesAndStates');
        countryStatesAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let varMapCountryStates = response.getReturnValue();
                let lstCountries = ['--None--'];
                let varMapCountryToStateOptions = new Map();
                for(let varCountry of Object.keys(varMapCountryStates)) {
                    lstCountries.push(varCountry);
                    varMapCountryToStateOptions[varCountry] = helper.generatePicklistOptions(varMapCountryStates[varCountry],true);
                }
                component.set('v.countryList',helper.generatePicklistOptions(lstCountries));
                component.set('v.mapCountryWithStates',varMapCountryToStateOptions);
                if(component.get("v.IsSupplier")){
                  component.set('v.DPMEmployee.DPM_Country__c','United States');   
                }
                helper.setStateList(component);
            }
        });
        $A.enqueueAction(countryStatesAction);
    },
    setStateList : function(component) {
        let varMapCountryToStateOptions = component.get('v.mapCountryWithStates');
        if($A.util.isEmpty(component.get('v.DPMEmployee.DPM_Country__c'))) {
            let states = [{
                    text:'--None--',
                    value:''
                }];
            states = states.concat(varMapCountryToStateOptions['United States']);
            component.set('v.statesList',states);
            //component.set('v.statesList',[]);
        } else {
            let states = [{
                    text:'--None--',
                    value:''
                }];
            states = states.concat(varMapCountryToStateOptions[component.get('v.DPMEmployee.DPM_Country__c')]);
            component.set('v.statesList',states);
        }
    },
    getCurrentDealership : function(component, event, helper) {
        var accountAction = component.get("c.getCurrentAccount");
        accountAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let currentAccount = response.getReturnValue();
                component.set('v.account',currentAccount);
                component.set('v.DPMEmployee.DPM_Account__c',currentAccount.Id);               
                helper.hideSpinner(component);
                helper.getPositionsList(component, event, helper);                
            }
        });
        $A.enqueueAction(accountAction);
    },
    getPicklistValuesFromDPM : function(component, helper, strAPIName) {
        var initAction = component.get('c.getPicklistValues');
        initAction.setParams({strFieldName:strAPIName});
        initAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let picklistValues = response.getReturnValue();
                switch(strAPIName) {
                    case 'DPM_Gender__c':
                        component.set('v.genderList',helper.generatePicklistOptions(picklistValues));
                        break;
                    case 'DPM_Prefix__c':
                        component.set('v.prefixList',helper.generatePicklistOptions(picklistValues));
                        break;
                    case 'DPM_Suffix__c':
                        component.set('v.suffixList',helper.generatePicklistOptions(picklistValues));
                        break;
                    default:
                        break;
                }
            }
        });
        $A.enqueueAction(initAction);
    },
    approveDPMRecord : function(component, event, helper) {
        helper.duplicateCheckOnApproval(component, event, helper,component.get('v.IsSupplier'));
    },
    saveDPMRecord : function(component, event, helper) {
        helper.saveRecordToDB(component, event, helper, 'Save');
    },
    submitRecord : function(component, event, helper) {
        var showValue=component.get("v.isOpen");
        component.set("v.isOpen",true);
        helper.saveRecordToDB(component, event, helper, 'Initiated');
    },
    //DupCheck Record
    duplicateCheckRecord : function(component, event, helper, varOrigin) {
        let dupCheckAction = component.get("c.duplicateCheck");
        let varDPMEmployee = component.get('v.DPMEmployee');
        delete varDPMEmployee['DPM_Job_Positions__r'];
        delete varDPMEmployee['DPM_Account__r'];
        dupCheckAction.setParams({strDPMEmployee:JSON.stringify(varDPMEmployee)});
        dupCheckAction.setCallback(this,function(response) {
            var state=response.getState();            
            if(state==='SUCCESS') {
                let retValue = response.getReturnValue();
                if(varOrigin!='admin'){
                    // employee initiates
                    component.set('v.blnShowDuplicatePopup',false);
                    helper.submitRecord(component, event, helper);
                } else {
                    // admin initiates
                    //check if email matches
                    let lstDuplicateRecords=retValue; 
                    let dpmemail=varDPMEmployee.DPM_Email__c;
                    //show dup popup
                    if(lstDuplicateRecords.length > 0) {
                        let blnEmailMatched = false;
                        let varMatchingFields = '';
                        for(let matchingRecord of lstDuplicateRecords) {
                            if(matchingRecord.RE_Psn_Active__c && (dpmemail == matchingRecord.DPM_Work_Email__c || dpmemail == matchingRecord.RE_Contact__r.Email)){
                                //email matching and record active
                                blnEmailMatched = true;                                
                                break;
                            } else {
                                if(varDPMEmployee.DPM_Last_Name__c == matchingRecord.RE_Contact__r.LastName 
                                   && varDPMEmployee.DPM_Legal_First_Name__c == matchingRecord.RE_Contact__r.FirstName
                                   && ($A.util.isEmpty(varDPMEmployee.DPM_Suffix__c) || varDPMEmployee.DPM_Suffix__c == matchingRecord.RE_Contact__r.Suffix)
                                   && $A.util.isEmpty(varMatchingFields)) {
                                    varMatchingFields = 'Last Name, First Name, Suffix';
                                } else if(varDPMEmployee.DPM_Last_Name__c == matchingRecord.RE_Contact__r.LastName 
                                          && varDPMEmployee.DPM_Preferred_First_Name__c == matchingRecord.RE_Contact__r.DPM_Preferred_First_Name__c
                                          && ($A.util.isEmpty(varDPMEmployee.DPM_Suffix__c) || varDPMEmployee.DPM_Suffix__c == matchingRecord.RE_Contact__r.Suffix)
                                          && !$A.util.isEmpty(varDPMEmployee.DPM_Preferred_First_Name__c)
                                          && $A.util.isEmpty(varMatchingFields)) {
                                    varMatchingFields = 'Last Name, Preferred First Name, Suffix';
                                }
                            }
                        }
                        if(blnEmailMatched) {
                            component.set('v.strMatchingFields_DupCheck','This email is in our records. If you confirm the email, you can only reactivate that employee.');
                        } else {
                            component.set('v.strMatchingFields_DupCheck','Our records indicate that a person with the same name already exists in our system. Please correct the field '+varMatchingFields+', or select the "Reactivate Employee" option.');
                        }                        
                        component.set('v.blnDupeEmailMatch',blnEmailMatched);
                        component.set('v.blnShowDuplicatePopup',true);
                    } else {
                        //no record matches
                        component.set('v.blnShowDuplicatePopup',false);
                        helper.submitRecord(component, event, helper);                                                
                    }
                }
                helper.hideSpinner(component);
            } else {
                let errors = response.getError();
                let message = 'Unknown error'; // Default error message
                // Retrieve the error message sent by the server
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                // Display the message
                helper.showToast('error',message);
                helper.hideSpinner(component);
            }             
        });
        $A.enqueueAction(dupCheckAction);
    },
    saveRecordToDB : function(component, event, helper, type) {
        let varDPMEmployee = component.get('v.DPMEmployee');
        var submitAction = component.get('c.submitDPMRecord');
        //Remove related lists (parent and child)
        delete varDPMEmployee['DPM_Job_Positions__r'];
        delete varDPMEmployee['DPM_Account__r'];
        console.log('json123$ '+JSON.stringify(component.get('v.DPMEmployee')));
        if(type == 'Initiated' && !component.get('v.IsSupplier')) {
            submitAction.setParams({strDPMEmployee:JSON.stringify(component.get('v.DPMEmployee')),strDPMJobPositions:JSON.stringify(component.get('v.DPMJobPositions')),strType:type});
        } else if(!component.get('v.IsSupplier') && (type == 'Approved' || type == 'Pending Corporate Approval')) {
            submitAction.setParams({strDPMEmployee:JSON.stringify(varDPMEmployee),strDPMJobPositions:JSON.stringify(component.get('v.DPMJobPositions')),strType:type});
        } else if(type == 'Save') {
            submitAction.setParams({strDPMEmployee:JSON.stringify(varDPMEmployee),strDPMJobPositions:JSON.stringify(component.get('v.DPMJobPositions')),strType:type});
        }
        else if(type == 'Approved' && component.get('v.IsSupplier')){
            var varSupplier = component.get('v.DPMEmployee');
            varSupplier.DPM_Employee_Type__c = 'Supplier';
            varSupplier.DPM_Request_Type__c = 'New';
            console.log('varSupplier=-=-',varSupplier);
            submitAction.setParams({strDPMEmployee:JSON.stringify(component.get('v.DPMEmployee')),strDPMJobPositions:JSON.stringify(component.get('v.DPMJobPositions')),strType:type});
        }
        submitAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                if(type == 'Approved') {
                    helper.showSpinner(component);
                    helper.showMessage(component, event, helper);
                } 
                else if(type == 'Initiated'){
                    helper.showToast('success','New profile was submitted successfully');  //Data was saved successfully., 
                }
                    else if(type=='Save') {
                        helper.showToast('success','The information is saved. Do not forget to approve the profile');  //Data was saved successfully., New profile was submitted successfully
                    }                
                helper.hideSpinner(component);
                helper.refreshDPM(component);
                helper.closeModal(component);                
            } else {
                let errors = response.getError();
                let message = $A.get("$Label.c.DPM_System_Error"); // Default error message
                // Retrieve the error message sent by the server
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    let systemErrorMessage = errors[0].message;
                    helper.generateDPMLog(component, event, helper,varDPMEmployee.DPM_Account__c,systemErrorMessage);
                }
                // Display the message
                helper.showToast('error',message);
                helper.hideSpinner(component);
            }  
        });
        $A.enqueueAction(submitAction);
    },
    
    //updated By Gaurav for userstory 1873167
    createNewComponent : function(component, event, helper, componentName, parameters) {
        $A.createComponent(componentName, parameters, function(modal, status, errorMessage) {
            if (status === 'SUCCESS') {
                var body = component.get('v.body');
                body.push(modal);
                component.set('v.body', body);
            } else if (status === "INCOMPLETE") {
                console.warn("No response from server or client is offline.")
            } else if (status === "ERROR") {
                console.error("Error: " + errorMessage);
            }
        });
    },
    getPicklistValuesForPositions : function(component, helper) {
        let IdAccount=null;
        //get accountId based on portal/corporate
        try{
        if(component.get("v.fromPortal")){
            IdAccount=component.get("v.account").Id;
        }else{
            IdAccount=component.get("v.DPMEmployee").DPM_Account__c;
        }
    }catch(err){
        console.log(err.stack);
    }
       // console.log('IdAccount:'+IdAccount);
        var initPositionAction = component.get('c.getAllJobPositions');
        let params={'retailer_storeId':IdAccount};
        console.log('params:'+JSON.stringify(params));
        initPositionAction.setParams(params);
        initPositionAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let varAllJobPositions = response.getReturnValue();
                let varJobPositions = ['--None--'];
                let varPrimaryPositions = [];
                let varOwnerPositions = ['--None--'];
                for(let jobPosition of varAllJobPositions) {					
                    if(jobPosition.DPM_Primary_Position__c) {
                        varPrimaryPositions.push(jobPosition.MasterLabel);
                    }
                    if(jobPosition.DPM_Owner_Position__c) {
                        varOwnerPositions.push(jobPosition.MasterLabel);
                    } else {
                        varJobPositions.push(jobPosition.MasterLabel);
                    }
                }
                component.set('v.positionsList',helper.generatePicklistOptions(varJobPositions));
               
                //check if positionsList contains all employee positions, else add it to prevent country filter              
                /*let DPMJobPositions=component.get("v.DPMJobPositions"); 
                let positionsList=component.get("v.positionsList");  
                for(let position of DPMJobPositions){
                    if(position.Name!=null && position.Name!='' && positionsList.includes({'text':position.Name,'value':position.Name})){                        
                        positionsList.remove({'text':position.Name,'value':position.Name});
                    }
                }
                component.set("v.positionsList",positionsList);*/
                component.set('v.primaryPositionsList',varPrimaryPositions);
                component.set('v.ownerPositionsList',helper.generatePicklistOptions(varOwnerPositions));
            }
        });
        $A.enqueueAction(initPositionAction);
    },
    showToast : function(type,message) {
        let toastEvent = $A.get("e.force:showToast");
        let title = (type=='error'?'Error!':(type=='success'?'Success!':'Warning!'));
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type":type,
            "duration":10000
        });
        toastEvent.fire();        
    },
    showSpinner : function(component) {
        $A.util.removeClass(component.find('idSpinner'),'slds-hide');
    },
    hideSpinner : function(component) {
        $A.util.addClass(component.find('idSpinner'),'slds-hide');
    },
    closeModalSupplier : function(component,helper) {
        if(!component.get('v.blnReadOnly') && component.get('v.IsSupplier')){// updated by gaurav for supplier employee creation us: 2614342 
            let varBody="Are you sure you want to cancel this employee creation?";
            let parameters = {"aura:id":"idAlertSupplierCancel",
                              "strModalHeader":"Confirmation",
                              "strModalBody":varBody,
                              "strModalType":"confirmation"};
            helper.createModal(component,'c:DPM_NotificationModal',parameters); 
        }else{
            component.destroy();
        }
        
    }, 
    closeModal : function(component,helper) {
        component.destroy();
    },
    generatePicklistOptions : function(lstPicklistValues) {
        let picklistOptions = [];
        for(let picklistValue of lstPicklistValues) {
            picklistOptions.push(
                {
                    text:picklistValue,
                    value:(picklistValue=='--None--'?'':picklistValue)
                }
            );
        }
        return picklistOptions;
    },
    capitalize : function(strText) {
        return strText.charAt(0).toUpperCase() + strText.slice(1);
    },
    showMessage:function(component,event,helper){
        var dpmEmpFN = component.get('v.DPMEmployee.DPM_Legal_First_Name__c');
        var dpmEmpLN = component.get('v.DPMEmployee.DPM_Last_Name__c');
        if(dpmEmpFN != null){
            this.showToast('success','Employee' +' '+ dpmEmpFN + ' '+ dpmEmpLN + ' '+ 'is now created in Digital Personnel Management.');
        }
    },
    hireDateInput : function(component,event) {
        var preDate = new Date();
        preDate.setDate(preDate.getDate() - 15);
        var prefifDate = $A.localizationService.formatDate(preDate, "yyyy MM dd ");
        component.set("v.prefifDate", prefifDate);
        var userSelectedDate = component.find('hireDate').get('v.value');
        var selecteddate = $A.localizationService.formatDate(userSelectedDate, "yyyy MM dd ");
        component.set("v.selecteddate", selecteddate);
        var inputCmp = component.find("hireDate");
        var value = inputCmp.get("v.value");
        var orgActiveDate = component.get("v.account.Org_activated__c");
        var orgActiveDateFormatted = $A.localizationService.formatDate(orgActiveDate, "yyyy MM dd ");
        var corpOrgActivationDate = component.get("v.storeDealership.Org_activated__c"); 
        
        if(selecteddate < prefifDate){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title : 'Warning',
                message: 'Hire date more than 15 days ago, please verify the hire date',
                duration:'10000',
                key: 'info_alt',
                type: 'warning',
                mode: 'dismissible'
            });
            toastEvent.fire();
        }
        if((selecteddate < orgActiveDateFormatted && orgActiveDate != null) || (!$A.util.isUndefinedOrNull(corpOrgActivationDate) && selecteddate < $A.localizationService.formatDate(corpOrgActivationDate, "yyyy MM dd "))){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title : 'Error',
                message: 'The Hire date cannot be earlier than the Store activation date. Please change the Hire date',
                duration:'10000',
                key: 'info_alt',
                type: 'error',
                mode: 'dismissible'
            });
            toastEvent.fire();
        }
    },
    validateFields:function(component,event,helper){
        let blnAllow = true;
        let requiredInputs =[];
        if(component.get("v.fromPortal")){
            requiredInputs=["legalFName","email","gender","prefix","lastName","hireDate","idOwnerTitle","idPersonalEmail","zipcodeMex","zipcode","zipcodeUn"];
        }else{
            requiredInputs=["legalFName","email","gender","prefix","lastName","hireDate","idOwnerTitle","idAccount","idPersonalEmail","zipcodeMex","zipcode","zipcodeUn","cellphone","address","city","idState","idStateCan","idStateMex","idCountry","postalcodeMex"];
        }
        
        for (let idInput of requiredInputs) {
            let input = component.find(idInput);
            if (input && !input.checkValidity()) {
                input.showHelpMessageIfInvalid();
                blnAllow = false;
            }
        }
        //required inputs of Job Positions Component
        let varJPPositions = component.find('idJPCmp').find('idPosition');
        let varJPStartDates = component.find('idJPCmp').find('idStartDate');
        let arrRequiredInputs = [];
        if(Array.isArray(varJPPositions)) {
            arrRequiredInputs.push(...varJPPositions);
        } else {
            arrRequiredInputs.push(varJPPositions);
        }
        if(Array.isArray(varJPStartDates)) {
            arrRequiredInputs.push(...varJPStartDates);
        } else {
            arrRequiredInputs.push(varJPStartDates);
        }
        for(let inputPosition of arrRequiredInputs) {
            //console.log(inputPosition);
            if (!inputPosition.checkValidity()) {
                inputPosition.showHelpMessageIfInvalid();
                blnAllow = false;
            }
        }
        if(blnAllow) {
            //Non-required validations
            let varDPMEmployee = component.get('v.DPMEmployee');
            let varDPMJobPositions = component.get('v.DPMJobPositions');
            let hireDate = varDPMEmployee.DPM_Hire_Date__c;
            let hasPrimary = false;
            let varJobTitle = [];   
            var orgActiveDate = component.get("v.account.Org_activated__c");
            var corpOrgActivationDate = component.get("v.storeDealership.Org_activated__c");  
            
            for(let jobPosition of varDPMJobPositions) {
                if($A.localizationService.formatDate(jobPosition.DPM_Start_Date__c, "yyyy MM dd ") < $A.localizationService.formatDate(hireDate, "yyyy MM dd ")) {
                    helper.showToast('error','Start Date cannot be earlier than the Hire Date.');
                    blnAllow = false;
                    break;
                }
                if($A.localizationService.formatDate(jobPosition.DPM_Start_Date__c, "yyyy MM dd ") > $A.localizationService.formatDate(jobPosition.DPM_End_Date__c, "yyyy MM dd ")) {
                    helper.showToast('error','End Date cannot be earlier than the Start Date.');
                    blnAllow = false;
                    break;
                }
                if(!hasPrimary) {                    
                    if(jobPosition.DPM_Primary__c && jobPosition.DPM_End_Date__c == null) {
                        hasPrimary = jobPosition.DPM_Primary__c;
                    }
                }    
                if(jobPosition.DPM_End_Date__c==null){
                	varJobTitle.push(jobPosition.Name);
                }
            }
            if(blnAllow) {
                //Check for active primary positions
                if(!hasPrimary) {
                    helper.showToast('error','One active Primary position should be assigned to the Retailer Employee.');
                    blnAllow = false; 
                }
            }
            if(blnAllow) {
                //Check for duplicate job titles
                if(varJobTitle.length != new Set(varJobTitle).size) {
                    helper.showToast('error','Duplicate positions are selected, please select unique positions for the Retailer Employee.');
                    blnAllow = false; 
                }
            }
            if(blnAllow) {
                // Check for Hire Date
                
                let hireDate = component.get('v.DPMEmployee.DPM_Hire_Date__c');
                if(orgActiveDate != null){
                    if(($A.localizationService.formatDate(hireDate, "yyyy MM dd ") < $A.localizationService.formatDate(orgActiveDate, "yyyy MM dd ")) ) {
                    helper.showToast('error','The Hire date cannot be earlier than the Store activation date. Please change the Hire date');
                    blnAllow = false; 
                    } 
                }else if(!$A.util.isUndefinedOrNull(corpOrgActivationDate) && ($A.localizationService.formatDate(hireDate, "yyyy MM dd ") < $A.localizationService.formatDate(corpOrgActivationDate, "yyyy MM dd ")) ) {
                    helper.showToast('error','The Hire date cannot be earlier than the Store activation date. Please change the Hire date');
                    blnAllow = false;                        
                }
            }
        }
        return blnAllow;
    },
    refreshDPM : function(component) {
        component.getEvent("refreshDPMEvent").fire();
    },
    setJobPositions : function(component, event, helper) {
        let varDPMJobPositions = [];
        component.set('v.DPMJobPositions',helper.addJobPosition(varDPMJobPositions));
    },
    addJobPosition : function(lstJobPositions) {
        lstJobPositions.push({Name:'',DPM_Start_Date__c:null,DPM_End_Date__c:null,DPM_Primary__c:false,showPrimary:false,blnAlreadyTerminated:false});
        return lstJobPositions;
    },
    getMaxHireDate : function() {
        let maxDate = new Date();
        maxDate.setMonth(maxDate.getMonth() + 3);
        let month = maxDate.getMonth();
        if (month < 10) {month = '0' + month;}
        let date = maxDate.getDate();
        if (date < 10) {date = '0' + date;}
        let todaysDate = maxDate.getFullYear() + '-' + month + '-' + date;
        return todaysDate;
    },
    getDealershipOptions : function(component, event, helper) {
        var accountAction = component.get('c.getDealerships');
        accountAction.setParams({
            "isSupplier" : component.get("v.IsSupplier") 
        });
        accountAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let varDealerships = response.getReturnValue();
                let picklistOptions = [];
                picklistOptions.push({text:'--None--',value:''});
                if(!$A.util.isEmpty(varDealerships)) {
                    for(let dealership of varDealerships) {
                        picklistOptions.push(
                            {
                                text:dealership.Name+' - '+dealership.Retailer__c,
                                value:dealership.Id
                            }
                        );
                    }
                    component.set('v.storeAllDealershipsList',varDealerships);
                }                
                component.set('v.dealershipsList',picklistOptions);                
                helper.hideSpinner(component);
            }
        });
        $A.enqueueAction(accountAction);
    },
    reactivateEmpHlpr: function(component, event, helper) {
        alert('Employee reactivation process is under construction...');
        component.set("v.isOpen", false);
        var showModal = component.get('v.showModal');
        component.set('v.showModal', !showModal);
    },
    deleteRetEmpRecord :function(component, event, helper) {        
        let dmpRecId = component.get("v.DPMEmployee.Id");
        let varDPMEmployee = component.get("v.DPMEmployee");
        var deleteAction = component.get("c.deleteNewRetailerEmp");
        deleteAction.setParams({            
            idDpmEmp:dmpRecId
        });        
        deleteAction.setCallback(this,function(response){
            var state=response.getState();
            var retValue=response.getReturnValue();            
            if(state==='SUCCESS'){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Success',
                    message: 'Record has been deleted successfully',
                    duration:'5000',
                    type: 'Success'
                    
                });
                toastEvent.fire();
                component.getEvent("refreshDPMEvent").fire();
            }
            else if(state==='ERROR'){
                let errors = response.getError();
                let message = $A.get("$Label.c.DPM_System_Error"); // Default error message
                // Retrieve the error message sent by the server
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    let systemErrorMessage = errors[0].message;
                    helper.generateDPMLog(component, event, helper,varDPMEmployee.DPM_Account__c,systemErrorMessage);
                }
                // Display the message
                helper.showToast('error',message);
                //helper.hideSpinner(component);
                //helper.showToast('error',message);
            }
        });
        $A.enqueueAction(deleteAction);
    }, 
    generateDPMLog : function(component, event, helper, parentAccountId,ErrorMessage) {
        let action = component.get("c.createDPMErrorNotification");
        action.setParams({accountId:parentAccountId,strExceptionMsg:ErrorMessage});
        action.setCallback(this, function(response) {
            var state = response.getState();
            //alert(state);
            if (state === "SUCCESS") {  
                return true;
            }
        });
        $A.enqueueAction(action);
        return true;
    },
    createModal : function(component,componentName,parameters) {
        $A.createComponent(componentName, parameters, function(modal,status,errorMessage) {
            if (status === 'SUCCESS') {
                var body = component.get('v.body');
                body.push(modal);
                component.set('v.body', body);
            } else if (status === "INCOMPLETE") {
                console.warn("No response from server or client is offline.")
            }
                else if (status === "ERROR") {
                    console.error("Error: " + errorMessage);
                }
        });
    },
    duplicateCheckOnApproval : function(component, event, helper,isSupplier) {
     	let dupCheckAction = component.get("c.duplicateCheck_Approval");
        let varDPMEmployee = component.get('v.DPMEmployee');
        delete varDPMEmployee['DPM_Job_Positions__r'];
        delete varDPMEmployee['DPM_Account__r'];
        dupCheckAction.setParams({strDPMEmployee:JSON.stringify(varDPMEmployee)});
        dupCheckAction.setCallback(this,function(response) {
            var state=response.getState();            
            if(state==='SUCCESS') {
                let lstDuplicateRecords = response.getReturnValue();
                if($A.util.isEmpty(lstDuplicateRecords)) {
                    if(isSupplier){// updated by gaurav for supplier employee creation us: 2614342 
                        component.set('v.strModalHeader','Confirmation');
                        component.set('v.strModalBody','You want to proceed with the employee creation.');
                        component.set('v.strModalType','confirmation_btns_confirm_back');
                        //component.set('v.showNotification',true);
                        let parameters = {"aura:id":"idAlertSupplier","strModalBody": component.get("v.strModalBody"),"strModalHeader":component.get("v.strModalHeader"), "strModalType":component.get("v.strModalType")};
                        helper.createModal(component, 'c:DPM_NotificationModal',parameters);
                       
                        /*let varBody="You want to proceed with the employee creation.";
                        let parameters = {"aura:id":"idAlertSupplier",
                                          "strModalHeader":"Confirmation",
                                          "strModalBody":varBody,
                                          "strModalType":"confirmation_btns_confirm_back"};
                        helper.createModal(component,'c:DPM_NotificationModal',parameters);*/
                    }else{
                        helper.saveRecordToDB(component, event, helper, 'Approved');
                    }
                    
                } else {
                    let blnSSNMatched=false;
                    let blnEmailMatched=false;
                    //Determine SSN Match
                    for(let personRole of lstDuplicateRecords){
                        console.log('personRole123$ '+JSON.stringify(personRole));
                        if(varDPMEmployee.DPM_Email__c==personRole.RE_Contact__r.Email || varDPMEmployee.DPM_Email__c==personRole.DPM_Work_Email__c){
                            blnEmailMatched=true;
                            break;
                        }
                        if(varDPMEmployee.DPM_Request_Type__c=='New') {
                            if(personRole.RE_Contact__c!=null &&
                               personRole.RE_Contact__r.DPM_SSN__c!=null &&
                               varDPMEmployee.DPM_SSN_SIN__c==personRole.RE_Contact__r.DPM_SSN__c){
                                blnSSNMatched=true;
                                break;
                            }
                        }                        
                    }
                    //if email does not exist and the request is not for a new employee
                    if(!blnEmailMatched && varDPMEmployee.DPM_Request_Type__c!='New') {
                        helper.saveRecordToDB(component, event, helper, 'Approved');
                        return;
                    }// updated by gaurav for supplier employee creation us: 2614342                     
                    if(blnEmailMatched || (isSupplier && blnEmailMatched)) {
                        //Email Matched
                        let varBody="This email is already used in another retailer "+lstDuplicateRecords[0].RE_Account__r.Name+". Please indicate a different email, preferably your employee's work email in this store, to approve the profile.";
                        let parameters = {"aura:id":"idAlert",
                                          "strModalHeader":"Duplicate Email Check",
                                          "strModalBody":varBody,
                                          "strModalType":"alert"};
                        helper.createModal(component,'c:DPM_NotificationModal',parameters);
                        helper.hideSpinner(component);
                    } else if(blnSSNMatched && !isSupplier) {
                        //SSN Matched                       
                        let varBody="This SSN is already used in another retailer "+lstDuplicateRecords[0].RE_Account__r.Name+". Please contact the administrator.";
                        let parameters = {"aura:id":"idAlert",
                                          "strModalHeader":"Duplicate SSN Check",
                                          "strModalBody":varBody,
                                          "strModalType":"alert"};
                        helper.createModal(component,'c:DPM_NotificationModal',parameters);
                        helper.hideSpinner(component);                                              
                    } else {
                        //name matched
                        //display warning message: This employee may already exist. Do you want to continue?
                        if(!isSupplier){
                            let varBody="This person might be currently employed at another Volvo retailer, or a recent Volvo training school graduate, or they may have previously worked for Volvo. Please review the data and approve the record as per your determination.";
                            let parameters = {"aura:id":"idAlert",
                                              "strModalHeader":"Duplicate Name Check",
                                              "strModalBody":varBody,
                                              "strModalType":"confirmation_styletwo"};
                            helper.createModal(component,'c:DPM_NotificationModal',parameters);
                            helper.hideSpinner(component);
                        }
                    }
                }
                //  console.log('hrer1');                
            } else {
                let errors = response.getError();
                let message = 'Unknown error'; // Default error message
                // Retrieve the error message sent by the server
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                // Display the message
                helper.showToast('error',message);
                helper.hideSpinner(component);
            }             
        });
        $A.enqueueAction(dupCheckAction);
    },
})