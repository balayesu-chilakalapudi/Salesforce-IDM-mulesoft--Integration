import { LightningElement, track, api } from 'lwc';

export default class DPM_BuySellPersonnelSelectionConfirmation extends LightningElement {
    @track isOpenModal = false;
    @api isModOpen= false;
    @api idFromSelection;
    @api buy;
    @api sell;
 
    handleCloseModal() {
        this.isOpenModal = true;
    }
    editLst(){
    const selectedEvent = new CustomEvent("modvaluechange", {
      detail: this.isModOpen
    });
    this.dispatchEvent(selectedEvent);
  }
  nextModal(event) {
        let varDataToPass = {stage:'3'};
        this.dispatchEvent(new CustomEvent('nextModal',{
            detail : {varDataToPass},            
        }));
  }
}