({
    createLanguagesMap : function(component, event, helper) {
        let employeeData;
        if(component.get('v.fromEmployeeProfile')) {
            employeeData = component.get('v.personRole.RE_Contact__r');
        } else {
            employeeData = component.get('v.dpmEmployee');
        }
        console.log(component.get('v.dpmProficiency')+' asdasd '+JSON.stringify(employeeData));
        if(employeeData) {
            let mapLanguagesOnProfileToProficiency = [];
            let varLanguageList = component.get('v.languageList');
            let varLanguageValueList = [];
            for(let languageOption of varLanguageList) {
                varLanguageValueList.push(languageOption.value);
            }
            for(let i=0;i<3;i++) {
                let varLanguageFieldName = 'DPM_Language_'+(i+1)+'__c';
                let varProficiencyFieldName = 'DPM_Proficiency_'+(i+1)+'__c';
                if(!$A.util.isEmpty(employeeData[varLanguageFieldName])) {
                    let blnOtherLanguage = !varLanguageValueList.includes(employeeData[varLanguageFieldName]);
                    mapLanguagesOnProfileToProficiency.push({
                        'Language' : (blnOtherLanguage?'Other':employeeData[varLanguageFieldName]),
                        'Proficiency' : employeeData[varProficiencyFieldName],
                        'OtherLanguage' : (blnOtherLanguage?employeeData[varLanguageFieldName]:'')
                    });
                }                
            }
            if($A.util.isEmpty(mapLanguagesOnProfileToProficiency)) {
                mapLanguagesOnProfileToProficiency.push({'Language' : '','Proficiency' : '','OtherLanguage' : ''});
            }
            component.set('v.mapLanguageToProficiency',mapLanguagesOnProfileToProficiency);
        }        
    },
})