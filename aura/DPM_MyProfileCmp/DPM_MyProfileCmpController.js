({
    doInit : function(component, event, helper) {
        helper.getProfile(component,event,helper);
        helper.getPositionsList(component, event, helper);
    },
    editProfile : function(component, event, helper) {
        helper.viewNewEmployeeModal(component, event, helper);
    },
    openSingleFile: function(cmp, event, helper) {
        var labelValue = $A.get("$Label.c.DPM_DocumentId");
        var docids = labelValue.split(',');
        if(!$A.util.isEmpty(docids)){
            var docIdArray = [];
            docIdArray.push(docids[1]);
            if(!$A.util.isEmpty(docIdArray)){
                $A.get('e.lightning:openFiles').fire({
                    recordIds: docIdArray
                });
            }
        }
    },
    handleOpenFiles: function(cmp, event, helper) {
        // for the File preview
    },    
    handleTerminationDateMsgEvent:function(component,event,helper){
        // console.log('handleTerminationDateMsgEvent running'); 
        let editEmployeeParameters = {
            "aura:id":"idEditEmployeeCmp2",
            "personRole":component.get('v.personRole'),
            "account":component.get('v.personRole.RE_Account__r'),
            "contact":component.get('v.personRole.RE_Contact__r'),
            "jobPositions":component.get('v.personRole.DPM_Job_Positions__r'),
            "mode":component.get('v.mode'),
            "isRetailerAdmin":component.get('v.isRetailerAdmin')
        };         
        let strModalBody = event.getParam("strModalBody");    
        let parameters = {"aura:id":"idTerminationDateMessages","strModalBody":strModalBody,"empParams":editEmployeeParameters};
        helper.createModal(component, 'c:DPM_TerminationDateMessages',parameters); 
        event.stopPropagation();       
    },
    handleEditTerminationDateEvent : function(component,event,helper) {
        let terminationDateCmp = component.find('idEmployeeForm').find('idTerminationDate');
        // console.log(terminationDateCmp);
        event.stopPropagation();       
    }
})