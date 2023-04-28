({
	createNewRetailerEmployee : function(component, event, helper) {
        helper.viewExistingCheckModal(component, event, helper);
	},
    buttonSelect: function (component, event, helper) {
        var selectedMenuItemValue = event.getParam("value");
        if(selectedMenuItemValue == 'item1'){
            helper.viewNewEmployeeModalForSupplier(component, event, helper); 
        }
        else if(selectedMenuItemValue == 'item2'){
            helper.createBuySellComponent(component,event,helper);
        }
        else if(selectedMenuItemValue == 'item3'){
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
                "url": $A.get("$Label.c.DPM_CDSIDMonitor_Dashboard_Url")
            });
            urlEvent.fire();
        }
        else if(selectedMenuItemValue == 'item4'){
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                    "url": $A.get("$Label.c.DPM_W9_Report_Url")
                });
                urlEvent.fire();
            }
            else if(selectedMenuItemValue == 'item5'){
                helper.viewDMSIdWorkPhoneEmailReportModal(component,event,helper);
            }
            else if(selectedMenuItemValue == 'item_cdua'){
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                    "url": '/lightning/n/DPM_CorporateUsersAccessTab'
                });
                urlEvent.fire();
            }
    },
    openSingleFile: function(cmp, event, helper) {
        var labelValue = $A.get("$Label.c.DPM_DocumentId");
        var docids = labelValue.split(',');
        if(!$A.util.isEmpty(docids)){
            var docIdArray = [];
            if(cmp.get("v.fromPortal")){
                docIdArray.push(docids[0]);
                if(!$A.util.isEmpty(docIdArray)){
                    $A.get('e.lightning:openFiles').fire({
                        recordIds: docIdArray
                    });
                }
            }
            else if(!cmp.get("v.fromPortal") && cmp.get("v.corporatePermissions.showUserGuideToIncentive")){
                docIdArray.push(docids[3]);
                if(!$A.util.isEmpty(docIdArray)){
                    $A.get('e.lightning:openFiles').fire({
                        recordIds: docIdArray
                    });
                }
            }
            else{
                docIdArray.push(docids[2]);
                if(!$A.util.isEmpty(docIdArray)){
                    $A.get('e.lightning:openFiles').fire({
                        recordIds: docIdArray
                    });
                }
            }
        }
        else{
            helper.showToast('error','No File Found in System');
        }
    },
    handleOpenFiles: function(cmp, event, helper) {
        // for the File preview
    },
    searchEmployee : function(component, event, helper) {
        helper.viewSearchModal(component, event, helper);
    },
    handleUserInput : function(component, event, helper) {
        let blnNew = event.getParam('isNew');
        if(blnNew) {
            helper.viewNewEmployeeModal(component, event, helper);
        } else {
           helper.viewReactivateExtendEmployeeModal(component, event, helper);
        }
    },
    doInit : function(component, event, helper) {
        helper.showSpinner(component);
        component.set('v.sessionSettings.intLimit',$A.get("$Label.c.DPM_ExistingEmployeePaginationLimit"));
        component.set('v.sessionSettings.showViewMore',true);
        helper.fetchDPMEmployees(component, event, helper);
        var pageReference = component.get("v.pageReference");
            if(pageReference!==undefined && pageReference!==null && pageReference.state!=null)
            {
                //component.set('v.blnIsIncentiveProfile',true);
                component.set('v.fromPortal',false); 
                component.set('v.corporatePermissions.hideInitiatedRequestsTab',true);
                component.set('v.corporatePermissions.hideSubmitedRequestsTab',true);
                component.set('v.corporatePermissions.viewW9',true);
                component.set('v.mode','search');
            }else{
                var cmpTarget = component.find('changeIt');
        		$A.util.removeClass (cmpTarget, 'slds-box slds-theme_default classDPMCorp slds-p-around_small');
            }
        if(!component.get('v.fromPortal')) {
            helper.fetchCorporatePermissions(component, event, helper);
            if(pageReference!==undefined && pageReference!==null && pageReference.state!=null)
            {
                var psnId=pageReference.state.c__PsnId; 
                var IsFromReport=pageReference.state.c__IsFromReport; 
                var isTerminateEmployee = false;
                if(pageReference.state.c__W9Reason =='Termination'){
                    isTerminateEmployee = true;
                }
                 
                helper.handleSearchReport(component,event,helper,psnId,IsFromReport,isTerminateEmployee);
                component.set('v.IsFromReport',IsFromReport);
                component.set('v.corporatePermissions.hideInitiatedRequestsTab',true);
                component.set('v.corporatePermissions.hideSubmitedRequestsTab',true);
            }
            if(!$A.util.isEmpty(component.get('v.searchFields'))) {
                component.set('v.sessionSettings.intOffset',0);
                helper.handleSearchEventHelper(component,event,helper);
            }            
        } else {
            helper.getWorkflowAppLinks(component, event, helper, 'DPM');
            helper.fetchCurrentEmployee(component,event,helper);            
        }
        
    },
    handleSessionSettingChange : function(component, event, helper) {
        helper.showSpinner(component);         
        if(!component.get('v.fromPortal')) {
            component.set('v.sessionSettings.intOffset',0);
            helper.searchForEmployee(component,event,helper, 'init');
        } else {
            if(component.get('v.sessionSettings.filterBy') != '') {
                component.set('v.sessionSettings.showViewMore',false);
            }
            helper.fetchStoreEmployees(component, event, helper, 'init');
        } 
    },
    viewMore : function(component, event, helper) {
        let varSessionSettings = component.get('v.sessionSettings'); 
        varSessionSettings.intOffset += parseInt(varSessionSettings.intLimit);
        varSessionSettings.skipOffset = false;
        component.set('v.sessionSettings',varSessionSettings);
        if(!component.get('v.fromPortal')) {
            helper.searchForEmployee(component, event, helper, 'viewMore');
        } else {
            helper.fetchStoreEmployees(component, event, helper, 'viewMore');
        }        
    },
    viewMoreDPMEmployees:function(component, event, helper) {
        let varSessionSettings = component.get('v.sessionSettings'); 
        varSessionSettings.intOffset += parseInt(varSessionSettings.intLimit);
        varSessionSettings.skipOffset = false;
        component.set('v.sessionSettings',varSessionSettings);
        if(!component.get('v.fromPortal')) {
            helper.searchEmployeeCreationStatus(component, event, helper, 'ViewMoreDPMEmployees');
        }       
    },
    activateRetailerEmployee : function(component,event,helper){
        helper.viewReactivateExtendEmployeeModal(component, event, helper);
    },
    handleNextEvent : function(component,event,helper) {
        let blnNext = event.getParam("blnNext");
        if(blnNext) {
            let parameters = JSON.parse(event.getParam("modalParams"));
            if(!component.get('v.fromPortal')) {
                parameters.corporatePermissions = component.get('v.corporatePermissions');
            }
            helper.createModal(component,event.getParam("modalName"),parameters);            
        }
        event.stopPropagation();
    },
    //#1857927,  7/Jan/2021, Balayesu Chilakalapudi   
    handleReactivationEvent : function(component,event,helper) {  
        let varDPMEmployee = event.getParam("DPMEmployee");        
        let parameters = {"aura:id":"idReactivateExtendEmployeeCmp","fromPortal":component.get('v.fromPortal'),"DPMEmployee":varDPMEmployee};
        helper.createModal(component, 'c:DPM_ReactivateExtendRetailerEmployee',parameters);
        event.stopPropagation();
    },
    handleSearchEvent : function(component,event,helper) {
        component.set('v.searchFields',event.getParam('searchFields'));
        component.set('v.sessionSettings.intLimit',$A.get("$Label.c.DPM_ExistingEmployeePaginationLimit"));
        component.set('v.sessionSettings.showViewMore',true);
        component.set("v.sessionSettings.showViewMoreDPMEmployees",true);
        component.set('v.sessionSettings.intOffset',0);
        helper.handleSearchEventHelper(component,event,helper);
    },  
    retailerAdminSearch : function(component, event, helper) {
        helper.viewRetailerAdminSearchModal(component, event, helper);
    },
    handleRetailerAdminSearchEvent:function(component,event,helper) {
        component.set('v.retailerAdminSearchFields',event.getParam('searchFields'));
        component.set('v.retailerAdminSessionSettings.intLimit',$A.get("$Label.c.DPM_ExistingEmployeePaginationLimit"));        
        component.set('v.retailerAdminSessionSettings.showViewMore',true);
        component.set('v.retailerAdminSessionSettings.intOffset',0);
        helper.handleRetailerAdminSearchEventHelper(component,event,helper);
    },
    downloadCorpSearchResults:function(component,event,helper){
        let varSessionSettings = component.get('v.sessionSettings'); 
        varSessionSettings.skipOffset =true;
        component.set('v.sessionSettings',varSessionSettings);       
       helper.searchForEmployee(component,event,helper,'download');
    },
    viewDMSReportModal:function(component,event,helper){
        helper.viewDMSIdWorkPhoneEmailReportModal(component,event,helper);
    }, 
    downloadEmployeeStatusSearchResults:function(component,event,helper){
        /*let varSessionSettings = component.get('v.sessionSettings'); 
        varSessionSettings.skipOffset =true;
        component.set('v.sessionSettings',varSessionSettings);       
       helper.searchEmployeeCreationStatus(component,event,helper,'download');*/
       component.find('idEmployeeCreationStatus').downloadEmployeeStatus();
    }
})