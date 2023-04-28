({
	doInit : function(component, event, helper) {
        helper.getSuffixList(component, event, helper);
        helper.getStateCountryValues(component, event, helper);
        helper.getAllJobPositions(component, event, helper);
        helper.getAccounts(component,event,helper);
	},
    close : function(component, event, helper) {
        helper.closeModal(component);
    },
    search : function(component, event, helper) {
        if(helper.validateInputs(component, event, helper)) {
            let dpmSearchEvent = component.getEvent("retailerAdminSearchEvent"); 
            dpmSearchEvent.setParams({
                "searchFields" : component.get('v.searchFields')
            });
            dpmSearchEvent.fire();
        } else {
            helper.showToast('error','Please indicate either a name, an email or a job position to start the search.');
        }       
    },
    handleChange: function (component, event) {
        var selectedOptionValue = event.getParam("value");
        component.set("v.searchFields.jobPosition",JSON.stringify(selectedOptionValue));
    },
    handleAccountChange : function(component, event, helper) {
        if($A.util.isEmpty(component.get('v.selectedAccount'))) {
            component.set('v.searchFields.store_SFId','');
        } else {
            let selectedAccount = component.get('v.selectedAccount');
            let selectedAccountName = selectedAccount.split(' - ')[0];
            let selectedAccountCode = selectedAccount.split(' - ')[1];
            let allAccounts = component.get('v.dealersList');
            for(let account of allAccounts) {
                if(account.Name == selectedAccountName && account.Retailer__c == selectedAccountCode) {
                    component.set('v.searchFields.store_SFId',account.Id);
                    break;
                }
            }
        }
    },
})