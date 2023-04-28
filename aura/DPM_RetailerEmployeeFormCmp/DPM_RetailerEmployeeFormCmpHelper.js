({
    decryptIdAndCheckLinkExpiry : function(component, event, helper) {
        let varCurrentURLParam = window.location.search.substring(1);        
        let varParamNameValuePair = varCurrentURLParam.split('=');
        if (varParamNameValuePair[0] == 'id') {
            let varEncryptedId = varParamNameValuePair[1];
            //console.log('varEncryptedId: '+varEncryptedId);
            if(varEncryptedId) {
                var accessAction = component.get("c.decryptAndCheckAccess");
                accessAction.setParams({strEncryptedId:varEncryptedId});
                accessAction.setCallback(this, function(response) {
                    var state = response.getState();
                    if (state === "SUCCESS") {
                        let varDPMEmployee = response.getReturnValue();
                        component.set('v.DPMEmployee',varDPMEmployee);
                         //let varDPMEmployee = component.get('v.DPMEmployee');
        				component.set("v.strJobPositionList",JSON.stringify(varDPMEmployee['DPM_Job_Positions__r']));        
                        let addressFieldDisable = {};
                        addressFieldDisable.DPM_Home_Address_Street__c = helper.checkValueIsNull(varDPMEmployee, 'DPM_Home_Address_Street__c');
                        addressFieldDisable.DPM_Home_Address_Street_2__c = helper.checkValueIsNull(varDPMEmployee, 'DPM_Home_Address_Street_2__c');
                        addressFieldDisable.DPM_City__c = helper.checkValueIsNull(varDPMEmployee, 'DPM_City__c');
                        addressFieldDisable.DPM_US_State__c = helper.checkValueIsNull(varDPMEmployee, 'DPM_US_State__c');
                        addressFieldDisable.DPM_Canadian_State__c = helper.checkValueIsNull(varDPMEmployee, 'DPM_Canadian_State__c');
                        addressFieldDisable.DPM_Mexican_State__c = helper.checkValueIsNull(varDPMEmployee, 'DPM_Mexican_State__c');
                        addressFieldDisable.DPM_Zipcode__c = helper.checkValueIsNull(varDPMEmployee, 'DPM_Zipcode__c');
                        component.set('v.addressFieldDisable', addressFieldDisable);
                        //console.log('-=-=-'+JSON.stringify(varDPMEmployee));
                        component.set('v.DPMJobPositions',varDPMEmployee.DPM_Job_Positions__r);
                        component.set('v.hasAccess',true);
                        if(varDPMEmployee.DPM_Country__c == 'Canada') {
                            component.set('v.SSNBtnLabel','Show SIN');
                        } else {
                            component.set('v.SSNBtnLabel','Show SSN');
                        }
                        helper.addMessageEventListener(component, event, helper);
                        helper.getStateCountryValues(component, event, helper);
                        try{
                            helper.getDiversityDataOptions(component, event, helper);
                        }catch(err){
                            console.log(err.stack);
                        }
                        helper.handleUnsavedCheck(component, event, helper, 'addListener');
                        helper.hideSpinner(component);
                    } else {
                        let errors = response.getError();
                        let message = 'Unknown error'; // Default error message
                        // Retrieve the error message sent by the server
                        if (errors && Array.isArray(errors) && errors.length > 0) {
                            message = errors[0].message;
                        }
                        // Display the message
                        //helper.showToast('error',message);
                        if(message == 'last block incomplete in decryption') {
                            message='The registration form is invalid.';
                        }
                        component.set('v.errorMessage',message);
                        helper.hideSpinner(component);
                    }
                });
                $A.enqueueAction(accessAction);
            }            
        } else {
            helper.showToast('error','The URL is invalid.');
        }   
    },
    checkValueIsNull : function(record, fieldName) { 
        if(record[fieldName] && record[fieldName] != ''){
            return true;
        }
        return false;
    },
    getProficiencyValues : function(component, event, helper) { 
        helper.getpicklistValuesFromDPM(component, helper, 'DPM_Proficiency_1__c');
    },
    getDiversityDataOptions : function(component, event, helper) {
        let diversityDataAction = component.get('c.getDiversityData');
        diversityDataAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let lstDiversityData = response.getReturnValue();
                let lstLanguageOptions = ['--None--'];
                component.set('v.diversityData',lstDiversityData);
                /*if(!$A.util.isEmpty(component.get('v.diversityData')[0].DPM_Available_Languages__c)) {
                    component.set('v.languageList',helper.generatePicklistOptions(lstLanguageOptions.concat((component.get('v.diversityData')[0].DPM_Available_Languages__c).split(';'))));
                }*/
                helper.setDiversityDataByCountry(component, event, helper);
            }
        });
        $A.enqueueAction(diversityDataAction);
    },    
    capitalize : function(strText) {
        return strText.charAt(0).toUpperCase() + strText.slice(1);
    },
    getGenderList : function(component, event, helper) {
        helper.getpicklistValuesFromDPM(component, helper, 'DPM_Gender__c');
    },
    getPrefixList : function(component, event, helper) {
        helper.getpicklistValuesFromDPM(component, helper, 'DPM_Prefix__c');
    },
    getSuffixList : function(component, event, helper) {
        helper.getpicklistValuesFromDPM(component, helper, 'DPM_Suffix__c');
    },
    getpicklistValuesFromDPM : function(component, helper, strAPIName) {
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
                    case 'DPM_US_State__c':
                        component.set('v.statesList',helper.generatePicklistOptions(picklistValues));
                        break;
                    case 'DPM_Canadian_State__c':
                        component.set('v.statesList',helper.generatePicklistOptions(picklistValues));
                        break;
                    case 'DPM_Proficiency_1__c':
                        component.set('v.DPMProficiency',helper.generatePicklistOptions(picklistValues));
                        break;
                    default:
                        break;
                }
            }
        });
        $A.enqueueAction(initAction);
    },
    saveRecordToDB : function(component, event, helper, type) {
       // console.log('saveRecordToDB running');
        let varDPMEmployee = component.get('v.DPMEmployee');
        //console.log('varDPMEmployee:'+JSON.stringify(varDPMEmployee));
        let country = component.get('v.DPMEmployee.DPM_Country__c');
        if(component.get('v.DPMEmployee.DPM_Request_Type__c') != 'Extension' && country != 'Mexico') {
            //Diversity Data: Add Languages
            let varMapLanguageToProficiency = component.find("idLanguageCmp").get('v.mapLanguageToProficiency');
            for(let i=0;i<3;i++) {
                let varLanguageField = 'DPM_Language_'+(i+1)+'__c';
                let varProficiencyField = 'DPM_Proficiency_'+(i+1)+'__c';
                if($A.util.isEmpty(varMapLanguageToProficiency[i])) {
                    varDPMEmployee[varLanguageField] = '';
                    varDPMEmployee[varProficiencyField] = '';
                } else {
                    if(varMapLanguageToProficiency[i].Language == 'Other') {
                        varDPMEmployee[varLanguageField] = varMapLanguageToProficiency[i].OtherLanguage;
                    } else {
                        varDPMEmployee[varLanguageField] = varMapLanguageToProficiency[i].Language;
                    }
                    varDPMEmployee[varProficiencyField] = varMapLanguageToProficiency[i].Proficiency;
                }            
            }
            if(varDPMEmployee.DPM_Race__c == 'Two or more races') {
                if(!$A.util.isEmpty(component.get('v.otherRace'))) {
                    varDPMEmployee.DPM_Race__c = component.get('v.otherRace');
                } 
            }
            if(varDPMEmployee.DPM_Ethnicity__c == 'Other') {
                if(!$A.util.isEmpty(component.get('v.otherEthnicity'))) {
                    varDPMEmployee.DPM_Ethnicity__c = component.get('v.otherEthnicity');
                } 
            }
        }
               
        //console.log(' varDPMEmployee>>>>>> '+JSON.stringify(varDPMEmployee));
        var submitAction = component.get('c.submitDPMRecord');
        //Remove related lists (parent and child)
        let strJobPositionList=component.get("v.strJobPositionList");
        //console.log('strJobPositionList:'+strJobPositionList);
        delete varDPMEmployee['DPM_Job_Positions__r'];
        delete varDPMEmployee['DPM_Account__r'];
        if(type == 'Submitted - SSN Mismatch' || type == 'Saved - SSN Mismatch') {
            // do not save SSN in case of mismatch
            delete varDPMEmployee['DPM_SSN_SIN__c'];
        }
        //varDPMEmployee.DPM_Suffix__c = 'jjj';// for testing purpose!!
        submitAction.setParams({strDPMEmployee:JSON.stringify(varDPMEmployee),strDPMJobPositions:strJobPositionList,strType:type});
        submitAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                if(type.includes('Submitted')) {
                    component.set('v.hasAccess',false);
                    component.set('v.submittedMessage','Your profile has been submitted successfully.');
                    helper.handleUnsavedCheck(component, event, helper, 'removeListener');
                } else {
                    helper.showToast('success','Your profile was saved successfully.',component);
                }
                helper.hideSpinner(component);
            } else {
                let errors = response.getError();
                let message = $A.get("$Label.c.DPM_System_Error"); // Default error message
                // Retrieve the error message sent by the server
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    let systemErrorMessage = errors[0].message;
                    helper.generateDPMLog(component, event, helper,varDPMEmployee.DPM_Account__c,systemErrorMessage);
                }
                // Display the message
                helper.showToast('error',message,component);
                helper.hideSpinner(component);
            }
        });
        $A.enqueueAction(submitAction);
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
    showToast : function(type,message,component) {
        let parameters = {"aura:id":"idToast","type":type,"message":message,"title":type};
        $A.createComponent('c:DPM_RetailerEmployeeForm_CustomToast', parameters, function(modal, status, errorMessage) {
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
        window.setTimeout(
            $A.getCallback(function() {
                let toastCmp = component.find("idToast");
                if(toastCmp != undefined) {
                    toastCmp.destroy();
                }
            }), 10000
        );
    },
    showSpinner : function(component) {
        $A.util.removeClass(component.find('idSpinnerDiv'),'slds-hide');        
    },
    hideSpinner : function(component) {
        $A.util.addClass(component.find('idSpinnerDiv'),'slds-hide');
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
    validateFields:function(component, event, helper){
        let blnAllow = true;
        let requiredInputs = ["legalFName","email","gender","prefix","lastName","cellphone","address","city","idState","idStateCan","zipcode","zipcodeCan","homephone","confirmEmail","confirmSSN","idPersonalEmail","cellphoneMex","postalcodeMex"];
        blnAllow = helper.checkRequiredValidity(component,blnAllow,requiredInputs);  
        if(!blnAllow) {
            helper.hideSpinner(component);
        }
        return blnAllow;
    },
    validateSaveOnlyFields : function(component, event, helper) {
        let blnAllow = true;
        let requiredInputs = ["confirmEmail","confirmSSN"];
        blnAllow = helper.checkRequiredValidity(component,blnAllow,requiredInputs);
        if(!blnAllow) {
            helper.hideSpinner(component);
        }
        return blnAllow;
    },
    checkDuplicates : function(component, event, helper) {
        let checkDuplicateAction = component.get('c.duplicateCheckSelfReg');
        let varDPMEmployee = component.get('v.DPMEmployee');
        delete varDPMEmployee['DPM_Job_Positions__r'];
        delete varDPMEmployee['DPM_Account__r'];
        checkDuplicateAction.setParams({'strDPMEmployee':JSON.stringify(varDPMEmployee)});
        checkDuplicateAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {//console.log('#####2.1');
                let varDuplicateResponse = response.getReturnValue();
                if(varDuplicateResponse.hasDuplicates) {
                    let varDuplicatesFound = component.get('v.blnDuplicateFound');
                    if(!varDuplicatesFound) {
                        let varMatchingFields = '';
                        for(let matchingDuplicate of varDuplicateResponse.dpmDuplicates) {
                            if(!matchingDuplicate.blnPlacebo) {
                                if(matchingDuplicate.objectType == 'Contact') {
                                    if(!$A.util.isEmpty(varDPMEmployee.DPM_SSN_SIN__c)) {
                                        let varSSN = (varDPMEmployee.DPM_SSN_SIN__c).replaceAll("-","");
                                        if(varSSN == matchingDuplicate.objRecord.DPM_SSN__c) {
                                            let varSSNLabel = (component.get('v.DPMEmployee.DPM_Country__c')=='United States'?'SSN':'SIN');
                                            varMatchingFields = ($A.util.isEmpty(varMatchingFields)?varSSNLabel:varMatchingFields+';'+varSSNLabel);
                                        }                                        
                                    }
                                    if(varDPMEmployee.DPM_Cell_Phone__c!=null && 
                                       (varDPMEmployee.DPM_Cell_Phone__c == matchingDuplicate.objRecord.Phone
                                      || varDPMEmployee.DPM_Cell_Phone__c == matchingDuplicate.objRecord.HomePhone
                                      || varDPMEmployee.DPM_Cell_Phone__c == matchingDuplicate.objRecord.OtherPhone)){
                                        if(component.get('v.DPMEmployee.DPM_Country__c') !='Mexico'){
                                        varMatchingFields = ($A.util.isEmpty(varMatchingFields)?'Personal Phone#':varMatchingFields+';Personal Phone#');
                                        }
                                        else{
                                            varMatchingFields = ($A.util.isEmpty(varMatchingFields)?'Contact Phone#':varMatchingFields+';Contact Phone#');
                                        }
                                    }
                                    if(varDPMEmployee.DPM_Email__c == matchingDuplicate.objRecord.Email){
                                        varMatchingFields = ($A.util.isEmpty(varMatchingFields)?'Registration Email':varMatchingFields+';Registration Email');                                       
                                    }
                                    if(varDPMEmployee.DPM_Last_Name__c == matchingDuplicate.objRecord.LastName 
                                       && varDPMEmployee.DPM_Legal_First_Name__c == matchingDuplicate.objRecord.FirstName
                                       && ($A.util.isEmpty(varDPMEmployee.DPM_Suffix__c) || varDPMEmployee.DPM_Suffix__c == matchingDuplicate.objRecord.Suffix)
                                       && $A.util.isEmpty(varMatchingFields)) {
                                        varMatchingFields = ($A.util.isEmpty(varMatchingFields)?'Last Name, First Name, Suffix':varMatchingFields+';Last Name, First Name, Suffix');
                                    } else if(varDPMEmployee.DPM_Last_Name__c == matchingDuplicate.objRecord.LastName 
                                              && varDPMEmployee.DPM_Preferred_First_Name__c == matchingDuplicate.objRecord.DPM_Preferred_First_Name__c
                                              && ($A.util.isEmpty(varDPMEmployee.DPM_Suffix__c) || varDPMEmployee.DPM_Suffix__c == matchingDuplicate.objRecord.Suffix)
                                              && !$A.util.isEmpty(varDPMEmployee.DPM_Preferred_First_Name__c)
                                              && $A.util.isEmpty(varMatchingFields)) {
                                        varMatchingFields = ($A.util.isEmpty(varMatchingFields)?'Last Name, Preferred First Name, Suffix':varMatchingFields+';Last Name, Preferred First Name, Suffix');
                                    }
                                } else {
                                    if(varDPMEmployee.DPM_Cell_Phone__c == matchingDuplicate.objRecord.DPM_Work_Phone__c){
                                        if(component.get('v.DPMEmployee.DPM_Country__c') !='Mexico'){
                                        varMatchingFields = ($A.util.isEmpty(varMatchingFields)?'Personal Phone#':varMatchingFields+';Personal Phone#');
                                        }
                                        else{
                                            varMatchingFields = ($A.util.isEmpty(varMatchingFields)?'Contact Phone#':varMatchingFields+';Contact Phone#');
                                        }
                                    }
                                    if(varDPMEmployee.DPM_Email__c == matchingDuplicate.objRecord.DPM_Work_Email__c){
                                        varMatchingFields = ($A.util.isEmpty(varMatchingFields)?'Registration Email':varMatchingFields+';Registration Email');                                       
                                    }
                                }
                                if(varMatchingFields!=''){
                                	helper.showAlert(component, event, helper, 'Duplicates Found', 'We found a similar profile based on your '+varMatchingFields+', please verify your entry.', 'alert');
                            		break;
                                }
                            }                            
                        }
                    } else {//console.log('#####2.2');
                        helper.showAlert(component, event, helper, 'Duplicates Found', 'Have you worked at any of these stores?','duplicate',varDuplicateResponse.dpmDuplicates);
                    }
                    component.set('v.blnDuplicateFound',varDuplicateResponse.hasDuplicates);
                    component.set('v.lstDuplicateRecords',varDuplicateResponse.dpmDuplicates);
                } else {//console.log('#####2.3');
                    helper.saveRecordToDB(component, event, helper, 'Submitted');
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
        $A.enqueueAction(checkDuplicateAction);
    },
    checkRequiredValidity : function(component,blnAllow,requiredInputs) {  
        //console.log('idInput>>>>>>>> '+component.get("v.DPMEmployee.DPM_US_State__c"));
        for (let idInput of requiredInputs) {            
            let input = component.find(idInput);            
            if (input && !input.checkValidity()) {
                input.showHelpMessageIfInvalid();
                blnAllow = false;
            }            
        }        
        if(!$A.util.isEmpty(component.get('v.DPMEmployee.DPM_SSN_SIN__c')) && !$A.util.isEmpty(component.get('v.confirmSSN'))) {
            if(component.get('v.DPMEmployee.DPM_SSN_SIN__c') != component.get('v.confirmSSN')) {
                let confirmSSNComponent = component.find("idConfirmSSN");
                if(confirmSSNComponent) {
                    confirmSSNComponent.setCustomValidity("Your SSNs don't match, please re-type");
                    confirmSSNComponent.reportValidity();
                }                
                blnAllow = false;
            }   
        }  
        //required inputs of Diversity Data
        
        if(component.get('v.DPMEmployee.DPM_Request_Type__c') != 'Extension') {
            let arrRequiredInputs = [];
            if(!$A.util.isEmpty(component.find('idLanguageCmp'))) {
                let varLanguages = component.find('idLanguageCmp').find('idLanguage');
                let varOtherLanguages = component.find('idLanguageCmp').find('idOtherLanguage');
                let varProficiencies = component.find('idLanguageCmp').find('idProficiency');
                arrRequiredInputs = this.addToArray(arrRequiredInputs,varLanguages);
                arrRequiredInputs = this.addToArray(arrRequiredInputs,varOtherLanguages);
                arrRequiredInputs = this.addToArray(arrRequiredInputs,varProficiencies);
            }
            if(!$A.util.isEmpty(component.find('idDiversityData'))) {
                let cmpOtherRace = component.find('idDiversityData').find('idOtherRace');
                let cmpOtherEthnicity = component.find('idDiversityData').find('idOtherEthnicity');
                arrRequiredInputs = this.addToArray(arrRequiredInputs,cmpOtherRace);                
                arrRequiredInputs = this.addToArray(arrRequiredInputs,cmpOtherEthnicity);
            }              
            for(let inputElement of arrRequiredInputs) {
                //console.log('inputElement>>>>>> '+inputElement);
                if (inputElement && !inputElement.checkValidity()) {
                    inputElement.showHelpMessageIfInvalid();
                    blnAllow = false;
                }
            }
        }         
        if(!blnAllow) {
            this.showToast('warning','Please verify your inputs',component);
        } else if(!$A.util.isEmpty(component.get('v.DPMEmployee.DPM_Country__c')) && component.get('v.DPMEmployee.DPM_Country__c') == 'Mexico'){
            let varStreetAddress = component.get('v.DPMEmployee.DPM_Home_Address_Street__c');
            let varCity = component.get('v.DPMEmployee.DPM_City__c');
            let varMexicanState = component.get('v.DPMEmployee.DPM_Mexican_State__c');
            let varZipcode = component.get('v.DPMEmployee.DPM_Zipcode__c');
            let intFilledFields = 0;
            if(!$A.util.isEmpty(varStreetAddress)) {
                intFilledFields++;
            }
            if(!$A.util.isEmpty(varCity)) {
                intFilledFields++;
            }
            if(!$A.util.isEmpty(varMexicanState)) {
                intFilledFields++;
            }
            if(!$A.util.isEmpty(varZipcode)) {
                intFilledFields++;
            }
            if(intFilledFields !=0 && intFilledFields !=4){ 
                this.showToast('error','Please fill in all address fields among Street, Postal code, City, State',component);
                blnAllow = false;                
            }             
        } 
        return blnAllow;
    },
    getPositionsList : function(component, event, helper) {
        helper.getPicklistValuesForPositions(component, helper);
    },
    getPicklistValuesForPositions : function(component, helper) {
        let IdAccount=component.get("v.DPMEmployee").DPM_Account__c;
        let params={'retailer_storeId':IdAccount};	
        var initPositionAction = component.get('c.getAllJobPositions');
        initPositionAction.setParams(params);
        initPositionAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let varAllJobPositions = response.getReturnValue();
                let varJobPositions = ['--None--'];
                let varPrimaryPositions = [];
                let varOwnerPositions = [];
                let varIncentiveEligiblePositions = [];
                for(let jobPosition of varAllJobPositions) {					
                    if(jobPosition.DPM_Primary_Position__c) {
                        varPrimaryPositions.push(jobPosition.MasterLabel);
                    }
                    if(jobPosition.DPM_Owner_Position__c) {
                        varOwnerPositions.push(jobPosition.MasterLabel);
                    } else {
                        varJobPositions.push(jobPosition.MasterLabel);
                    }
                    if(jobPosition.DPM_Incentive_Eligible__c) {
                        varIncentiveEligiblePositions.push(jobPosition.MasterLabel);
                    }
                }
                component.set('v.positionsList',helper.generatePicklistOptions(varJobPositions));
                component.set('v.primaryPositionsList',varPrimaryPositions);
                component.set('v.incentivePositionsList',varIncentiveEligiblePositions);
                component.set('v.ownerPositionsList',helper.generatePicklistOptions(varOwnerPositions));
            }
        });
        $A.enqueueAction(initPositionAction);
    },
    showPrompt : function(component, event, helper, promptType, promptText, promptTitle) {        
        let parameters = {"aura:id":"idPrompt","strPromptType":promptType,"strPromptText":promptText,"strPromptTitle":promptTitle};
        helper.createNewComponent(component, event, helper,'c:DPM_PromptMessage',parameters);        
    },
    showAlert : function(component, event, helper, alertHeader, alertBody, alertType, duplicateRecords) {        
        let parameters = {"aura:id":"idAlertModal","strModalHeader":alertHeader,"strModalBody":alertBody,"strModalType":alertType,"lstDuplicateRecords":duplicateRecords};
        helper.createNewComponent(component, event, helper,'c:DPM_NotificationModal',parameters);
    },
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
    handleUnsavedCheck : function(component,helper,event,message) {
        let handlerEvent = $A.get("e.c:DPM_PersonnelMasterHandleRecordEvt");
        handlerEvent.setParams({"message":message});
        handlerEvent.fire();
    },
    addMessageEventListener : function(component,helper,event) {
        window.addEventListener("message",function(event) {
            if(event.data=='Unlock') {
                component.set('v.blnSubmitDisabled',false);
            } else if(event.data=='Lock') {
                component.set('v.blnSubmitDisabled',true);
            } else if(event.data=='hidden_recaptchaChallenge') {
                let captchEl = document.getElementById('idGoogleReCaptchaIframe');
                captchEl.height = 110;
            } else if(event.data=='visible_recaptchaChallenge') {
                let captchEl = document.getElementById('idGoogleReCaptchaIframe');
                captchEl.height = 500;
            }
        });
    },
    getStateCountryValues : function(component, event, helper) {
        let countryStatesAction = component.get('c.getCountriesAndStates');
        countryStatesAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let varMapCountryStates = response.getReturnValue();
                let lstCountries = [];
                let varMapCountryToStateOptions = new Map();
                for(let varCountry of Object.keys(varMapCountryStates)) {
                    lstCountries.push(varCountry);
                    varMapCountryToStateOptions[varCountry] = helper.generatePicklistOptions(varMapCountryStates[varCountry],true);
                }
                component.set('v.countryList',helper.generatePicklistOptions(lstCountries));
                component.set('v.mapCountryWithStates',varMapCountryToStateOptions);
                helper.setStateList(component);
            }
        });
        $A.enqueueAction(countryStatesAction);
    },
    setStateList : function(component) {
        let varMapCountryToStateOptions = component.get('v.mapCountryWithStates');
        if($A.util.isEmpty(component.get('v.DPMEmployee.DPM_Country__c'))) {
            component.set('v.statesList',[]);
        } else {
            let states = [{
                    text:'--None--',
                    value:''
                }];
            states = states.concat(varMapCountryToStateOptions[component.get('v.DPMEmployee.DPM_Country__c')]);
            component.set('v.statesList',states);
        }
    },
    clearSSNData : function(component) {
        component.set('v.DPMEmployee.DPM_SSN_SIN__c','');
        component.set('v.confirmSSN','');
    },
    checkConfirmationHelper : function(component, event, helper) {
        let changedComponent = event.getSource();
        let changedComponentId = changedComponent.getLocalId();        
        if(changedComponentId == 'confirmEmail' || changedComponentId == 'email') {
            if(!$A.util.isEmpty(component.get('v.DPMEmployee.DPM_Email__c')) 
               && !$A.util.isEmpty(component.get('v.confirmEmail'))) {
                let confirmEmailComponent = component.find('confirmEmail');
                if(component.get('v.DPMEmployee.DPM_Email__c') != component.get('v.confirmEmail')) {
                    confirmEmailComponent.setCustomValidity("Emails do not match, please re-enter");  //Your emails don't match, please re-type
                } else {
                    confirmEmailComponent.setCustomValidity("");                    
                }  
                confirmEmailComponent.reportValidity();
            }            
        }
        if(changedComponentId == 'idSSN' || changedComponentId == 'idConfirmSSN' || changedComponentId == 'idConfirmSIN') {
            if(!$A.util.isEmpty(component.get('v.DPMEmployee.DPM_SSN_SIN__c')) 
               && !$A.util.isEmpty(component.get('v.confirmSSN'))) {
                let confirmSSNComponent = component.find('idConfirmSSN');
                if(changedComponentId == 'idConfirmSSN' || changedComponentId == 'idConfirmSIN' ) {
                    confirmSSNComponent = event.getSource();
                }                
                if(component.get('v.DPMEmployee.DPM_SSN_SIN__c') != component.get('v.confirmSSN')) {
                    if(component.get('v.DPMEmployee.DPM_Country__c') == 'Canada') {
                        confirmSSNComponent.setCustomValidity("Your SINs don't match, please re-type");
                    } else {
                        confirmSSNComponent.setCustomValidity("Your SSNs don't match, please re-type");
                    }                    
                } else {
                    confirmSSNComponent.setCustomValidity("");                    
                }  
                confirmSSNComponent.reportValidity();
            } 
            if($A.util.isEmpty(component.get('v.DPMEmployee.DPM_SSN_SIN__c')) 
               && $A.util.isEmpty(component.get('v.confirmSSN'))) {
                let confirmSSNComponent = component.find('idConfirmSSN');
                confirmSSNComponent.setCustomValidity("");
                confirmSSNComponent.reportValidity();
            }
        }
    },
    compareSSN : function(component,event,helper,varOrigin) {
        let varContinue = true;
        //alert(component.get('v.DPMEmployee.DPM_Country__c'));
        
        if(component.get('v.DPMEmployee.DPM_Request_Type__c') != 'New' && !$A.util.isEmpty(component.get('v.DPMEmployee.DPM_SSN_SIN__c')) && !$A.util.isEmpty(component.get('v.DPMEmployee.DPM_Contact__r.DPM_SSN__c'))){
            if((component.get('v.DPMEmployee.DPM_SSN_SIN__c')).replaceAll('-','') != (component.get('v.DPMEmployee.DPM_Contact__r.DPM_SSN__c')).replaceAll('-','')) {
                varContinue = false;
                if(!component.get('v.blnSSNMismatch')) {
                    helper.showAlert(component, event, helper, 'SSN Mismatch', 'The SSN you entered does not match what we have on record. Please enter your SSN again.', 'alert');    
                    component.set('v.blnSSNMismatch',true);
                } else {
                    helper.showMatchingProfileList(component,event,helper,varOrigin);
                }                
            }
        }
        
        //alert(varContinue);
        return varContinue;
        //alert('I ....');
    },
    showMatchingProfileList : function(component,event,helper,varOrigin) {
        var getProfileAction = component.get("c.findMatchingProfilesForReactivation_SelfReg");
                getProfileAction.setParams({strContactId:component.get('v.DPMEmployee.DPM_Contact__c')});
                getProfileAction.setCallback(this, function(response) {
                    var state = response.getState();
                    if (state === "SUCCESS") {
                        let varContactList = response.getReturnValue();
                        let varCountry=component.get("v.DPMEmployee").DPM_Country__c; //24/Feb/2021, showing country before SSN Mismatch
                        let parameters = {"aura:id":"idMatchingProfile","profileList":helper.sortMatchingProfiles(component,event,helper,varContactList),"varOrigin":varOrigin,"varCountry":varCountry};
                        helper.createNewComponent(component, event, helper,'c:DPM_MatchingProfileList_SelfReg',parameters);
                    } else {
                        let errors = response.getError();
                        let message = 'Unknown error'; // Default error message
                        // Retrieve the error message sent by the server
                        if (errors && Array.isArray(errors) && errors.length > 0) {
                            message = errors[0].message;
                        }
                        // Display the message
                        //helper.showToast('error',message);
                        component.set('v.errorMessage',message);
                        helper.hideSpinner(component);
                    }
                });
                $A.enqueueAction(getProfileAction);
    },
    sortMatchingProfiles : function(component,event,helper,varMatchingProfiles) {
        let varActiveProfiles = [];
        let varInactiveProfiles = [];
        for(let varProfile of varMatchingProfiles) {
            if(varProfile.Person_Roles__r && varProfile.Person_Roles__r.length>0) {
                //varProfile.Person_Roles__r = (helper.sortList(varProfile.Person_Roles__r,'date')).reverse();
                let varActivePersonRoles = [];
                let varInactivePersonRoles = [];
                let blnActive = false;
                for(let varPersonRole of varProfile.Person_Roles__r) {                    
                    if(!$A.util.isEmpty(varPersonRole.RE_Psn_Active_Date__c)) {
                        varPersonRole.hireYear = (new Date(varPersonRole.RE_Psn_Active_Date__c)).getFullYear();
                    }
                    if(!$A.util.isEmpty(varPersonRole.RE_Psn_NonActive_Date__c)) {
                        varPersonRole.terminationYear = (new Date(varPersonRole.RE_Psn_NonActive_Date__c)).getFullYear();
                    }
                    if(varPersonRole.RE_Psn_Active__c) {
                        blnActive = true;
                        varActivePersonRoles.push(varPersonRole);
                    } else {
                        varInactivePersonRoles.push(varPersonRole);
                    }
                }  
                varActivePersonRoles = (helper.sortList(varActivePersonRoles,'RE_Psn_Active_Date__c')).reverse();
                varInactivePersonRoles = (helper.sortList(varInactivePersonRoles,'RE_Psn_NonActive_Date__c')).reverse();
                varProfile.Person_Roles__r = varActivePersonRoles.concat(varInactivePersonRoles);
                if(blnActive) {
                    varActiveProfiles.push(varProfile);
                } else {
                    varInactiveProfiles.push(varProfile);
                }
            }            
        }
        return varActiveProfiles.concat(varInactiveProfiles);
    },
    sortList : function(lstToBeSorted,field) {
        return lstToBeSorted.sort(function(a,b) {
            return new Date(a[field]) - new Date(b[field]);
        });
    },
    showHideSSNHelper : function(component, event, helper) {
        let country = component.get('v.DPMEmployee.DPM_Country__c');
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
    checkMissingSSN : function(component,event,helper,fromSubmit) {
        component.set('v.blnSSNMissingSubmit',fromSubmit);
        if(component.get("v.DPMEmployee.DPM_Request_Type__c") !='Extension' && component.get('v.DPMEmployee.DPM_Country__c') != 'Mexico' && component.get('v.DPMEmployee.DPM_Country__c') != 'Canada'){
            let lstJobPositions = component.get('v.DPMJobPositions');
            let lstIncentiveEligiblePositions = component.get('v.incentivePositionsList');
            let lstVowels = ['a','e','i','o','u'];
            for(let jobPosition of lstJobPositions) {
                let varSSN = (component.get('v.DPMEmployee.DPM_Country__c')=='United States'?'SSN':'SIN');
                if(lstIncentiveEligiblePositions.includes(jobPosition.Name) && $A.util.isEmpty(component.get('v.DPMEmployee.DPM_SSN_SIN__c'))) {
                    let alertHeader = 'Missing '+varSSN;
                    let firstCharacter = (jobPosition.Name).charAt(0).toLowerCase;
                    let varArticle = (lstVowels.includes(firstCharacter)?'an':'a');
                    let alertBody = 'As '+varArticle+' '+jobPosition.Name+ ' you may qualify for incentives. '+varSSN+' must be provided to receive incentive payments. Please go Back to update your '+varSSN+',or click on Save to save your data without '+varSSN+'.';
                    component.set('v.strModalType','confirmation_stylethree');
                    let parameters = {"aura:id":"idAlertModal","strModalHeader":alertHeader,"strModalBody":alertBody,"strModalType":"confirmation_stylethree"};
                    helper.createNewComponent(component, event, helper,'c:DPM_NotificationModal',parameters);
                    return false;
                }
            }
        }
        return true;
    },
    diversityDataRaceCheck : function(component,event,helper,lstRaces) {
        if(!lstRaces.includes(component.get('v.DPMEmployee.DPM_Race__c'))) {
            component.set('v.otherRace',component.get('v.DPMEmployee.DPM_Race__c'));
            component.set('v.DPMEmployee.DPM_Race__c','Two or more races');
        }
    },
    diversityDataEthnicityCheck : function(component,event,helper,lstEthnicities) {
        if(!lstEthnicities.includes(component.get('v.DPMEmployee.DPM_Ethnicity__c'))) {
            component.set('v.otherEthnicity',component.get('v.DPMEmployee.DPM_Ethnicity__c'));
            component.set('v.DPMEmployee.DPM_Ethnicity__c','Other');
        }
    },
    addToArray : function(varArray,elementToAdd) {
        if(Array.isArray(elementToAdd)) {
            varArray.push(...elementToAdd);
        } else {
            varArray.push(elementToAdd);
        }
        return varArray;
    },
    setDiversityDataByCountry : function(component,event,helper) {
        let lstDiversityData = component.get('v.diversityData');
        for(let varDiversityData of lstDiversityData) {
            let lstLanguageOptions = ['--None--'];
            let lstRaceOptions = ['--None--'];
            let lstEthnicityOptions = ['--None--'];
            if(varDiversityData.MasterLabel == component.get('v.DPMEmployee.DPM_Country__c')) { 
                if(!$A.util.isEmpty(varDiversityData.DPM_Available_Languages__c)) {
                    component.set('v.languageList',helper.generatePicklistOptions(lstLanguageOptions.concat((varDiversityData.DPM_Available_Languages__c).split(';'))));
                }                
                if(!$A.util.isEmpty(varDiversityData.DPM_Available_Races__c)) {
                    component.set('v.raceList',helper.generatePicklistOptions(lstRaceOptions.concat((varDiversityData.DPM_Available_Races__c).split(';'))));
                }  
                if(!$A.util.isEmpty(varDiversityData.DPM_Available_Ethnicities__c)) {
                    component.set('v.ethnicityList',helper.generatePicklistOptions(lstEthnicityOptions.concat((varDiversityData.DPM_Available_Ethnicities__c).split(';'))));
                } 
                if(!$A.util.isEmpty(component.get('v.DPMEmployee.DPM_Race__c'))) {
                    helper.diversityDataRaceCheck(component, event, helper, (varDiversityData.DPM_Available_Races__c).split(';'));
                }
                if(!$A.util.isEmpty(component.get('v.DPMEmployee.DPM_Ethnicity__c'))) {
                    helper.diversityDataEthnicityCheck(component, event, helper, (varDiversityData.DPM_Available_Ethnicities__c).split(';'));
                }
                break;
            }
        }
    },
    clearDiversityData : function(component) {
        component.set('v.DPMEmployee.DPM_Race__c','');
        component.set('v.DPMEmployee.DPM_Ethnicity__c','');
        component.set('v.otherEthnicity','');
        component.set('v.otherRace','');
        component.set('v.DPMEmployee.DPM_US_Military__c',false);
    },
})