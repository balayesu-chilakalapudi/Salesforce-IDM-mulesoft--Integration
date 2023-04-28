import { LightningElement, api } from 'lwc';

export default class DPM_NotificationLibrary extends LightningElement {
    @api strModalHeader;
    @api strModalBody;
    @api strModalType;
    @api blnOkButton = false;
    @api blnCancelButton = false;
    @api blnConfirmButton = false;
    @api blnEditListButton = false;
    closeModal() {
        this.notificationDispatch('close');
    }
    cancelModal() {
        this.notificationDispatch('cancel');
    }
    okClicked() {        
        this.notificationDispatch('ok');
    }
    editModal() {
        this.notificationDispatch('edit');
    }
    notificationDispatch(eventName) {
        this.dispatchEvent(new CustomEvent('notification',{
            detail : {name:eventName,type:this.strModalType}
        }));
    }
}