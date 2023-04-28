import { LightningElement, track, api } from 'lwc';

export default class DPM_SearchBox extends LightningElement {
    @api options;
    @track optionsFiltered;
    @track selectedOption = {label:'',value:''};
    @track inputFilter = '';
    @track preventBlur = false;
    @api isRequired = false;
    @api errorMessage;
    @api selectedId;
    connectedCallback() {
        this.optionsFiltered = this.options;
    }
    renderedCallback() {
        let cmpOptionsDiv = this.template.querySelector(".classOptionsBox");
        let varTemplate = this;
        cmpOptionsDiv.addEventListener("mousedown",function() {
            varTemplate.preventBlur = true;
        });
        if(this.selectedId) {
            this.handleOptionSelection(this.selectedId);
        }        
    }
    showOptions() {
        this.handleErrors(false);
        let optionsBox = this.template.querySelector(".classOptionsBox");
        optionsBox.classList.remove("slds-hide");
    }
    optionSelected(event) {
        let selectedOptionValue = event.currentTarget.dataset.record;
        this.handleOptionSelection(selectedOptionValue);
    }
    handleOptionSelection(selectedOptionValue) {
        for(let option of this.options) {
            if(selectedOptionValue == option.value) {
                this.selectedOption = option;                
                break;
            }
        }        
        this.preventBlur = false;
        let optionsBox = this.template.querySelector('.classOptionsBox');
        optionsBox.classList.add("slds-hide");
        let inputCmp = this.template.querySelector('.classFilterInput');
        inputCmp.value = this.selectedOption.label;
        this.handleErrors(false);
        this.onoptionselection(this.selectedOption.value);
    }
    onoptionselection(selectedValue) {
        const passEvent = new CustomEvent('optionselection', {
            detail:{selectedOption:selectedValue} 
        });
       this.dispatchEvent(passEvent);
    }
    filterOptions(event) {
        let filterText = event.currentTarget.value;
        if(filterText && this.options) {
            var filteredOptions = [];
            for(let option of this.options) {
                if((option.label.toString().toLowerCase()).includes(filterText.toString().toLowerCase())) {
                    filteredOptions.push(option);
                }
            } 
            this.optionsFiltered = filteredOptions;
        }        
    }
    hideOptions(event) {
        let vartarget = event.currentTarget;
        let filterText = vartarget.value;
        let templateCmp = this;
        if(!this.preventBlur) {
            window.setTimeout(
                function() {
                    let optionsBox = templateCmp.template.querySelector('.classOptionsBox');
                    optionsBox.classList.add("slds-hide");
                    let hasMatch = false;
                    for(let option of templateCmp.options) {
                        if((option.label.toString().toLowerCase()) == filterText.toString().toLowerCase()) {
                            hasMatch = true;
                            break;
                        }
                    } 
                    if(!hasMatch) {
                        vartarget.value='';
                        templateCmp.selectedOption = {label:'',value:''};
                        templateCmp.onoptionselection('');
                        templateCmp.optionsFiltered = templateCmp.options;
                    }
                },200);
        } 
        this.preventBlur = false;
    }
    @api checkValidity() {
        let blnValid = true;
        let inputCmp = this.template.querySelector(".slds-input");
        if(!inputCmp.value) {            
            blnValid = false;
            this.handleErrors(true);
        }        
        return blnValid;
      }
      handleErrors(hasError) {
        let cmpEnvelope = this.template.querySelector('.classEnvelope');        
        let cmpErrorMsg = this.template.querySelector('.slds-form-element__help');
        if(hasError) {
            cmpEnvelope.classList.add("slds-has-error");
            cmpErrorMsg.classList.remove("slds-hide");
        } else {
            cmpEnvelope.classList.remove("slds-has-error");
            cmpErrorMsg.classList.add("slds-hide");
        }        
      }
}