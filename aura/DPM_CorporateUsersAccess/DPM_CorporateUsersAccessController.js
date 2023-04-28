({
    doInit: function (component, event, helper) {
        var today = new Date();
        var dd = String(today.getDate()).padStart(2, '0');
        var mm = String(today.getMonth() + 1).padStart(2, '0'); //January is 0!
        var yyyy = today.getFullYear();

        today = mm + '/' + dd + '/' + yyyy;
        component.set("v.generatedDate", today);
        var action = component.get("c.getCorporateUserAccessReport");
        //action.setParams({strSessionSettings:JSON.stringify(varSessionSettings)});
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let data = response.getReturnValue();
                component.set("v.RecordList",data);
            } else {
                let message = 'Unknown error'; // Default error message
                // Retrieve the error message sent by the server
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                let toastEvent = $A.get("e.force:showToast");
                let type = 'error';
                let title = (type == 'error' ? 'Error!' : (type == 'success' ? 'Success!' : 'Warning!'));
                toastEvent.setParams({
                    "title": title,
                    "message": message,
                    "type": type,
                    "mode": "sticky"
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
    }
})