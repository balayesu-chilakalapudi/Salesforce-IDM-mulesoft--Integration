({
    myAction : function(component, event, helper) {

    },
    doInit:function(component,event,helper){
        let country=[];
        let countrynames_label=$A.get("$Label.c.DPM_DMS_Id_Countries");
        let countrynames=countrynames_label.split(',');
        
        for(let x of countrynames){
        country.push({
                label:x,
                value:x
            }
        );
        }
    component.set("v.countryList",country);
    },
    handleCountryChange:function(component,event,helper){
        //component.set("v.regionList",null);
        //component.set("v.regionSelected",'');
        let regionnames_label='';
        var selectedCountryOptionValue = event.getParam("value");
        component.set("v.countrySelected",selectedCountryOptionValue);
        if(selectedCountryOptionValue.includes('USA')){
            regionnames_label+=$A.get("$Label.c.DPM_DMS_Id_USA_Regions");
        }
        if(selectedCountryOptionValue.includes('CAN')){
            if(regionnames_label!=''){
                regionnames_label+=',';
            }
            regionnames_label+=$A.get("$Label.c.DPM_DMS_Id_CAN_Regions");
        }
        console.log('selectedCountryOptionValue:'+selectedCountryOptionValue);
        console.log('regionnames_label:'+regionnames_label);
        let region=[];
        let regionnames=regionnames_label.split(',');

        for(let x of regionnames){
        region.push({
                label:x,
                value:x
            }
        );
        }
        component.set("v.regionList",region); 
       
        let regionSelected_value=component.get("v.regionSelected")+',';
        console.log('before regionSelected_value:'+regionSelected_value);         
        
        console.log('regionSelected_value:'+regionSelected_value);
       
        if(regionSelected_value!=undefined){
        let selected_region_arr=regionSelected_value.split(',');
        let updated_regions='';
        let regionValue=[];
        for(let x of selected_region_arr){
            if(regionnames.includes(x)){
                updated_regions+=x+',';
                regionValue.push(x);
            }
        }
        updated_regions=updated_regions.replace(/,\s*$/, "");
        console.log('updated_regions:'+updated_regions);
        component.set("v.regionSelected",updated_regions);
        component.set("v.regionValue",regionValue);
        }
    },
    handleRegionChange:function(component,event,helper){
        var selectedRegionOptionValue = event.getParam("value");
        component.set("v.regionSelected",selectedRegionOptionValue);
        console.log('handleRegionChange > regionSelected:'+component.get("v.regionSelected"));
    },
    generateReport:function(component,event,helper){
        let countrySelected=component.get("v.countrySelected");
        let regionSelected=component.get("v.regionSelected");
        let report_url=$A.get("$Label.c.DPM_DMS_Id_Work_phone_email_report_url");
        report_url+='?fv0='+countrySelected+'&fv1='+regionSelected;
        console.log('report_url:'+report_url);
        var urlEvent = $A.get("e.force:navigateToURL");
    urlEvent.setParams({
      "url": report_url
    });
    urlEvent.fire();
    },
    close : function(component) {
        component.destroy();
    }, 
    openConfirmationModal:function(component,event,helper){   
        let country= component.get("v.countrySelected");
        let region= component.get("v.regionSelected");
        if(country!='' && country!=undefined && region!='' && region!=undefined){
        let msg='Click Confirm to proceed with Country: '+component.get("v.countrySelected")+' and Region: '+component.get("v.regionSelected")+' report. Click Back to return to edit your selection';
        component.set("v.confirmationMessage",msg);
        component.set("v.showConfirmation",true);
        }else{
            component.set("v.showWarningConfirmation",true);
        }
    },
    closeConfirmationModal:function(component,event,helper){
        component.set("v.showConfirmation",false);
       /* component.set("v.regionList",null);
        component.set("v.regionSelected",'');
        component.set("v.countrySelected",'');*/
    },
    closeWarningConfirmationModal:function(component,event,helper){
        component.set("v.showWarningConfirmation",false);
    }
})