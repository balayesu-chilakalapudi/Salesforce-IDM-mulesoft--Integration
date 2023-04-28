({
  showSpinner: function (component) {
    $A.util.removeClass(component.find("idSpinnerModal"), "slds-hide");
  },
  hideSpinner: function (component) {
    $A.util.addClass(component.find("idSpinnerModal"), "slds-hide");
  },
  handleClick: function (component, event, helper, message) {
    helper.showSpinner(component);
    let dpmEvent = component.getEvent("dpmNotificationEvt");
    dpmEvent.setParams({
      message: message,
      type: component.get("v.strModalType"),
    });
    dpmEvent.fire();
    helper.hideSpinner(component);
  },
});