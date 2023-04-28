({
    handleColumnClick : function(component,event,helper) {
        let objSessionSettings = component.get('v.sessionSettings');
        let headerElem = event.currentTarget;
        let headerName = headerElem.dataset.header;
        let varMode = component.get('v.mode');
        if(varMode == 'search') {
            if(headerName != 'Store' && headerName != 'Name' && headerName!='Job_Position'
            && headerName!='RE_Psn_Active__c' && headerName!='Position_Start_Date' 
            && headerName!='Work_Email' && headerName!='country' && headerName!='Retailer_Admin' && headerName!='Owner') {
                return;
            }
        }
        if(objSessionSettings.sortBy == headerName) {
            if(objSessionSettings.sortDirection == 'ASC') {
                objSessionSettings.sortDirection = 'DESC';
            } else {
                objSessionSettings.sortDirection = 'ASC';
            }
        } else {
            objSessionSettings.sortBy = headerName;
            objSessionSettings.sortDirection = 'ASC';
        }
        component.set('v.sessionSettings',objSessionSettings);   
        component.getEvent("changeDPMEvent").fire();
    },
    handleFilterClick : function(component,event,helper) {
        let headerElem = event.currentTarget;
        let headerName = headerElem.dataset.header;
        helper.toggleFilterBox(component,event,helper,headerName);
        if($A.util.isEmpty(component.get('v.sessionSettings.filterString'))) {
            component.set('v.sessionSettings.filterBy','');
        } else {
            component.set('v.sessionSettings.filterBy',headerName);
        }  
    },
    applyFilter : function(component,event,helper) {
        let headerElem = event.target;
        let headerName = headerElem.dataset.header;
        helper.toggleFilterBox(component,event,helper,headerName);
        if($A.util.isEmpty(component.get('v.sessionSettings.filterString'))) {
            component.set('v.sessionSettings.filterBy','');
        } else {
            component.set('v.sessionSettings.filterBy',headerName);            
        }      
        component.set('v.sessionSettings.intOffset',0);
        component.getEvent("changeDPMEvent").fire();
    },
    doInit:function(component,event,helper){
        console.log('blnIsIncentiveProfile:'+component.get("v.blnIsIncentiveProfile"));
    }
})