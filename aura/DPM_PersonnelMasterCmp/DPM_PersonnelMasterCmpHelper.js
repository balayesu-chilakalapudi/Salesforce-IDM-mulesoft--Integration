({
    viewNewEmployeeModal: function (component, event, helper) {
        let parameters = { "aura:id": "idNewEmployeeCmp", "fromPortal": component.get('v.fromPortal'), "corporatePermissions": component.get('v.corporatePermissions') };
        helper.createModal(component, 'c:DPM_NewRetailerEmployeeCmp', parameters);
    },
    viewExistingCheckModal: function (component, event, helper) {
        let parameters = { "aura:id": "idNewOrExistingEmployeeCmp" };
        helper.createModal(component, 'c:DPM_ExistingEmpCheckCmp', parameters);
    },
    viewNewEmployeeModalForSupplier: function (component, event, helper) {
        let parameters = { "aura:id": "idNewSuppEmployeeCmp", "fromPortal": component.get('v.fromPortal'), "corporatePermissions": component.get('v.corporatePermissions'), "mapDPMEmployee": component.get('v.mapDPMEmployee'), "IsSupplier": "true" };
        helper.createModal(component, 'c:DPM_NewRetailerEmployeeCmp', parameters);
    },
    createModal: function (component, componentName, parameters) {
        $A.createComponent(componentName, parameters, function (modal, status, errorMessage) {
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
    createBuySellComponent: function (component, event, helper) {
        let parameters = { "aura:id": "idBuySell" };
        helper.createModal(component, 'c:DPM_BuySellProcessCmp', parameters);
    },
    sortDPMEmployeesByStatus: function (lstDPMEmployee) {
        var varInitiated = [];
        var varSubmitted = [];
        if (!$A.util.isEmpty(lstDPMEmployee)) {
            if (lstDPMEmployee.length > 0) {
                lstDPMEmployee.forEach(function (dpmEmployee) {
                    if (!$A.util.isEmpty(dpmEmployee.DPM_SSN_SIN__c)) {
                        let varLastFourSSN = (dpmEmployee.DPM_SSN_SIN__c).substring(5, 9);
                        if (dpmEmployee.DPM_Country__c == 'Canada') {
                            varLastFourSSN = (dpmEmployee.DPM_SSN_SIN__c).substring(6, 9);
                            dpmEmployee.DPM_SSN_LastFour = '***-***-' + varLastFourSSN;
                        } else {
                            varLastFourSSN = (dpmEmployee.DPM_SSN_SIN__c).substring(5, 9);
                            dpmEmployee.DPM_SSN_LastFour = '***-**-' + varLastFourSSN;
                        }
                    }
                    switch (dpmEmployee.DPM_Status__c) {
                        case 'Initiated':
                            varInitiated.push(dpmEmployee); break;
                        case 'Submitted':
                            varSubmitted.push(dpmEmployee); break;
                        case 'Submitted - Duplicate Not Confirmed':
                            varSubmitted.push(dpmEmployee); break;
                        case 'Submitted - Duplicate Confirmed':
                            varSubmitted.push(dpmEmployee); break;
                        case 'Approved':
                            varSubmitted.push(dpmEmployee); break;
                        case 'Pending Corporate Approval':
                            varSubmitted.push(dpmEmployee); break;
                        case 'Pending Retailer Admin Action':
                            varSubmitted.push(dpmEmployee); break;
                    }
                });
            }
        }
        return {
            initiated: varInitiated,
            submitted: varSubmitted
        }
    },
    fetchStoreEmployees: function (component, event, helper, origin) {
        var action = component.get("c.getExistingEmpRecords");
        let varSessionSettings = component.get('v.sessionSettings');
        if ($A.util.isEmpty(varSessionSettings.intLimit)) {
            varSessionSettings.intLimit = 50;
        }
        action.setParams({ strSessionSettings: JSON.stringify(varSessionSettings) });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let varLstEmployees = component.get('v.existingEmployeeList');
                if (origin != 'init') {
                    component.set('v.existingEmployeeList', varLstEmployees.concat(response.getReturnValue()));
                    if (component.get('v.existingEmployeeList.length') >= component.get('v.totalCount')) {
                        component.set('v.sessionSettings.showViewMore', false);
                    }
                } else {
                    component.set('v.existingEmployeeList', response.getReturnValue());
                }
                helper.fetchStoreEmployeeTotal(component, event, helper);
                helper.setSessionStorage(component);
                //   console.log('existingEmployeeList:'+component.get("v.existingEmployeeList"));
            } else if (state === "ERROR") {
                helper.handleError(response.getError());
            } else {
                // Handle other reponse states
            }
            helper.hideSpinner(component);
        });
        $A.enqueueAction(action);
    },
    fetchStoreEmployeeTotal: function (component, event, helper) {
        let fetchTotalAction = component.get('c.getTotalStoreEmployees');
        fetchTotalAction.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set('v.totalCount', response.getReturnValue());
                //console.log(component.get('v.existingEmployeeList.length'));
                //console.log(component.get('v.totalCount'));
                if (component.get('v.existingEmployeeList.length') >= component.get('v.totalCount')) {
                    component.set('v.sessionSettings.showViewMore', false);
                }
                //console.log(JSON.stringify(component.get('v.sessionSettings')));
            } else if (state === "ERROR") {
                helper.handleError(response.getError());
            } else {
                // Handle other reponse states
            }
            helper.hideSpinner(component);
        });
        $A.enqueueAction(fetchTotalAction);
    },
    fetchDPMEmployees: function (component, event, helper) {
        let fetchAction;
        if (component.get('v.fromPortal')) {
            fetchAction = component.get('c.getDPMEmployeeRecords');
        } else {
            fetchAction = component.get('c.getDPMEmployeeRecordsCorp');
        }
        fetchAction.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set('v.mapDPMEmployee', helper.sortDPMEmployeesByStatus(response.getReturnValue()));
            } else if (state === "ERROR") {
                helper.handleError(response.getError());
            } else {
                // Handle other reponse states
            }
            helper.hideSpinner(component);
        });
        $A.enqueueAction(fetchAction);
    },
    fetchCurrentEmployee: function (component, event, helper) {
        let action = component.get("c.currentPersonRole");
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let varCurrentEmployee = response.getReturnValue();
                component.set('v.hasAccess', varCurrentEmployee.RE_IsAdmin__c);
                if (!varCurrentEmployee.RE_IsAdmin__c) {
                    helper.showToast('warning', 'You are now logging in a store where you do not have Admin privileges - you can only maintain your own profile in this store.');
                }
                component.set('v.currentEmployee', response.getReturnValue());
                helper.getSessionStorage(component);
                helper.fetchStoreEmployees(component, event, helper, 'init');
            } else if (state === "ERROR") {
                helper.handleError(response.getError());
            } else {
                // Handle other reponse states
            }
            helper.hideSpinner(component);
        });
        $A.enqueueAction(action);
    },
    handleError: function (errors) {
        let message = 'Unknown error'; // Default error message
        // Retrieve the error message sent by the server
        if (errors && Array.isArray(errors) && errors.length > 0) {
            message = errors[0].message;
        }
        // Display the message
        if (message.includes('List has no rows')) {
            message = 'You do not have access to Digital Personnel Management.';
        }
        this.showToast('error', message);
    },
    showToast: function (type, message) {
        let toastEvent = $A.get("e.force:showToast");
        let title = (type == 'error' ? 'Error!' : (type == 'success' ? 'Success!' : 'Warning!'));
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type,
            "mode": "sticky"
        });
        toastEvent.fire();
    },
    showSpinner: function (component) {
        $A.util.removeClass(component.find('idSpinner'), 'slds-hide');
    },
    hideSpinner: function (component) {
        $A.util.addClass(component.find('idSpinner'), 'slds-hide');
    },
    setSessionStorage: function (component) {
        let varSessionSettings = component.get('v.sessionSettings');
        let varSession = 'DPM_sessionSettings_' + component.get('v.currentEmployee.Id');
        sessionStorage.setItem(varSession, JSON.stringify(varSessionSettings));
        //console.log(varSession+' '+sessionStorage.getItem(varSession));
    },
    getSessionStorage: function (component) {
        let varSession = 'DPM_sessionSettings_' + component.get('v.currentEmployee.Id');
        let varSessionSettings = sessionStorage.getItem(varSession);
        //console.log(varSession+' 123# '+varSessionSettings);
        if (!$A.util.isEmpty(varSessionSettings)) {
            component.set('v.sessionSettings', JSON.parse(varSessionSettings));
        }
    },
    viewReactivateExtendEmployeeModal: function (component, event, helper) {
        let varmapDPMEmployee = component.get("v.mapDPMEmployee");
        let parameters = { "aura:id": "idReactivateExtendEmployeeCmp", "fromPortal": component.get('v.fromPortal'), "mapDPMEmployee": component.get("v.mapDPMEmployee") };
        helper.createModal(component, 'c:DPM_ReactivateExtendRetailerEmployee', parameters);
    },
    viewSearchModal: function (component, event, helper) {
        let parameters = { "aura:id": "idSearchEmployeeCmp", "fromPortal": component.get('v.fromPortal'), "corporatePermissions": component.get("v.corporatePermissions") };
        helper.createModal(component, 'c:DPM_PersonnelMasterSearch', parameters);
    },
    handleSearchReport : function(component,event,helper,psnId,IsFromReport,isTerminateEmployee) {
        let searchFields=component.get("v.searchFields");
        searchFields.VPID = psnId;
        searchFields.retailerAdmin = false;
        searchFields.showInactiveEmployees = isTerminateEmployee;
        searchFields.primaryJobOnly = false;
        searchFields.fromPortal = false;
        component.set('v.searchFields',searchFields);
        component.set('v.sessionSettings.intLimit',$A.get("$Label.c.DPM_ExistingEmployeePaginationLimit"));
        component.set('v.sessionSettings.showViewMore',true);
        component.set('v.sessionSettings.intOffset',0);
    },
    searchForEmployee: function (component, event, helper, origin) {
        component.set('v.totalCount', 0);
        let searchAction = component.get("c.searchEmployees");
        searchAction.setParams({ strSessionSettings: JSON.stringify(component.get('v.sessionSettings')), strSearchFields: JSON.stringify(component.get('v.searchFields')) });
        searchAction.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let varLstEmployees = component.get('v.existingEmployeeList');
                let varSearchResults = response.getReturnValue();
                component.set('v.totalCount', varSearchResults.intTotalResults);
                if (component.get('v.IsFromReport')) {
                    component.set("v.blnIsIncentiveProfile", true);
                } else {
                    component.set("v.blnIsIncentiveProfile", varSearchResults.blnIsIncentiveProfile);
                }
                console.log('blnIsIncentiveProfile:' + varSearchResults.blnIsIncentiveProfile);
                if (origin == 'download') {
                    var lstRecords = [];
                    // console.log('data:'+JSON.stringify(varSearchResults.lstPersonRole));
                    //extract downloadable results
                    for (let existingEmployee of varSearchResults.lstPersonRole) {
                        //firstname mapping
                        let firstname = '';
                        if (existingEmployee.RE_Contact__r.DPM_Preferred_First_Name__c != null) {
                            firstname += existingEmployee.RE_Contact__r.DPM_Preferred_First_Name__c;
                        } else {
                            firstname += existingEmployee.RE_Contact__r.FirstName;
                        }

                        //active/terminated mapping
                        let active_terminated = '';
                        if (existingEmployee.RE_Psn_Active__c) {
                            active_terminated = 'Active';
                        } else {
                            active_terminated = 'Terminated';
                        }
                        let vpid = '';
                        if (existingEmployee.RE_Contact__r.PsnId__c != null) {
                            vpid = existingEmployee.RE_Contact__r.PsnId__c;
                        } else {
                            vpid = 'Not Available';
                        }
                        if (!varSearchResults.blnIsIncentiveProfile) {
                            lstRecords.push({
                                'Name': existingEmployee.RE_Contact__r.LastName + ' ' + firstname,
                                'VPID': vpid,
                                'StoreName': existingEmployee.RE_Account__r.Name + ' - ' + existingEmployee.RE_Account__r.Retailer__c,
                                'PrimaryJobPosition': existingEmployee.RE_Employee_Position__c,
                                'Active_Terminated': active_terminated,
                                'HireDate': existingEmployee.RE_Psn_Active_Date__c,
                                'PrimaryCDSID': existingEmployee.RE_Contact__r.Cds_Id__c,
                                'RetailerAdmin': existingEmployee.RE_IsAdmin__c,
                                'Owner': existingEmployee.DPM_Owner__c,
                                'Country': existingEmployee.RE_Contact__r.MailingCountry
                            });
                        } else {
                            //push incentive specific columns and fields                           
                            if (existingEmployee.RE_Contact__r.DPM_SSN__c != null) {
                                let varLastFourSSN = (existingEmployee.RE_Contact__r.DPM_SSN__c).substring(5, 9);
                                if (existingEmployee.RE_Contact__r.MailingCountry == 'Canada') {
                                    varLastFourSSN = (existingEmployee.RE_Contact__r.DPM_SSN__c).substring(6, 9);
                                    existingEmployee.RE_Contact__r.DPM_SSNLastFour = '***-***-' + varLastFourSSN;
                                } else {
                                    varLastFourSSN = (existingEmployee.RE_Contact__r.DPM_SSN__c).substring(5, 9);
                                    existingEmployee.RE_Contact__r.DPM_SSNLastFour = '***-**-' + varLastFourSSN;
                                }
                            } else {
                                existingEmployee.RE_Contact__r.DPM_SSNLastFour = 'Not Available';
                            }
                            /*if($A.util.isEmpty(existingEmployee.RE_Contact__r.DPM_W9_Flag__c)){
                                existingEmployee.RE_Contact__r.DPM_W9_Flag__c='Not Available';
                                
                            }
                            if($A.util.isEmpty(existingEmployee.RE_Contact__r.DPM_W9_Date__c)){
                                existingEmployee.RE_Contact__r.DPM_W9_Date__c='Not Available';
                                
                            }
                            if($A.util.isEmpty(existingEmployee.RE_Contact__r.DPM_W9_Reason__c)){
                                existingEmployee.RE_Contact__r.DPM_W9_Reason__c='Not Available';
                                
                            }*/
                            lstRecords.push({
                                'Name': existingEmployee.RE_Contact__r.LastName + ' ' + firstname,
                                'VPID': vpid,
                                'StoreName': existingEmployee.RE_Account__r.Name + ' - ' + existingEmployee.RE_Account__r.Retailer__c,
                                'SSN': existingEmployee.RE_Contact__r.DPM_SSNLastFour,
                                'Active_Terminated': active_terminated,
                                'HireDate': existingEmployee.RE_Psn_Active_Date__c,
                                'W9_Flag': existingEmployee.RE_Contact__r.DPM_W9_Flag__c,
                                'W9_Date': existingEmployee.RE_Contact__r.DPM_W9_Date__c,
                                'W9_Reason': existingEmployee.RE_Contact__r.DPM_W9_Reason__c
                            });
                        }
                    }
                    // console.log('lstRecords:'+JSON.stringify(lstRecords));
                    let varfileName = '';
                    let varfileHeader = '';
                    if (!varSearchResults.blnIsIncentiveProfile) {
                        varfileName = 'CorpAdminSearchResults.csv';
                        varfileHeader = 'NAME,VPID,STORE NAME -ID,PRIMARY JOB POSITION,ACTIVE/TERMINATED,HIRE DATE,PRIMARY CDSID,RETAILER ADMIN,OWNER,COUNTRY';
                    } else {
                        varfileName = 'IncentiveProfileSearchResults.csv';
                        varfileHeader = 'NAME,VPID,STORE NAME -ID,SSN,ACTIVE/TERMINATED,HIRE DATE,W9 FLAG,W9 DATE,W9 REASON';
                    }
                    // let varfileName='CorpAdminSearchResults.csv';
                    // let varfileHeader='NAME,VPID,STORE NAME -ID,PRIMARY JOB POSITION,ACTIVE/TERMINATED,HIRE DATE,PRIMARY CDSID,RETAILER ADMIN,OWNER,COUNTRY';
                    let parameters = { "aura:id": "idDPM_csvExport", "fromPortal": component.get('v.fromPortal'), "records": lstRecords, "fileName": varfileName, "fileHeader": varfileHeader };
                    helper.createModal(component, 'c:DPM_csvExport', parameters);
                } else {
                    for (let varPersonRole of varSearchResults.lstPersonRole) {
                        let varJobPositions = varPersonRole.DPM_Job_Positions__r;
                        if (!$A.util.isEmpty(varJobPositions)) {
                            for (let position of varJobPositions) {
                                if (!$A.util.isEmpty(position.DPM_Position_End_Date__c)) {
                                    position.blnAlreadyTerminated = true;
                                }
                            }
                        }
                        if (!$A.util.isEmpty(varPersonRole.RE_Contact__r.DPM_SSN__c)) {
                            let varLastFourSSN = (varPersonRole.RE_Contact__r.DPM_SSN__c).substring(5, 9);
                            if (varPersonRole.RE_Contact__r.MailingCountry == 'Canada') {
                                varLastFourSSN = (varPersonRole.RE_Contact__r.DPM_SSN__c).substring(6, 9);
                                varPersonRole.RE_Contact__r.DPM_SSNLastFour = '***-***-' + varLastFourSSN;
                            } else {
                                varLastFourSSN = (varPersonRole.RE_Contact__r.DPM_SSN__c).substring(5, 9);
                                varPersonRole.RE_Contact__r.DPM_SSNLastFour = '***-**-' + varLastFourSSN;
                            }
                            varPersonRole.RE_Contact__r.DPM_SSN__c = helper.formatSSN(varPersonRole.RE_Contact__r.DPM_SSN__c, varPersonRole.RE_Contact__r.MailingCountry);
                        } else {
                        }
                    }
                    if (origin != 'init') {
                        component.set('v.existingEmployeeList', varLstEmployees.concat(varSearchResults.lstPersonRole));
                        if (component.get('v.existingEmployeeList.length') >= component.get('v.totalCount')) {
                            component.set('v.sessionSettings.showViewMore', false);
                        }
                    } else {
                        console.log('varSearchResults.lstPersonRole-=-');
                        console.log(varSearchResults.lstPersonRole);
                        component.set('v.existingEmployeeList', varSearchResults.lstPersonRole);
                        if (component.get('v.existingEmployeeList.length') >= component.get('v.totalCount')) {
                            component.set('v.sessionSettings.showViewMore', false);
                        }
                        if ($A.util.isEmpty(varSearchResults.lstPersonRole)) {
                            helper.showToast('error', 'No employee matches your search criteria. Please change the search and try again.');
                            return;
                        }
                    }
                    let searchEmployeeColumns = [];
                    if (!component.get("v.blnIsIncentiveProfile")) {
                        searchEmployeeColumns = [
                            { 'label': 'Name', 'name': 'Name' },
                            { 'label': 'VPID', 'name': 'VPID' },
                            { 'label': 'Store Name - Id', 'name': 'Store' },
                            { 'label': 'Primary Job Position', 'name': 'Job_Position' },
                            { 'label': 'Active/Terminated', 'name': 'RE_Psn_Active__c' },
                            { 'label': 'Hire Date', 'name': 'Hire_Date' },
                            { 'label': 'Primary CDSID', 'name': 'CDSID' },
                            { 'label': 'Retailer Admin', 'name': 'Retailer_Admin' },
                            { 'label': 'Owner', 'name': 'Owner' },
                            { 'label': 'Country', 'name': 'country' }
                        ];
                    } else {
                        searchEmployeeColumns = [
                            { 'label': 'Name', 'name': 'Name' },
                            { 'label': 'VPID', 'name': 'VPID' },
                            { 'label': 'Store Name - Id', 'name': 'Store' },
                            { 'label': 'SSN', 'name': 'SSN' },
                            { 'label': 'Active/Terminated', 'name': 'RE_Psn_Active__c' },
                            { 'label': 'Hire Date', 'name': 'Hire_Date' },
                            { 'label': 'W9 Flag', 'name': 'W9_Flag' },
                            { 'label': 'W9 Date', 'name': 'W9_Date' },
                            { 'label': 'W9 Reason', 'name': 'W9_Reason' }
                        ];
                    }

                    component.set('v.sessionSettings.existingEmployeeColumns', searchEmployeeColumns);
                    if (!$A.util.isEmpty(component.find('idSearchEmployeeCmp'))) {
                        component.find('idSearchEmployeeCmp').destroy();
                    }
                    component.set('v.showSearchResults', true);
                    component.set("v.showEmployeeCreationStatusSearchResults", false);
                    component.set('v.selectedTab', 'idSearchResults');
                    window.setTimeout(
                        $A.getCallback(function () {
                            helper.updateScroll(component, event, helper);
                        }), 500
                    );
                }
            } else if (state === "ERROR") {
                helper.handleError(response.getError());
            } else {
                // Handle other reponse states
            }
            helper.hideSpinner(component);
        });
        $A.enqueueAction(searchAction);
    },
    fetchCorporatePermissions: function (component, event, helper) {
        let corpAction = component.get("c.checkCorporatePermissions");
        corpAction.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let varCorpPermissions = response.getReturnValue();
                component.set('v.corporatePermissions', varCorpPermissions);
            } else if (state === "ERROR") {
                helper.handleError(response.getError());
            } else {
                // Handle other reponse states
            }
            helper.hideSpinner(component);
        });
        $A.enqueueAction(corpAction);
    },
    handleSearchEventHelper: function (component, event, helper) {
        if (component.get('v.searchFields').EmployeeCreationStatus) {
            helper.searchEmployeeCreationStatus(component, event, helper, 'init');
        } else {
            helper.searchForEmployee(component, event, helper, 'init');
        }
        event.stopPropagation();
    },
    updateScroll: function (component, event, helper) {
        if (component.find('idPMList')) {
            component.find('idPMList').getElement().scrollIntoView({ behavior: 'smooth' });
        }
    },
    updateScrollEmployeeCreationStatus: function (component, event, helper) {
        if (component.find('idEmployeeCreationStatus').getElement()) {
            component.find('idEmployeeCreationStatus').getElement().scrollIntoView({ behavior: 'smooth' });
        }
    },
    formatSSN: function (varSSN, varCountry) {
        if (varCountry == 'Canada') {
            varSSN = varSSN.substring(0, 3) + '-' + varSSN.substring(3, 6) + '-' + varSSN.substring(6, 9);
        } else {
            varSSN = varSSN.substring(0, 3) + '-' + varSSN.substring(3, 5) + '-' + varSSN.substring(5, 9);
        }
        //console.log('ssn123 '+varSSN);
        return varSSN;
    },
    getWorkflowAppLinks: function (component, event, helper, type) {
        var action = component.get('c.fetchWorkflowAppLinks');
        action.setParams({ type: type });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                component.set('v.appLinks', response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },
    viewRetailerAdminSearchModal: function (component, event, helper) {
        let parameters = { "aura:id": "idSearchEmployeeCmp", "fromPortal": component.get('v.fromPortal') };
        helper.createModal(component, 'c:DPM_RetailerAdminSearch', parameters);
    },
    handleRetailerAdminSearchEventHelper: function (component, event, helper) {
        helper.retailerAdminSearchForEmployee(component, event, helper);
        event.stopPropagation();
    },
    retailerAdminSearchForEmployee: function (component, event, helper) {
        // helper.showSpinner(component);
        let varSearchFields = component.get("v.retailerAdminSearchFields");
        let varSessionSettings = component.get("v.retailerAdminSessionSettings");
        varSearchFields.fromPortal = component.get('v.fromPortal');
        sessionStorage.setItem('retailerAdminSearchFields', JSON.stringify(varSearchFields));
        sessionStorage.setItem('retailerAdminSessionSettings', JSON.stringify(varSessionSettings));
        let searchAction = component.get("c.searchEmployees");
        let params = { strSessionSettings: JSON.stringify(component.get('v.retailerAdminSessionSettings')), strSearchFields: JSON.stringify(component.get('v.retailerAdminSearchFields')) };
        // console.log('params:'+JSON.stringify(params));
        searchAction.setParams(params);
        searchAction.setCallback(this, function (response) {
            var state = response.getState();
            console.log('state:' + state);
            if (state === "SUCCESS") {
                let varLstEmployees = component.get('v.existingEmployeeList');
                let varSearchResults = response.getReturnValue();
                if ($A.util.isEmpty(varSearchResults.lstJobPositions)) {
                    helper.showToast('error', 'No employee matches your search criteria. Please change the search and try again.');
                    return;
                } else {
                    let urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        "url": "/dpm-retailer-admin-search-results"
                    });
                    helper.hideSpinner(component);
                    urlEvent.fire();
                }
            } else if (state === "ERROR") {
                helper.handleError(response.getError());
            } else {
                // Handle other reponse states
            }
            helper.hideSpinner(component);
        });
        $A.enqueueAction(searchAction);
    },
    viewDMSIdWorkPhoneEmailReportModal: function (component, event, helper) {
        let parameters = { "aura:id": "idNewEmployeeCmp", "fromPortal": component.get('v.fromPortal'), "corporatePermissions": component.get('v.corporatePermissions') };
        helper.createModal(component, 'c:DPM_DMSIdWorkPhoneEmailReportModal', parameters);
    },
    searchEmployeeCreationStatus: function (component, event, helper, origin) {
        component.set('v.totalCount', 0);
        component.set("v.RetailerId", " Employee Creation Status");
        component.set("v.showEmployeeCreationStatusSearchResults", false);
        component.set('v.selectedTab', 'idInitiated');
        let searchAction = component.get("c.searchEmployeeCreationStatusAction");
        searchAction.setParams({ strSessionSettings: JSON.stringify(component.get('v.sessionSettings')), strSearchFields: JSON.stringify(component.get('v.searchFields')) });
        searchAction.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let varLstEmployees = component.get('v.existingEmployeeList');
                let varSearchResults = response.getReturnValue();
                component.set("v.RetailerId", "Employee Creation Status - "+varSearchResults.RetailerId);
                console.log('varSearchResults:' + JSON.stringify(varSearchResults));
                component.set('v.totalCount', varSearchResults.intTotalDPMEmployeeResults);
                /*if (origin == 'download') {
                    var lstRecords = [];
                    var myList = varSearchResults.lstDPMEmployees;
                    // check to make sure the list isn't null
                    if (myList != null) {
                        var listLength = myList.length;
                        for (var i = 0; i < listLength; i++) {
                            if (myList[i].DPM_Status__c == 'Initiated') {
                                myList[i].DPM_Status__c = 'Pending self-registration';
                            }
                            else if (myList[i].DPM_Status__c == 'Submitted') {
                                myList[i].DPM_Status__c = 'Pending Admin approval';
                            }
                            else if (myList[i].DPM_Status__c == 'Approved') {
                                myList[i].DPM_Status__c = 'Pending CDSID';
                            }
                            else if (myList[i].DPM_Status__c == 'Pending Corporate Approval') {
                                myList[i].DPM_Status__c = 'Pending Digital review';
                            }
                            else if (myList[i].DPM_Status__c == 'Pending Retailer Admin') {
                                myList[i].DPM_Status__c = 'Pending Admin Action';
                            }
                            else {
                                myList[i].DPM_Status__c = '';
                            }
                            lstRecords.push({
                                'First Name': myList[i].DPM_Legal_First_Name__c,
                                'Last Name': myList[i].DPM_Last_Name__c,
                                'Email': myList[i].DPM_Email__c,
                                'New/Activation': myList[i].DPM_Request_Type__c,
                                'Status': myList[i].DPM_Status__c
                            });
                        }
                        let varfileName = component.get("v.RetailerId")+'.csv';
                        let varfileHeader = 'First Name,Last Name,Email,New/Activation,Status';
                        let parameters = { "aura:id": "idDPM_csvExport", "fromPortal": component.get('v.fromPortal'), "records": lstRecords, "fileName": varfileName, "fileHeader": varfileHeader };
                        helper.createModal(component, 'c:DPM_csvExport', parameters);
                    }
                }//end download
                else {*/
                var actions = [
                    { label: 'View', name: 'view' }/*,
                    { label: 'Edit', name: 'edit' },
                    { label: 'Delete', name: 'delete' }*/
                ];
                    let searchEmployeeColumns = [
                        {label: '', type: 'action',typeAttributes: { rowActions: actions }}, 
                        { label: 'First Name', fieldName: 'DPM_Legal_First_Name__c', type: 'text', sortable: true },
                        { label: 'Last Name', fieldName: 'DPM_Last_Name__c', type: 'text', sortable: true },
                        { label: 'Email', fieldName: 'DPM_Email__c', type: 'text', sortable: false },
                        { label: 'Action', fieldName: 'DPM_Request_Type__c', type: 'text', sortable: false },
                        { label: 'Status', fieldName: 'DPM_Status__c', type: 'text', sortable: true }
                        
                    ];
                    component.set('v.sessionSettings.existingEmployeeColumns', searchEmployeeColumns);
                    if (origin != 'init') {

                        var myList = varSearchResults.lstDPMEmployees;
                        // check to make sure the list isn't null
                        if (myList != null) {
                            var listLength = myList.length;
                            for (var i = 0; i < listLength; i++) {
                                if (myList[i].DPM_Status__c == 'Initiated') {
                                    myList[i].DPM_Status__c = 'Pending self-registration';
                                }
                                else if (myList[i].DPM_Status__c == 'Submitted') {
                                    myList[i].DPM_Status__c = 'Pending Admin approval';
                                }
                                else if (myList[i].DPM_Status__c == 'Approved') {
                                    myList[i].DPM_Status__c = 'Pending CDSID';
                                }
                                else if (myList[i].DPM_Status__c == 'Pending Corporate Approval') {
                                    myList[i].DPM_Status__c = 'Pending Digital review';
                                }
                                else if (myList[i].DPM_Status__c == 'Pending Retailer Admin Action') {
                                    myList[i].DPM_Status__c = 'Pending Admin Action';
                                }
                                else {
                                    myList[i].DPM_Status__c = '';
                                }
                            }
                            component.set('v.existingEmployeeList', varLstEmployees.concat(varSearchResults.lstDPMEmployees));
                        }
                        if (component.get('v.existingEmployeeList.length') >= component.get('v.totalCount')) {
                            component.set('v.sessionSettings.showViewMoreDPMEmployees', false);
                        }
                    } else {
                        console.log('varSearchResults.lstDPMEmployees-=-');
                        console.log(varSearchResults.lstDPMEmployees);
                        component.set('v.existingEmployeeList', varSearchResults.lstDPMEmployees);
                        var myList = component.get('v.existingEmployeeList');
                        // check to make sure the list isn't null
                        if (myList != null) {
                            var listLength = myList.length;
                            for (var i = 0; i < listLength; i++) {
                                if (myList[i].DPM_Status__c == 'Initiated') {
                                    myList[i].DPM_Status__c = 'Pending self-registration';
                                }
                                else if (myList[i].DPM_Status__c == 'Submitted') {
                                    myList[i].DPM_Status__c = 'Pending Admin approval';
                                }
                                else if (myList[i].DPM_Status__c == 'Approved') {
                                    myList[i].DPM_Status__c = 'Pending CDSID';
                                }
                                else if (myList[i].DPM_Status__c == 'Pending Corporate Approval') {
                                    myList[i].DPM_Status__c = 'Pending Digital review';
                                }
                                else if (myList[i].DPM_Status__c == 'Pending Retailer Admin') {
                                    myList[i].DPM_Status__c = 'Pending Admin Action';
                                }
                                else {
                                    myList[i].DPM_Status__c = '';
                                }
                            }
                        }
                        if (component.get('v.existingEmployeeList.length') >= component.get('v.totalCount')) {
                            component.set('v.sessionSettings.showViewMoreDPMEmployees', false);
                        }
                        if ($A.util.isEmpty(varSearchResults.lstDPMEmployees)) {
                            helper.showToast('error', 'No employee matches your search criteria. Please change the search and try again.');
                            return;
                        }
                    }
               // }
                if (!$A.util.isEmpty(component.find('idSearchEmployeeCmp'))) {
                    component.find('idSearchEmployeeCmp').destroy();
                }
                component.set("v.showEmployeeCreationStatusSearchResults", true);
                component.set("v.showSearchResults", false);
                component.set('v.selectedTab', 'idEmployeeCreationStatusSearchResults');
                /*window.setTimeout(// commented by gaurav
                    $A.getCallback(function() {
                        helper.updateScrollEmployeeCreationStatus(component,event,helper);
                    }), 500
                );*/
            }
        });
        $A.enqueueAction(searchAction);
    }
})