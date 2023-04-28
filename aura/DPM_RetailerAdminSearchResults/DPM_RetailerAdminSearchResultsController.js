({
    doInit : function(component, event, helper) {
        helper.showSpinner(component);
        let varQueryParams=sessionStorage.getItem("retailerAdminSearchFields");
        component.set("v.searchFields",JSON.parse(varQueryParams));
        console.log('varQueryParams:'+varQueryParams);
       helper.searchForEmployee(component,event,helper,'');
       
    },
    backButtonClicked:function(component,event,helper){
        let urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": "/digital-personnel-master"
        });
        urlEvent.fire();
    },
    handleSessionSettingChange:function(component,event,helper){
        console.log('handleSessionSettingChange');  
        try{
        let varSearchFields=component.get("v.searchFields");
        varSearchFields.jobPosition='';
        component.set("v.searchFields",varSearchFields);   
        component.set("v.existingEmployeeList",[]);
        console.log('searchFields:'+JSON.stringify(varSearchFields));     
        helper.searchForEmployee(component,event,helper,'search');
        }catch(err){
            console.log(err.stack);
        }
    },
    viewMore:function(component,event,helper){
        helper.showSpinner(component);
        let varSessionSettings = component.get('v.sessionSettings'); 
        varSessionSettings.intOffset += parseInt(varSessionSettings.intLimit);
        varSessionSettings.skipOffset = false;
        component.set('v.sessionSettings',varSessionSettings);
        helper.searchForEmployee(component, event, helper, 'viewMore');        
    },
    downloadButtonClicked:function(component,event,helper){
        let varSessionSettings = component.get('v.sessionSettings'); 
        varSessionSettings.skipOffset =true;
        component.set('v.sessionSettings',varSessionSettings);
        helper.searchForEmployee(component, event, helper, 'download');        
    }
})