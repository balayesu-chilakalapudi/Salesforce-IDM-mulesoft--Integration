({
  viewNewEmployeeModal: function (component, event, helper) {
    let dpmEmployee = component.get("v.dpmEmployee");
    let dpmJobPositions = dpmEmployee.DPM_Job_Positions__r;
    if (dpmEmployee.DPM_Employee_Type__c == "Supplier") {
      helper.createModal(component, "c:DPM_NewRetailerEmployeeCmp", {
        DPMEmployee: component.get("v.dpmEmployee"),
        DPMJobPositions: dpmJobPositions,
        blnReadOnly: true,
        fromPortal: component.get("v.fromPortal"),
        corporatePermissions: component.get("v.corporatePermissions"),
        IsSupplier: "true",
      });
    } else {
      helper.createModal(component, "c:DPM_NewRetailerEmployeeCmp", {
        DPMEmployee: component.get("v.dpmEmployee"),
        DPMJobPositions: dpmJobPositions,
        blnReadOnly: true,
        fromPortal: component.get("v.fromPortal"),
        corporatePermissions: component.get("v.corporatePermissions"),
      });
    }
  },
  viewSearchEmployeeModal: function (component, event, helper) {
    let parameters = {
      "aura:id": "idSearchEmployeeCmp",
      personRole: component.get("v.existingEmployee"),
      account: component.get("v.existingEmployee.RE_Account__r"),
      contact: component.get("v.existingEmployee.RE_Contact__r"),
      jobPositions: component.get("v.existingEmployee.DPM_Job_Positions__r"),
      mode: "view",
      isRetailerAdmin: component.get("v.isRetailerAdmin"),
      isSearchModal: true,
      searchMode: "view",
      corporatePermissions: component.get("v.corporatePermissions"),
    };
    helper.createModal(component, "c:DPM_EditEmployeeProfile", parameters);
  },
  createModal: function (component, componentName, parameters) {
    $A.createComponent(
      componentName,
      parameters,
      function (modal, status, errorMessage) {
        if (status === "SUCCESS") {
          var body = component.get("v.body");
          body.push(modal);
          component.set("v.body", body);
        } else if (status === "INCOMPLETE") {
          console.warn("No response from server or client is offline.");
        } else if (status === "ERROR") {
          console.error("Error: " + errorMessage);
        }
      }
    );
  },
});