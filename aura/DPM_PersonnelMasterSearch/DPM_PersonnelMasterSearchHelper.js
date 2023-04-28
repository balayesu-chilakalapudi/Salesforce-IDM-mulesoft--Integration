({
    closeModal : function(component) {
        component.destroy();
    },  
    getSuffixList : function(component, event, helper) {
        helper.getPicklistValuesFromDPM(component, helper, 'DPM_Suffix__c');
    },
    getPicklistValuesFromDPM : function(component, helper, strAPIName) {
        var initAction = component.get('c.getPicklistValues');
        initAction.setParams({strFieldName:strAPIName});
        initAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let picklistValues = response.getReturnValue();
                switch(strAPIName) {
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
    getStateCountryValues : function(component, event, helper) {
        let countryStatesAction = component.get('c.getCorpCountriesAndStates');
        countryStatesAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let varMapCountryStates = response.getReturnValue();
                let lstCountries = ['--None--'];
                for(let varCountry of Object.keys(varMapCountryStates)) {
                    lstCountries.push(varCountry);
                }
                component.set('v.countryList',helper.generatePicklistOptions(lstCountries.sort(),true));
            }
        });
        $A.enqueueAction(countryStatesAction);
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
    generatePicklistOptionsForJP : function(lstPicklistValues) {
        let picklistOptions = [];
        for(let picklistValue of lstPicklistValues) {
            picklistOptions.push(
                {
                    label:picklistValue,
                    value:(picklistValue=='--None--'?'':picklistValue)
                }
            );
        }
        return picklistOptions;
    },

    getAllJobPositions : function(component,event,helper) {
        let IdAccount=component.get('v.searchFields.store_SFId');
        let params={'retailer_storeId':IdAccount};	
        var initPositionAction = component.get('c.getAllJobPositions');
        initPositionAction.setParams(params);
        initPositionAction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let varAllJobPositions = response.getReturnValue();
                let varJobPositions = ['--None--'];
                for(let jobPosition of varAllJobPositions) {					
                    if(!jobPosition.DPM_Owner_Position__c) {                        
                        varJobPositions.push(jobPosition.MasterLabel);                   
                    }
                }
                component.set('v.positionsList',helper.generatePicklistOptionsForJP(varJobPositions));                
            }
        });
        $A.enqueueAction(initPositionAction);
    },
    getAccounts : function(component,event,helper) {
        var getAccountAction = component.get('c.getAllDealerships');
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
    validateInputs : function(component,event,helper) {
        if($A.util.isEmpty(component.get('v.searchFields.lastName')) && 
           $A.util.isEmpty(component.get('v.searchFields.email')) &&
           $A.util.isEmpty(component.get('v.selectedAccount'))
          ) {
            return false;
        }
        return true;
    },
    showToast : function(type,message) {
        let toastEvent = $A.get("e.force:showToast");
        let title = (type=='error'?'Error!':(type=='success'?'Success!':'Warning!'));
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type":type
        });
        toastEvent.fire();        
    },
})