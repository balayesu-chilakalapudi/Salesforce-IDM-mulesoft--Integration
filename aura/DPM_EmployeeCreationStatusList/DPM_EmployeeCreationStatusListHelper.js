({
        
    sortData: function (cmp, fieldName, sortDirection) {
        var fname = fieldName;
        var data = cmp.get("v.existingEmployees");
        var reverse = sortDirection !== 'asc';
        data.sort(this.sortBy(fieldName, reverse))
        cmp.set("v.existingEmployees", data);
    },
    sortBy: function (field, reverse) {
        var key = function(x) {return x[field]};
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    },
    createModal: function (component, componentName, parameters) {
        $A.createComponent(componentName, parameters, function (modal, status, errorMessage) {
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
    }
})