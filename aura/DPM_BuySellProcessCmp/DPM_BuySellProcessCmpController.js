({
    closeModal : function(component, event, helper) {
        component.destroy();
    },
    nextModal : function(component, event, helper) {
        let data = event.getParam('varDataToPass');
        component.set('v.originalAppointmentDate',data.originalAppointmentDate);
        component.set('v.buyingRetailer',data.buyingRetailer);
        component.set('v.sellingRetailer',data.sellingRetailer);
        component.set('v.stage',data.stage);
    },
})