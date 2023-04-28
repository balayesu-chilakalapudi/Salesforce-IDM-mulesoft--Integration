({   
    searchForEmployee : function(component,event,helper,origin) {
        console.log('RetailerAdminSearch Results > searchForEmployee running');
        helper.showSpinner(component);
        component.set('v.totalCount',0);
        let searchAction = component.get("c.searchEmployees");
        let params={strSessionSettings:JSON.stringify(component.get('v.sessionSettings')),strSearchFields:JSON.stringify(component.get('v.searchFields'))};
        console.log('params:'+JSON.stringify(params));
        searchAction.setParams(params);
        searchAction.setCallback(this, function(response) {        
            var state = response.getState();
            console.log('state:'+state);
            if (state === "SUCCESS") {
                let varSearchResults = response.getReturnValue();
                if(origin=='download'){
                    var lstRecords=varSearchResults.lstJobPositions;
                    let varfileName='RetailerAdminSearchResults.csv';
                     let varfileHeader='NAME,STORE NAME - ID,JOB POSITION,ACTIVE/TERMINATED,POSITION START DATE,WORK EMAIL,COUNTRY';
                    let parameters = {"aura:id":"idDPM_csvExport","fromPortal":component.get('v.fromPortal'),"records":lstRecords,"fileName":varfileName,"fileHeader":varfileHeader};
                    helper.createModal(component, 'c:DPM_csvExport',parameters);                           
                }else{
                let varLstEmployees = component.get('v.existingEmployeeList');
                
                component.set('v.totalCount',varSearchResults.intTotalResults);
              console.log('varSearchResults:'+JSON.stringify(varSearchResults));                
                    console.log('varSearchResults.lstPersonRole-=-');
                   // console.log(varSearchResults.lstPersonRole);
                  
                    component.set('v.existingEmployeeList',varLstEmployees.concat(varSearchResults.lstJobPositions));
                    if(component.get('v.existingEmployeeList.length') >= component.get('v.totalCount')) {
                        component.set('v.sessionSettings.showViewMore',false);
                    }
                    if($A.util.isEmpty(varSearchResults.lstJobPositions)) {
                        helper.showToast('error','No employee matches your search criteria. Please change the search and try again.');
                        helper.hideSpinner(component);
                        return;
                    }
               // }
                let searchEmployeeColumns = [
                    {'label':'Name','name':'Name'},
                    {'label':'Store Name - Id','name':'Store'},
                    {'label':'Job Position','name':'Job_Position'},
                    {'label':'Active/Terminated','name':'RE_Psn_Active__c'},
                    {'label':'Position Start Date','name':'Position_Start_Date'},
                    {'label':'Work Email','name':'Work_Email'},
                    {'label':'Country','name':'country'}
                ];
                component.set('v.sessionSettings.existingEmployeeColumns',searchEmployeeColumns);
                if(!$A.util.isEmpty(component.find('idSearchEmployeeCmp'))) {
                    component.find('idSearchEmployeeCmp').destroy();
                }                
                component.set('v.showSearchResults',true);
                component.set('v.selectedTab','idSearchResults');
                window.setTimeout(
                    $A.getCallback(function() {
                        helper.updateScroll(component,event,helper);
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
    handleError : function(errors) {
        let message = 'Unknown error'; // Default error message
        // Retrieve the error message sent by the server
        if (errors && Array.isArray(errors) && errors.length > 0) {
            message = errors[0].message;
        }
        // Display the message
        this.showToast('error',message);
    },
    showToast : function(type,message) {
        let toastEvent = $A.get("e.force:showToast");
        let title = (type=='error'?'Error!':(type=='success'?'Success!':'Warning!'));
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type":type,
            "mode":"sticky"
        });
        toastEvent.fire();        
    },
    showSpinner : function(component) {
        $A.util.removeClass(component.find('idSpinner'),'slds-hide');
    },
    hideSpinner : function(component) {
        $A.util.addClass(component.find('idSpinner'),'slds-hide');
    },
    updateScroll : function(component, event, helper) {
        if(component.find('idPMList')) {
            component.find('idPMList').getElement().scrollIntoView({ behavior: 'smooth' });
        }        
    },
    createModal : function(component, componentName, parameters) {
        $A.createComponent(componentName, parameters, function(modal, status, errorMessage) {
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
})