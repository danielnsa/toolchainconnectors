import { LightningElement, track } from 'lwc';

export default class ToolChainLWCReaderv1 extends LightningElement {
    @track toolchainJSON;
    @track enteredId;
    @track retrievedSKU;
    @track retrievedTrackData;
 
      //Get record based on entering a specific ID value
      handleGetRecordbyId(event){
        this.enteredId = event.detail.value;
        let textVAR = {"vid" : this.enteredId ,"types": ["sku","trackinfo"]};
        this.toolchainJSON = JSON.stringify(textVAR);
        console.log('1. toolchainJSON: ', this.toolchainJSON);
    }

    //Make callout to ToolChain API Endpoint to fetch record
    handleGetRecordfromVET(){
        let endPoint = 'https://v.vechain.com/v2/data';
        fetch(endPoint,
            {
                // Request type
                method:"POST",

                // Headers
                headers:{
                    'Accept': 'application/json',
                    'Content-Type': 'application/json'
                },

                // JSON body
                body: this.toolchainJSON
            })
            // returning the response in the form of JSON
            .then((response) => response.json())

            .then((jsonResponse) => { 
                console.log('2. jsonResponse ', jsonResponse);
           
            // Assign variable for part of returned JSON for SKU data
                let returnedSKU = jsonResponse.data.jsonData.sku.base;


            // Create Object for SKU data to return
                let skuData = {
                    productimage : '',
                    productname : '',
                    description : ''
                };
                
            // Assign retrieved JSON to SKU Object parameters 
                skuData.productimage = returnedSKU.mainimage['filelocation'];
                skuData.productname = returnedSKU['productname'];
                skuData.description = returnedSKU['description'];

            // Return SKU data to HTML
                this.retrievedSKU = skuData;
                console.log('this.retrievedSKU data: ',this.retrievedSKU);


            // Assign variable for part of returned JSON for Tracking data
                let returnedTrackInfo = jsonResponse.data.jsonData.trackinfo;
                let noTrackedInfo = jsonResponse.data.jsonData.trackinfo.length;
                console.log('3. jsonResponse for Tracking data', returnedTrackInfo);

            // Create Array to assign returned Tracking Data
                var trackInfoData = new Array(noTrackedInfo);

            // Iterate over returned JSON for tracking data and assign to Array 
                for (let i = 0; i < noTrackedInfo; i++) {
                    trackInfoData[i]=({
                        trackNo : i + 1, 
                        dataVid : returnedTrackInfo[i].blockinfo.dataVid, 
                        name : returnedTrackInfo[i].base.name, 
                        timeStamp : new Date(parseInt(returnedTrackInfo[i].custom.tracktime)),
                    });
                }
                
                console.log('3.2 trackInfoData final: ',trackInfoData);

            // Return Tracking Data Array to HTML
                this.retrievedTrackData = trackInfoData;
                console.log('3.3 retrievedTrackData: ',this.retrievedTrackData);
            })

            .catch(error => {
                console.log('4. error: ', error);
            })
    }

}