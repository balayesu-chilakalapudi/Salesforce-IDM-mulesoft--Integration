import { LightningElement, track, api } from 'lwc';
import getSellingRetailersLst from '@salesforce/apex/DPM_PersonnelMasterController.getSellingRetailers';
import getBuyingRetailersLst from '@salesforce/apex/DPM_PersonnelMasterController.getBuyingRetailers';

export default class DPM_BuySellStoreSelection extends LightningElement {
    @api varSellingAccounts;
    @track varBuyingAccounts;
    @track varAccounts = [];
    @api selectedSellingRetailerId;
    @api selectedBuyingRetailerId;
    @track selectedSellingRetailer;
    @track selectedBuyingRetailer;
    @track showSellingRetailerDetails = false;
    @track showBuyingRetailerDetails = false;
    @track blnSellingRetailersLoaded = false;
    @track blnBuyingRetailersLoaded = false;
    @api varOriginalAppointmentDate;
    @track varOriginalAppointmentDateMax;
    @track varOriginalAppointmentDateMin;
    @track varAccountNonActiveDate;

    //Notification Variables
    @track blnNotificationActive = false;
    @api strModalHeader;
    @api strModalBody;
    @api strModalType;
    @api blnOkButton = false;
    @api blnCancelButton = false;

    connectedCallback() {
        let currentDate = new Date();
        this.varOriginalAppointmentDateMax = new Date();
        this.varOriginalAppointmentDateMin = new Date();
        this.varAccountNonActiveDate = new Date();
        this.varOriginalAppointmentDateMax.setDate(currentDate.getDate());
        this.varOriginalAppointmentDateMin.setDate(currentDate.getDate() - 30);
        this.varOriginalAppointmentDateMax = this.varOriginalAppointmentDateMax.toISOString();
        getSellingRetailersLst()
        .then(result => {
            this.varAccounts = this.varAccounts.concat(result);
            this.varSellingAccounts = this.convertToPicklist(result);
            this.blnSellingRetailersLoaded = true;
        })
        .catch();
        getBuyingRetailersLst()
        .then(result => {
            this.varAccounts = this.varAccounts.concat(result);
            this.varBuyingAccounts = this.convertToPicklist(result);
            this.blnBuyingRetailersLoaded = true;
        })
        .catch();
    }
    convertToPicklist(lstOptions) {
        let lstPicklistOptions = [];
        for(let option of lstOptions) {
            lstPicklistOptions.push({value:option.Id,label:option.Name+' - '+option.Retailer__c});
        }
        return lstPicklistOptions;
    }
    closeModal() {
        this.dispatchEvent(new CustomEvent('closeModal'));
    }
   handleConfirm() {
        if(this.validateFields()) {
            this.strModalHeader = "Confirm Buy/Sell Initiation";
            let dateToShow = new Date(this.varOriginalAppointmentDate);
                        //alert(dateToShow.getUTCDate());
            this.strModalBody = "You are about to initiate a buy/sell. Do you want to proceed with the buy/sell of "
                +this.selectedSellingRetailer.Name+"("+this.selectedSellingRetailer.Retailer__c+")"
                +'&nbsp; to &nbsp;'
                +this.selectedBuyingRetailer.Name+"("+this.selectedBuyingRetailer.Retailer__c+")"
                +' with buy/sell date of  '//+this.varOriginalAppointmentDate;
                +((dateToShow.getMonth()+1) < 10 ?'0'+(dateToShow.getMonth()+1):dateToShow.getMonth()+1)
                +'/'+((dateToShow.getUTCDate()) < 10 ?'0'+(dateToShow.getUTCDate()):(dateToShow.getUTCDate()))
                +'/'+dateToShow.getFullYear()+'.';
            this.strModalType = "confirmBuySell";
            this.blnOkButton = true;
            this.blnCancelButton = true;
            this.blnNotificationActive = true;
        }
    }
    nextModal() {
        let varDataToPass = {stage:'2',sellingRetailer: this.selectedSellingRetailer.Id,buyingRetailer:this.selectedBuyingRetailer.Id,originalAppointmentDate:this.varOriginalAppointmentDate};
            this.dispatchEvent(new CustomEvent('nextModal',{
                detail : {varDataToPass}
        })); 
    }
    validateFields() {
        let blnSuccess = true;         
        this.template.querySelectorAll('c-d-p-m_-search-box').forEach(element => {
            let blnSuccessElement = element.checkValidity();
            if(blnSuccess) {
                blnSuccess = blnSuccessElement;
            }
        });
        this.template.querySelectorAll('.classRequired').forEach(element => {
            let blnSuccessElement = element.checkValidity();
            if(blnSuccess) {
                blnSuccess = blnSuccessElement;
            } else {
                element.reportValidity();
            }
        });
        return blnSuccess;       
    }
    setSellingRetailer(event) {
        this.handleChange(event.detail.selectedOption,'idSellingRetailer');
    }
    setBuyingRetailer(event) {
        this.handleChange(event.detail.selectedOption,'idBuyingRetailer');
    }
    handleChange(idSelected,targetId) {
        if(idSelected) {           
            if(targetId == 'idSellingRetailer') {
                this.selectedSellingRetailerId = idSelected;
                this.showSellingRetailerDetails = false;
                for(let retailer of this.varAccounts) {
                    if(this.selectedSellingRetailerId == retailer.Id) {
                        this.selectedSellingRetailer = retailer;
                        this.showSellingRetailerDetails = true;                        
                        this.varOriginalAppointmentDate =retailer.Org_non_activated__c;
                        break;
                    }
                }
            }
            if(targetId == 'idBuyingRetailer') {
                this.selectedBuyingRetailerId = idSelected;
                this.showBuyingRetailerDetails = false;
                for(let retailer of this.varAccounts) {
                    if(this.selectedBuyingRetailerId == retailer.Id) {
                        this.selectedBuyingRetailer = retailer;
                        this.showBuyingRetailerDetails = true;
                        break;
                    }
                }
            }
            
        }  else {
            if(idSelected =='' && targetId == 'idSellingRetailer'){
                this.showSellingRetailerDetails = false;
            }
            else if(idSelected =='' && targetId == 'idBuyingRetailer'){
                this.showBuyingRetailerDetails = false;
            }
            
            
        }      
    }
    /*checkOriginalAppointmentDate(event) {
        this.varOriginalAppointmentDate = event.target.value;
        if(new Date(this.varOriginalAppointmentDate) < new Date(this.varOriginalAppointmentDateMin)) {
            this.strModalHeader = "Confirm Original Appointment Date";
            let dateToShow = new Date(this.varOriginalAppointmentDate);
            this.strModalBody = "The original appointment date "
                +((dateToShow.getMonth()+1) < 10 ?'0'+(dateToShow.getMonth()+1):dateToShow.getMonth())
                +'/'+((dateToShow.getDate()) < 10 ?'0'+dateToShow.getDate():dateToShow.getDate())
                +'/'+dateToShow.getFullYear()
                +" is more than 30 days prior. Do you want to proceed with this date?";
            this.strModalType = "confirmAppointmentDate";
            this.blnOkButton = true;
            this.blnCancelButton = true;
            this.blnNotificationActive = true;
        }
    }*/
    handleNotification(event) {
        if(event.detail.type == "confirmAppointmentDate") {
            if(event.detail.name == 'ok') {
                this.blnNotificationActive = false;                
            }
            if(event.detail.name == 'cancel') {
                this.blnNotificationActive = false;
                let elemOriginalAppointmentDate = this.template.querySelector('.classOriginalAppointmentDate')
                elemOriginalAppointmentDate.value = "";
                elemOriginalAppointmentDate.focus();
            }
            if(event.detail.name == 'close') {
                this.blnNotificationActive = false;
            }
        }
        if(event.detail.type == "confirmBuySell") {
            if(event.detail.name == 'ok') {
                this.nextModal();                
            }
            if(event.detail.name == 'cancel') {
                this.blnNotificationActive = false; 
                this.closeModal();               
            }
            if(event.detail.name == 'close') {
                this.blnNotificationActive = false;
            }
        }
    }
}