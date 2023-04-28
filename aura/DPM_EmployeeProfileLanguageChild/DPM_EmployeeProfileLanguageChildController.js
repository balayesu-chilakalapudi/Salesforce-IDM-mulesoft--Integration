({
    doInit : function(component, event, helper) {
        helper.createLanguagesMap(component, event, helper);
    },	
    addNewLanguage : function(component, event, helper) {
        let mapLanguagesOnProfileToProficiency = component.get('v.mapLanguageToProficiency');
        mapLanguagesOnProfileToProficiency.push({'Language':'','Proficiency':''});
        component.set('v.mapLanguageToProficiency',mapLanguagesOnProfileToProficiency);
    },
    removeFromList : function(component, event, helper) {
        let mapLanguagesOnProfileToProficiency = component.get('v.mapLanguageToProficiency');
        mapLanguagesOnProfileToProficiency.pop();
        component.set('v.mapLanguageToProficiency',mapLanguagesOnProfileToProficiency);
    },
    languageChanged : function(component, event, helper) {
        let mapLanguagesOnProfileToProficiency = component.get('v.mapLanguageToProficiency');
        for(let languageToProficiency of mapLanguagesOnProfileToProficiency) {
            if(languageToProficiency.Language != 'Other') {
                languageToProficiency.OtherLanguage='';
            }
        }
        if(event.getSource().get('v.value') != 'Other') {
            let cmpOtherLanguage = component.find('idOtherLanguage');
            if(Array.isArray(cmpOtherLanguage)) {
                for(let otherLanguage of cmpOtherLanguage) {
                    otherLanguage.reportValidity();
                }
            } else {
                cmpOtherLanguage.reportValidity();
            }
        }
        component.set('v.mapLanguageToProficiency',mapLanguagesOnProfileToProficiency);
    },
})