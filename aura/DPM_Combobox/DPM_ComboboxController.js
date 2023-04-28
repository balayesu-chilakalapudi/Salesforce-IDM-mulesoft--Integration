({
    optionsChange : function(component, event, helper) {
        component.set('v.optionsFiltered',component.get('v.options'));
    },
    showOptions : function(component, event, helper) {
		$A.util.removeClass(component.find('idOptionsBox'),'slds-hide');
    },
    hideOptions : function(component, event, helper) { 
        //console.log(component.get('v.preventBlur'));
        let vartarget = event.currentTarget;
        let currentValue = vartarget.value;
        if(!component.get('v.preventBlur')) {
            window.setTimeout(
                $A.getCallback(function() {
                    $A.util.addClass(component.find('idOptionsBox'),'slds-hide');
                    let selOption = currentValue;
                    let optionList = component.get('v.options');
                    if(!optionList.includes(selOption)) {
                        component.set('v.selectedOption','');
                        vartarget.value = '';
                    }
                }), 100
            );
        }        
    },
    optionSelected : function(component, event, helper) {
        component.set('v.selectedOption',event.currentTarget.dataset.record);
        component.set('v.preventBlur',false);
        $A.util.addClass(component.find('idOptionsBox'),'slds-hide');
    },
    preventBlur : function(component, event, helper) {
        //console.log('asdasda');
       // console.log(document.activeElement.classList);
        component.set('v.preventBlur',true);
    },
    filterOptions : function(component, event, helper) {
        let allOptions = component.get('v.options');
        let filterText = event.currentTarget.value;
        if(!$A.util.isEmpty(filterText) && !$A.util.isEmpty(allOptions)) {
            let filteredOptions = allOptions.filter(function(option) {
              //  console.log(option);
              //  console.log(filterText);
              //  console.log(option.includes(filterText));
                return (option.toLowerCase()).includes(filterText.toLowerCase());
            });
           // console.log(filteredOptions);
            component.set('v.optionsFiltered',filteredOptions);
        }        
    },
})