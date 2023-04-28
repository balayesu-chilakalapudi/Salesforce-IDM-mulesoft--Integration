import { LightningElement, wire, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getActivePersonnel from '@salesforce/apex/DPM_PersonnelMasterController.getActivePersonnel';
import transferPersonnel from '@salesforce/apex/DPM_PersonnelMasterController.transferPersonnel';

export default class dpm_buysellpersonnelselection extends LightningElement {
    clickedButtonLabel;
    @api sellingRetailer;
    @api buyingRetailer;
    @track showButton= true;
    @track isModalOpen = false;
    @track sellingRetailerIdName;
    @track buyingRetailerIdName;
    @api originalAppointmentDate;
    @track error;
    @track prsnRolList ;

    //Notification Variables
    @track blnNotificationActive = false;
    @api strModalHeader;
    @api strModalBody;
    @api strModalType;
    @api blnConfirmButton = false;
    @api blnEditListButton = false;

    @track columns = [{
            label: 'Name',
            fieldName: 'REContact',
            type: 'text',
            hideDefaultActions: true
        },
        {
            label: 'Primary Job Position',
            fieldName: 'RE_Employee_Position__c',
            type: 'text',
            hideDefaultActions: true
        },
        {
            label: 'Hire Date',
            fieldName: 'RE_Psn_Active_Date__c',
            type: "date-local",
            typeAttributes:{
                day: "2-digit",
                month: "2-digit",
                year: "numeric"
            },
            hideDefaultActions: true
        },
        {
            label: 'Retailer Admin',
            fieldName: 'RE_IsAdmin__c',
            type: 'boolean',
            hideDefaultActions: true
        }
    ]; 
    
    @wire(getActivePersonnel, {sellingRetailerId:'$sellingRetailer',buyingRetailerId:'$buyingRetailer'}) 
    wiredAccounts({
        error,
        data
    }) {
        if (data) {
            data.forEach(acc =>{
                if(acc.Person_Roles__r != undefined){
                    this.prsnRolList = acc.Person_Roles__r.map(row=>{
                        return{...row, REContact: row.RE_Contact__r.Name}
                    });
                }
                if(acc.Id == this.sellingRetailer){
                    this.sellingRetailerIdName = acc.Retailer__c+' - '+acc.Name;
                }
                if(acc.Id == this.buyingRetailer){
                    this.buyingRetailerIdName = acc.Retailer__c+' - '+acc.Name;
                }
            });            
        } else if (error) {
            this.error = error;
        }
    }
    handleClick(event) {
        this.clickedButtonLabel = event.target.label;
    }    
    closeModal() {
        this.dispatchEvent(new CustomEvent('closeModal'));
    } 
    nextModal() {
        let varDataToPass = {stage:'1',sellingRetailer: this.sellingRetailer,buyingRetailer:this.buyingRetailer,originalAppointmentDate:this.originalAppointmentDate};
        this.dispatchEvent(new CustomEvent('nextModal',{
            detail : {varDataToPass}
        })); 
    }   
    handleAdd(){
        this.strModalHeader = "Confirm Personnel Transfer";
        this.strModalBody = "You are about to transfer all the selected personnel to the new store, please confirm the selection!";
        this.strModalType = "confirmPersonnelTransfer";
        this.blnConfirmButton = true;
        this.blnEditListButton = true;
        this.blnNotificationActive = true;
    }
    rowSelection(event) {
        let selectedRows = event.detail.selectedRows;
        if(selectedRows.length > 0) {
            this.showButton = false;
        } else {
            this.showButton = true;
        }
    } 
    handleNotification(event) {
        if(event.detail.type == "confirmPersonnelTransfer") {
            if(event.detail.name == 'edit') {
                this.blnNotificationActive = false;                
            }
            if(event.detail.name == 'ok') {
                let selectedRecords = this.template.querySelector("lightning-datatable").getSelectedRows();
                let listOfPersonRoleId = [];
                for (const element of selectedRecords) {
                    listOfPersonRoleId.push(element.Id);
                }
                this.blnNotificationActive = false; 
                this.transferPersonnelToBuyingStore(listOfPersonRoleId);               
            }
            if(event.detail.name == 'close') {
                this.blnNotificationActive = false;
            }
        }
    }
    transferPersonnelToBuyingStore(listOfPersonRoleId) {
        transferPersonnel({
            lstPersonRoleIds:listOfPersonRoleId,
            strSellingRetailerId:this.sellingRetailer,
            strBuyingRetailerId:this.buyingRetailer,
            dtOriginalAppointmentDate:this.originalAppointmentDate
        })
        .then(result => {
            this.showToast('success','Your request to transfer personnel has been submitted.');
            this.closeModal();
        })
        .catch();
    }
    showToast(type,message) {
        const event = new ShowToastEvent({
            "title": (type=='success'?'Success!':'Error!'),
            "message": message,
            "variant": type
        });
        this.dispatchEvent(event);
    }
}