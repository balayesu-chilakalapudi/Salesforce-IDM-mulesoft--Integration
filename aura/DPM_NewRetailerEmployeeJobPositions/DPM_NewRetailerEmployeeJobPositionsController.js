({
    doInit : function(component, event, helper) {
    //    console.log('fromEmployeeProfile:'+component.get('v.fromEmployeeProfile'));
        let varPrimaryPositionsList = component.get('v.primaryPositionsList');
        let varJobPositions = component.get('v.jobPositions');
        let varJobPositionsNew = []; 
        if(varJobPositions) {
            for(let i=0;i<varJobPositions.length;i++) {
                let varJobPositionName = varJobPositions[i].Name;
                if(component.get('v.fromEmployeeProfile')) {
                    varJobPositionName = varJobPositions[i].DPM_Position_Title__c;
                }
                if(varPrimaryPositionsList.includes(varJobPositionName)) {
                    varJobPositions[i].showPrimary = true;
                } 
                if(varJobPositions[i].DPM_End_Date__c!=null){                    
                    varJobPositions[i].blnAlreadyTerminated = true;                	
                }
                varJobPositionsNew.push(varJobPositions[i]);
            }
        }        
        component.set('v.jobPositions',varJobPositionsNew);
         //show star symbol for primary positions
        let varpositionsList=component.get("v.positionsList");
        let varpositionsListNew=[];
        for(let i=0;i<varpositionsList.length;i++){
            varpositionsListNew[i]=varpositionsList[i];
            let varPositionText = varpositionsList[i].text;
            if(varPrimaryPositionsList.includes(varPositionText)) {
                varpositionsListNew[i].text =varpositionsList[i].text+'*' ;
            } 
        }
        component.set("v.positionsList",varpositionsListNew);
    },
    removeFromList : function(component, event, helper) {
        let target = event.target;
        let rowIndex = target.getAttribute("data-row-index");
        let varJobPositions = component.get('v.jobPositions');
        let varJobPositionsNew = [];
        for(let i=0;i<varJobPositions.length;i++) {
            if(i != rowIndex) {
                varJobPositionsNew.push(varJobPositions[i]);
            }
        }
        component.set('v.jobPositions',varJobPositionsNew);
    },
    selectionChanged : function(component, event, helper) {
        let target = event.target;
        let rowIndex = target.getAttribute("data-row-index");
        let varJobPositions = component.get('v.jobPositions');
        let varPrimaryPositionsList = component.get('v.primaryPositionsList');
        let varIncentiveEligiblePositionsList = component.get('v.incentiveEligiblePositionsList');
        //console.log(JSON.stringify(varPrimaryPositionsList));
        let varJobPositionsNew = [];
        for(let i=0;i<varJobPositions.length;i++) {
            if(i == rowIndex) {
                let varJobPositionName = varJobPositions[i].Name;
                let varJobPositionPrimary = varJobPositions[i].DPM_Primary__c;
                if(component.get('v.fromEmployeeProfile')) {
                    varJobPositionName = varJobPositions[i].DPM_Position_Title__c;
                    varJobPositionPrimary = varJobPositions[i].DPM_Primary_Position__c;
                }
                if(varPrimaryPositionsList.includes(varJobPositionName)) {
                    varJobPositions[i].showPrimary = true;
                } else {
                    varJobPositions[i].showPrimary = false;
                    varJobPositionPrimary = false;
                    if(component.get('v.fromEmployeeProfile')) {
                        varJobPositions[i].DPM_Primary_Position__c = false;
                    } else {
                        varJobPositions[i].DPM_Primary__c = false;
                    }                    
                }
            }
            varJobPositionsNew.push(varJobPositions[i]);
        }
        component.set('v.jobPositions',varJobPositionsNew);
    },
    primarySelected : function(component, event, helper) {
        let target = event.target;
        let rowIndex = target.getAttribute("data-row-index");
        let varJobPositions = component.get('v.jobPositions');
        let varJobPositionsNew = [];
        //If primary checkbox is selected, deselect primary from other selections
        for(let i=0;i<varJobPositions.length;i++) {
            if(i != rowIndex) {                
                if(component.get('v.fromEmployeeProfile')) {
                    if(varJobPositions[i].DPM_Primary_Position__c = true) {
                        varJobPositions[i].DPM_Primary_Position__c = false;
                    }
                } else {
                    if(varJobPositions[i].DPM_Primary__c = true) {
                        varJobPositions[i].DPM_Primary__c = false;
                    }
                }                        
            }
            varJobPositionsNew.push(varJobPositions[i]);
        }
        component.set('v.jobPositions',varJobPositionsNew);
    },
    checkEndDate :function(component,event,helper){  //25/Feb/2021, #1872325 
        let varEndDate = event.getSource().get("v.value");
        let varTerminationDate = component.get("v.terminationDate");
        if(!$A.util.isEmpty(varEndDate)) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title : 'Warning',
                message: 'You are about to end this position. You will not be able to change any field on this position after saving',
                duration:3000,
                key: 'info_alt',
                type: 'warning',
                mode: 'sticky'
            });
            toastEvent.fire();
        } 
        if(!$A.util.isEmpty(varTerminationDate)){
            event.getSource().set("v.value",varTerminationDate); 
        }
    }
})