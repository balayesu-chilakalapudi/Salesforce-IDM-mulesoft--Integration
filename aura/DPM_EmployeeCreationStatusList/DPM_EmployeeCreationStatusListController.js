({
    doInit: function (component, event, helper) {

    },
    //Method gets called by onsort action,
    updateSorting: function (cmp, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        helper.sortData(cmp, fieldName, sortDirection);
    },
    handleDownload: function (component, event, helper) {
        console.log('handleDownload');
        var lstRecords = [];
        var myList = component.get("v.existingEmployees");
        // check to make sure the list isn't null
        if (myList != null) {
            var listLength = myList.length;
            for (var i = 0; i < listLength; i++) {
                /* if (myList[i].DPM_Status__c == 'Initiated') {
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
                 }*/
                lstRecords.push({
                    'First Name': myList[i].DPM_Legal_First_Name__c,
                    'Last Name': myList[i].DPM_Last_Name__c,
                    'Email': myList[i].DPM_Email__c,
                    'Action': myList[i].DPM_Request_Type__c,
                    'Status': myList[i].DPM_Status__c
                });
            }
            let varfileName = component.get("v.RetailerId") + '.csv';
            let varfileHeader = 'First Name,Last Name,Email,Action,Status';
            let parameters = { "aura:id": "idDPM_csvExport", "fromPortal": component.get('v.fromPortal'), "records": lstRecords, "fileName": varfileName, "fileHeader": varfileHeader };
            helper.createModal(component, 'c:DPM_csvExport', parameters);
        }
    },
    viewRecord: function (component, event, helper) {
        var action = event.getParam('action');
        let dpmEmployee = event.getParam('row');
        switch (action.name) {
            case 'view':
                console.log('row:' + JSON.stringify(dpmEmployee));
                let dpmJobPositions = dpmEmployee.DPM_Job_Positions__r;
                helper.createModal(component, "c:DPM_NewRetailerEmployeeCmp", {
                    DPMEmployee: dpmEmployee,
                    DPMJobPositions: dpmJobPositions,
                    blnReadOnly: true,
                    fromPortal: component.get("v.fromPortal"),
                    corporatePermissions: component.get("v.corporatePermissions"),
                });
                break;
            /*case 'edit':
                break;
            case 'delete':
                break;*/
        }

    }
})