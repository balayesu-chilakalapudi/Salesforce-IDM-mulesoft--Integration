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
    },
    getProficiencyValues : function(component, event, helper) {         
        helper.getPicklistValuesFromDPM(component, helper, 'DPM_Proficiency_1__c');
    },
    getCurrentPersonRole : function(component, event, helper) {
        let initAction = component.get('c.currentPersonRole');
        initAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var personObj = response.getReturnValue();
                if(personObj.RE_IsAdmin__c /*|| personObj.RE_User__c == $A.get("$SObjectType.CurrentUser.Id")*/){
                    component.set("v.isRetailerAdmin",true);
                }
                
            }
        });
        $A.enqueueAction(initAction);
                
    },
    getW9FlagValues :function(component, event, helper) {  
        var picklistOptions =[];
        picklistOptions.push(
            {
                label:'Yes',
                value:'y'
            },
            {
                label:'No',
                value:'N'
            },
            {
                label:'Error',
                value:'E'
            }
        );
            component.set('v.w9flagList',picklistOptions);
        helper.getMaxHireDate(component);
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
                component.set('v.countryList',helper.generatePicklistOptions(lstCountries,true));
                component.set('v.mapCountryWithStates',varMapCountryToStateOptions);
                helper.setStateList(component,'idWorkAddress');
                helper.setStateList(component,'home');
            }
        });
        $A.enqueueAction(countryStatesAction);
    },
    getPicklistValuesFromDPM : function(component, helper, strAPIName) {
        let initAction = component.get('c.getPicklistValues');
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
                    case 'DPM_Proficiency_1__c':
                        component.set('v.DPMProficiency',helper.generatePicklistOptions(picklistValues));
                        break;
                    default:
                        break;
                }
                //Do not wait for Diversity Data to load in case of Admin
                if(component.get('v.mode') == 'admin') {
                    helper.hideSpinner(component);
                }
            }
        });
        $A.enqueueAction(initAction);
    },
    getPicklistValuesForPositions : function(component, helper) {
        var initPositionAction = component.get('c.getAllJobPositions');
        let accountId=null;
        try{
        accountId=component.get('v.personRole').RE_Account__c;
        console.log('accountId:'+accountId);
        }catch(err){
            console.log(err.stack);
        }
        initPositionAction.setParams({'retailer_storeId':accountId});
        initPositionAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let varAllJobPositions = response.getReturnValue();
                let varJobPositions = ['--None--'];
                let varPrimaryPositions = [];
                let varOwnerPositions = ['--None--'];
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
                
                //check if positionsList contains all employee positions, else add it to prevent country filter              
                let personRole=component.get("v.personRole");
                let positionsList=component.get("v.positionsList");
                if(!$A.util.isEmpty(personRole.DPM_Job_Positions__r )){
                    for(let position of personRole.DPM_Job_Positions__r){
                        if(position.DPM_Position_Title__c!=null &&
                           position.DPM_Position_Title__c!='' &&
                           !positionsList.includes({'text':position.DPM_Position_Title__c,'value':position.DPM_Position_Title__c})){
                            positionsList.push({'text':position.DPM_Position_Title__c,'value':position.DPM_Position_Title__c});
                        }
                    }
                }
                component.set("v.positionsList",positionsList);
               
                component.set('v.primaryPositionsList',varPrimaryPositions);
                component.set('v.incentiveEligiblePositionsList',varIncentiveEligiblePositions);
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
            "mode":(type=='error'?'sticky':'dismissible'),
            "duration":'10000'
        });
        toastEvent.fire();        
    },
    showSpinner : function(component) {
        $A.util.removeClass(component.find('idSpinner'),'slds-hide');
    },
    hideSpinner : function(component) {
        $A.util.addClass(component.find('idSpinner'),'slds-hide');
    },    
    generatePicklistOptions : function(lstPicklistValues,labelOrText) {
        let picklistOptions = [];
        for(let picklistValue of lstPicklistValues) {
            if(labelOrText) {
                picklistOptions.push(
                    {
                        label:picklistValue,
                        value:(picklistValue=='--None--'?'':picklistValue)
                    }
                );
            } else {
                picklistOptions.push(
                    {
                        text:picklistValue,
                        value:(picklistValue=='--None--'?'':picklistValue)
                    }
                );
            }            
        }
        return picklistOptions;
    },
    getMaxHireDate : function(component) {
        console.log('getMaxHireDate running');
        let today = new Date();
        let month = today.getMonth() + 3;
        if (month < 10) {month = '0' + month;}
        let date = today.getDate();
        if (date < 10) {date = '0' + date;}
        let todaysDate = today.getFullYear() + '-' + month + '-' + date;
        console.log('todaysDate:'+todaysDate);
        component.set('v.w9MaxDate',todaysDate);
       // return todaysDate;
    },
    closeModal : function(component) {
        component.destroy();
    },
    setStateList : function(component,type) {        
        let varMapCountryToStateOptions = component.get('v.mapCountryWithStates');
        if(type=='idWorkAddress') {
            if($A.util.isEmpty(component.get('v.personRole.DPM_Work_Address_Country__c'))) {
                component.set('v.stateListWork',[]);
            } else {
                component.set('v.stateListWork',varMapCountryToStateOptions[component.get('v.personRole.DPM_Work_Address_Country__c')]);
            }
        } else {
            if($A.util.isEmpty(component.get('v.personRole.RE_Contact__r.MailingCountry'))) {
                component.set('v.stateList',[]);
            } else {
                component.set('v.stateList',varMapCountryToStateOptions[component.get('v.personRole.RE_Contact__r.MailingCountry')]);
            }
        }
    },
    checkCustomValidity : function(component,changedComponentId,changedComponent) {
        if(changedComponentId == 'idHomeAddress' && component.get('v.personRole.RE_Contact__r.MailingCountry') != 'Mexico') {
            if($A.util.isEmpty(component.get('v.personRole.RE_Contact__r.MailingStreet'))) {
                changedComponent.setCustomValidityForField("Enter Home Street","street");
            }  else {
                changedComponent.setCustomValidityForField("","street");
            }          
            if($A.util.isEmpty(component.get('v.personRole.RE_Contact__r.MailingCity'))) {
                changedComponent.setCustomValidityForField("Enter Home City","city");
            } else {
                changedComponent.setCustomValidityForField("","city");
            }
            if($A.util.isEmpty(component.get('v.personRole.RE_Contact__r.MailingState'))) {
                changedComponent.setCustomValidityForField("Select Home State/Province","province");
            } else {
                changedComponent.setCustomValidityForField("","province");
            }
            if($A.util.isEmpty(component.get('v.personRole.RE_Contact__r.MailingPostalCode'))) {
                changedComponent.setCustomValidityForField("Enter Home Zip/Postal Code","postalCode");
            } else {
                changedComponent.setCustomValidityForField("","postalCode");
                if(component.get('v.personRole.RE_Contact__r.MailingCountry')=='United States') {
                    let zipRegexFormatUS = new RegExp($A.get("$Label.c.DPM_PostalCode_US_Format"));
                    if(!(component.get('v.personRole.RE_Contact__r.MailingPostalCode')).match(zipRegexFormatUS)) {
                        changedComponent.setCustomValidityForField("Home Zip/PostalCode is not valid.","postalCode");
                    }
                }
                if(component.get('v.personRole.RE_Contact__r.MailingCountry')=='Canada') {
                    let zipRegexFormatCAN = new RegExp($A.get("$Label.c.DPM_PostalCode_CAN_Format"));
                    if(!(component.get('v.personRole.RE_Contact__r.MailingPostalCode')).match(zipRegexFormatCAN)) {
                        changedComponent.setCustomValidityForField("Home Zip/PostalCode is not valid.","postalCode");
                    }
                }
                if(component.get('v.personRole.MailingCountry')=='Mexico') {
                    let zipRegexFormatCAN = new RegExp($A.get("$Label.c.DPM_PostalCode_Mexican_Format"));
                    if(!(component.get('v.personRole.DPM_Work_Address_Zip_Postal_Code__c')).match(zipRegexFormatCAN)) {
                        changedComponent.setCustomValidityForField("Work Zip/PostalCode is not valid.","postalCode");
                    }
                    
                }
            }
            if($A.util.isEmpty(component.get('v.personRole.RE_Contact__r.MailingCountry'))) {
                changedComponent.setCustomValidityForField("Select Home Country","country");
            } else {
                changedComponent.setCustomValidityForField("","country");
            }
        }   
        if(changedComponentId == 'idWorkAddress') {            
            changedComponent.setCustomValidityForField("","postalCode");
            if(component.get('v.personRole.DPM_Work_Address_Country__c')=='United States') {
                let zipRegexFormatUS = new RegExp($A.get("$Label.c.DPM_PostalCode_US_Format"));
                if(!(component.get('v.personRole.DPM_Work_Address_Zip_Postal_Code__c')).match(zipRegexFormatUS)) {
                    changedComponent.setCustomValidityForField("Work Zip/PostalCode is not valid.","postalCode");
                }
            }
            if(component.get('v.personRole.DPM_Work_Address_Country__c')=='Canada') {
                let zipRegexFormatCAN = new RegExp($A.get("$Label.c.DPM_PostalCode_CAN_Format"));
                if(!(component.get('v.personRole.DPM_Work_Address_Zip_Postal_Code__c')).match(zipRegexFormatCAN)) {
                    changedComponent.setCustomValidityForField("Work Zip/PostalCode is not valid.","postalCode");
                }
            }
            if(component.get('v.personRole.DPM_Work_Address_Country__c')=='Mexico') {
                let zipRegexFormatCAN = new RegExp($A.get("$Label.c.DPM_PostalCode_Mexican_Format"));
                if(!(component.get('v.personRole.DPM_Work_Address_Zip_Postal_Code__c')).match(zipRegexFormatCAN)) {
                    changedComponent.setCustomValidityForField("Work Zip/PostalCode is not valid.","postalCode");
                }
            }
            
        }
    },
    getMaxHireDate : function() {
        let maxDate = new Date();
        let month = maxDate.getMonth();
        let date = maxDate.getDate();
        let todaysDate = maxDate.getFullYear() + '-' + month + '-' + date;
        return todaysDate;
    },
    viewTerminationMessageModal:function(component,event,helper,strModalBody){  
       try {            
           //show message
            var msgEvt=component.getEvent('dpmTerminationDateMessagesEvt');            
            msgEvt.setParams({"strModalBody":strModalBody });
            msgEvt.fire();
        }catch(err){
            console.log('ERROR:'+err.stack);
        }
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
    getAccounts : function(component,event,helper) {
        var getAccountAction = component.get('c.getDealerships');
        getAccountAction.setParams({
            "isSupp" : component.get("v.IsSupplier") 
        });
        getAccountAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let varAllDealerships = response.getReturnValue();
                component.set('v.dealersList',varAllDealerships);
                let varStoreIdNames = [];
                for(let dealership of varAllDealerships) {					
                    varStoreIdNames.push(dealership.Name+' - '+dealership.Retailer__c);
                }
                component.set('v.accountsList',varStoreIdNames);                
            }
        });
        $A.enqueueAction(getAccountAction);
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
    getDiversityDataOptions : function(component, event, helper) {
        let diversityDataAction = component.get('c.getDiversityData');
        diversityDataAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let lstDiversityData = response.getReturnValue();
                component.set('v.diversityData',lstDiversityData);
                helper.setDiversityDataByCountry(component,event,helper);
            }
            helper.hideSpinner(component);
        });
        $A.enqueueAction(diversityDataAction);
    }, 
    diversityDataRaceCheck : function(component,event,helper,lstRaces) {
        if(!lstRaces.includes(component.get('v.personRole.RE_Contact__r.DPM_Race__c'))) {
            component.set('v.otherRace',component.get('v.personRole.RE_Contact__r.DPM_Race__c'));
            component.set('v.personRole.RE_Contact__r.DPM_Race__c','Two or more races');
        }
    },
    diversityDataEthnicityCheck : function(component,event,helper,lstEthnicities) {
        if(!lstEthnicities.includes(component.get('v.personRole.RE_Contact__r.DPM_Ethnicity__c'))) {
            component.set('v.otherEthnicity',component.get('v.personRole.RE_Contact__r.DPM_Ethnicity__c'));
            component.set('v.personRole.RE_Contact__r.DPM_Ethnicity__c','Other');
        }
    },
    setDiversityDataByCountry : function(component,event,helper) {
        let lstDiversityData = component.get('v.diversityData');
        for(let varDiversityData of lstDiversityData) {
            let lstLanguageOptions = ['--None--'];
            let lstRaceOptions = ['--None--'];
            let lstEthnicityOptions = ['--None--'];
            if(varDiversityData.MasterLabel == component.get('v.personRole.RE_Contact__r.MailingCountry')) { 
                if(!$A.util.isEmpty(varDiversityData.DPM_Available_Languages__c)) {
                    component.set('v.languageList',helper.generatePicklistOptions(lstLanguageOptions.concat((varDiversityData.DPM_Available_Languages__c).split(';'))));
                }                
                if(!$A.util.isEmpty(varDiversityData.DPM_Available_Races__c)) {
                    component.set('v.raceList',helper.generatePicklistOptions(lstRaceOptions.concat((varDiversityData.DPM_Available_Races__c).split(';'))));
                }  
                if(!$A.util.isEmpty(varDiversityData.DPM_Available_Ethnicities__c)) {
                    component.set('v.ethnicityList',helper.generatePicklistOptions(lstEthnicityOptions.concat((varDiversityData.DPM_Available_Ethnicities__c).split(';'))));
                } 
                if(!$A.util.isEmpty(component.get('v.personRole.RE_Contact__r.DPM_Race__c')) && !$A.util.isEmpty(varDiversityData.DPM_Available_Races__c)) {
                    helper.diversityDataRaceCheck(component, event, helper, (varDiversityData.DPM_Available_Races__c).split(';'));
                }
                if(!$A.util.isEmpty(component.get('v.personRole.RE_Contact__r.DPM_Ethnicity__c')) && !$A.util.isEmpty(varDiversityData.DPM_Available_Ethnicities__c)) {
                    helper.diversityDataEthnicityCheck(component, event, helper, (varDiversityData.DPM_Available_Ethnicities__c).split(';'));
                }
                break;
            }
        }
    },
    clearDiversityData : function(component) {
        component.set('v.personRole.RE_Contact__r.DPM_Race__c','');
        component.set('v.personRole.RE_Contact__r.DPM_Ethnicity__c','');
        component.set('v.otherEthnicity','');
        component.set('v.otherRace','');
        component.set('v.personRole.RE_Contact__r.DPM_US_Military__c',false);
    },
     clearSSNData : function(component) {
        component.set('v.languageList','');
        component.set('v.personRole.RE_Contact__r.DPM_SSNLastFour','');
    },
    clearLangData : function(component,event,helper) {
        component.set('v.personRole.RE_Contact__r.DPM_Language_1__c','');
        component.set('v.personRole.RE_Contact__r.DPM_Language_2__c','');
        component.set('v.personRole.RE_Contact__r.DPM_Language_3__c','');
        component.set('v.personRole.RE_Contact__r.DPM_Proficiency_1__c','');
        component.set('v.personRole.RE_Contact__r.DPM_Proficiency_2__c','');
        component.set('v.personRole.RE_Contact__r.DPM_Proficiency_3__c','');
        let lstDiversityData = component.get('v.diversityData');
        let lstLanguageOptions = ['--None--'];
        component.set('v.languageList',helper.generatePicklistOptions(lstLanguageOptions.concat((lstDiversityData[0].DPM_Available_Languages__c).split(';'))));
    },
    addToArray : function(varArray,elementToAdd) {
        if(Array.isArray(elementToAdd)) {
            varArray.push(...elementToAdd);
        } else {
            varArray.push(elementToAdd);
        }
        return varArray;
    },
    showSpinner : function(component) {
        $A.util.removeClass(component.find('idSpinner'),'slds-hide');
    },
    hideSpinner : function(component) {
        $A.util.addClass(component.find('idSpinner'),'slds-hide');
    },
    getCurrentDealership : function(component, event, helper) {
        var accountAction = component.get("c.getCurrentAccount");
        accountAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let currentAccount = response.getReturnValue();
                component.set('v.account',currentAccount);     
                console.log('country:'+currentAccount.Country__r.Name);      
            }
        });
        $A.enqueueAction(accountAction);
    },
})