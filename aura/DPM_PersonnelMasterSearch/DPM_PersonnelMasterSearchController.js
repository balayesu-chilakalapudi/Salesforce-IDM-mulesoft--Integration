({
    doInit: function (component, event, helper) {
        helper.getSuffixList(component, event, helper);
        helper.getStateCountryValues(component, event, helper);
        helper.getAllJobPositions(component, event, helper);
        helper.getAccounts(component, event, helper);
    },
    close: function (component, event, helper) {
        helper.closeModal(component);
    },
    search: function (component, event, helper) {
        try {
            let searchFields = component.get("v.searchFields");
            let ssn = searchFields.SSN;
            if (ssn != null) {
                if (ssn.includes('-')) {
                    ssn = ssn.replace(/-/g, '');
                }
                searchFields.SSN = ssn;
                component.set('v.searchFields', searchFields);
            }
            if (component.get('v.searchFields').VPID != null || helper.validateInputs(component, event, helper) || (component.get('v.searchFields').SSN != null && component.get('v.searchFields').SSN != '')) {
                let dpmSearchEvent = component.getEvent("searchEvent");
                dpmSearchEvent.setParams({
                    "searchFields": component.get('v.searchFields')
                });
                dpmSearchEvent.fire();
            } else {
                helper.showToast('error', 'Please indicate either a name, an email or a store to start the search.');
            }
        } catch (err) {
            console.log(err.stack);
        }
    },
    handleChange: function (cmp, event) {
        // This will contain an array of the "value" attribute of the selected options
        var selectedOptionValue = event.getParam("value");
        cmp.set("v.searchFields.jobPosition", JSON.stringify(selectedOptionValue));
        //alert("Option selected with value: '" + cmp.get("v.searchFields.jobPosition"));
    },
    handleAccountChange: function (component, event, helper) {
        if ($A.util.isEmpty(component.get('v.selectedAccount'))) {
            component.set('v.searchFields.store_SFId', '');
        } else {
            let selectedAccount = component.get('v.selectedAccount');
            let arrSelectdAccount = selectedAccount.split(' - ');
            let selectedAccountName = arrSelectdAccount[0];  //get first indexed values as name			
            let selectedAccountCode = arrSelectdAccount[arrSelectdAccount.length - 1];  //get last indexed value as Retailer code			
            let allAccounts = component.get('v.dealersList');
            for (let account of allAccounts) {
                //Some account name has more than two hyphens				   
                if ((account.Name).startsWith(selectedAccountName) && account.Retailer__c == selectedAccountCode) {
                    component.set('v.searchFields.store_SFId', account.Id);
                    break;
                }
            }
        }
    },
    formatSSN: function (component, helper, event) {
        try {
            var validity = component.find("ssninput").get("v.value");
            console.log('-----------' + validity)
            var val = validity.replace(/\D/g, '');
            var sizes = [3, 2, 4];
            var newVal = '';

            for (var i in sizes) {
                if (val.length > sizes[i]) {
                    newVal += val.substr(0, sizes[i]) + '-';
                    val = val.substr(sizes[i]);
                }
            }
            newVal += val;
            console.log('newVal--' + newVal);
            let searchFields = component.get("v.searchFields");
            searchFields.SSN = newVal;
            component.set("v.searchFields", searchFields);
        } catch (err) {
            console.log(err.stack);
        }
    },
    searchEmployeeCreationStatus: function (component, event, helper) {
        try {
            let searchFields = component.get("v.searchFields");
            let ssn = searchFields.SSN;
            if (ssn != null) {
                if (ssn.includes('-')) {
                    ssn = ssn.replace(/-/g, '');
                }
                searchFields.SSN = ssn;
                component.set('v.searchFields', searchFields);
            }
            if (!$A.util.isEmpty(component.get('v.selectedAccount'))) {
                component.set('v.searchFields.EmployeeCreationStatus', true);
                let dpmSearchEvent = component.getEvent("searchEvent");
                dpmSearchEvent.setParams({
                    "searchFields": component.get('v.searchFields')
                });
                dpmSearchEvent.fire();
            } else {
                helper.showToast('error', 'Please indicate a store to start the search.');
            }
        } catch (err) {
            console.log(err.stack);
        }
    }
})