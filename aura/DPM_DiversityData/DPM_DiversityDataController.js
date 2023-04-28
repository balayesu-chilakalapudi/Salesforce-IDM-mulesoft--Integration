({
    doInit : function(component, event, helper) {
        console.log('@@@ '+JSON.stringify(component.get('v.personRole')));
    },
    raceChanged : function(component, event, helper) {
        let varRace;
        if(component.get('v.fromEmployeeProfile')) {
            varRace = component.get('v.personRole.RE_Contact__r.DPM_Race__c');
        } else {
            varRace = component.get('v.DPMEmployee.DPM_Race__c');
        }
        if(varRace != 'Two or more races') {
            component.set('v.otherRace','');
            let cmpOtherRace = component.find('idOtherRace');
            if(cmpOtherRace) {
                cmpOtherRace.reportValidity(); 
            }
        }
    },
    ethnicityChanged : function(component, event, helper) {
        let varEthnicity;
        if(component.get('v.fromEmployeeProfile')) {
            varEthnicity = component.get('v.personRole.RE_Contact__r.DPM_Ethnicity__c');
        } else {
            varEthnicity = component.get('v.DPMEmployee.DPM_Ethnicity__c');
        }
        if(varEthnicity != 'Other') {
            component.set('v.otherEthnicity','');
            let cmpOtherEthnicity = component.find('idOtherEthnicity');
            if(cmpOtherEthnicity) {
                cmpOtherEthnicity.reportValidity(); 
            }
        }
    },
})