({
	showHideSSN : function(component, event, helper) {
        if(component.get('v.strCountry') == 'Canada') {
            if(component.get('v.showSSN')) {
                component.set('v.SSNBtnLabel','Show SIN');
            } else {
                component.set('v.SSNBtnLabel','Hide SIN');
            }
        } else {
            if(component.get('v.showSSN')) {
                component.set('v.SSNBtnLabel','Show SSN');
            } else {
                component.set('v.SSNBtnLabel','Hide SSN');
            }
        }
		component.set('v.showSSN',!component.get('v.showSSN'));
	}
})