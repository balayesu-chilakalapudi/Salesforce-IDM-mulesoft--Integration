({
    closeModal : function(component,event,helper) {
        component.destroy();      
    },
    handleReactivateEmployee : function(component,event,helper) {
        helper.handleUserSelection(component,event,helper,false);
        component.destroy();
    },
    handleNewEmployee : function(component,event,helper) {
        helper.handleUserSelection(component,event,helper,true);
        component.destroy();
    },
})