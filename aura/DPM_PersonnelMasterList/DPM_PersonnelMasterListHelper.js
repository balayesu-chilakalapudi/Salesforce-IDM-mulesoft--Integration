({
	toggleFilterBox : function(component,event,helper,headerName) {
		let columnList = component.get('v.sessionSettings.existingEmployeeColumns');
        for(let column of columnList) {
            if(column.name == headerName) {
                if(column.filter == 'show') {
                    column.filter = 'hide';
                } else {
                    column.filter = 'show';
                }                
            }
        }
        component.set('v.sessionSettings.existingEmployeeColumns',columnList);
	},
})