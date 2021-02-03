import { LightningElement, track, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

// Import APEX class
import getViDData from '@salesforce/apex/VET_REST_Reader.retrieveViD';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

const FIELDS = [
    'ServiceAppointment.AccountId'
];

export default class vechainApexReader extends LightningElement {
    @track status;
    @track enteredId;
    @api recordId;
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })serviceappointment;

    //Get record based on entering a specific ID value
    handleGetRecordbyId(event){
        this.enteredId = event.detail.value;
    }

    //Make callout to ToolChain API Endpoint to fetch record
    handleGetRecordfromVET(){
        // call APEX class
        getViDData({strViD : this.enteredId,ownerId : this.serviceappointment.data.fields.AccountId.value, appointmentId :this.recordId})
            // returning the response in the form of JSON
            .then(responseData => {
                const event = new ShowToastEvent({
                    title: 'Success',
                    message: 'Product data successfully retrieved from VeChain',
                    variant: 'success',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);
           })
           .catch(error => { 
               const event = new ShowToastEvent({
                    title: 'Error',
                    message: 'Product data not available or retrievable from VeChain',
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);
           })
    }

}