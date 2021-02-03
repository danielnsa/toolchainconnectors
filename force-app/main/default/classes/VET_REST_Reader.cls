public inherited sharing class VET_REST_Reader {
    
    @AuraEnabled
    public static Boolean retrieveViD(String strViD, Id ownerId, Id appointmentId){
       
    // Call ToolChain to get the JSON for the corresponding ViD
        System.debug('ViD passed in: '+strViD);
        System.debug('Account record Id passed on: '+ownerId);
        System.debug('Appointment record Id passed on: '+appointmentId);


        String strResponse = null;

        // create JSON Body for ToolChain callout
        Map<String,Object> v2dataMap = new Map<String,Object>();
        v2dataMap.put('vid', strViD);
        List<String> v2subtypes = new List<String>{'sku','trackinfo'};
        v2dataMap.put('types',v2subtypes);
        String v2datajsonbody = JSON.serialize(v2dataMap);
        System.debug('v2datajsonbody: '+v2datajsonbody);

        if(String.isNotBlank(strViD)) {
            HttpRequest httpRequest = new HttpRequest();  
            httpRequest.setEndpoint('https://v.vechain.com/v2/data');
            httpRequest.setMethod('POST');   
            httpRequest.setHeader('Accept', 'application/json');        
            httpRequest.setHeader('Content-Type', 'application/json');
            httpRequest.setBody(v2datajsonbody); 
            
            try {  
                Http http = new Http();   
                HttpResponse httpResponse = http.send(httpRequest);

                if (httpResponse.getStatusCode() == 200 ) {  
                    strResponse = httpResponse.getBody();
                    System.debug('strResponse: '+strResponse);
                } 
                else {  
                    throw new CalloutException(httpResponse.getBody()); 
                }   
            } 
            catch(Exception ex) {  
                throw ex;  
            }  
        } 

        // Work with the return JSON from ToolChain
        map<String, Object> mapJsonData = new map<String, Object>();
        if(!String.isBlank(strResponse)) {
            // Deserialise strResponse & progress to key sections in JSON
            mapJsonData = (map<String, Object>)JSON.deserializeUntyped(strResponse);
            System.debug('mapJsonData: '+mapJsonData);
            Map<String,Object> rootData = (Map<String,Object>)mapJsonData.get('data');
            Map<String,Object> jsonData = (Map<String,Object>)rootData.get('jsonData');
            System.debug('rootData: '+rootData);
            System.debug('jsonData: '+jsonData);
           
            // Start of Tracking Information JSON elements
            List<Object> trackData = (List<Object>)jsonData.get('trackinfo');

            // Start of SKU JSON elements
            Map<String,Object> skuData = (Map<String,Object>)jsonData.get('sku'); // SKU start
            Map<String,Object> skuBlock = (Map<String,Object>)skuData.get('blockinfo'); // SKU Block Information
            Map<String,Object> baseData = (Map<String,Object>)skuData.get('base'); // Base section under SKU
            Map<String,Object> imageData = (Map<String,Object>)baseData.get('mainimage'); // Image ection under SKU
            List<Object> prodparames = (List<Object>)baseData.get('productparames'); // Custom product parameters under SKU
            
        // Retrieve image from ToolChain and convert to blob
        HttpRequest imgreq = new HttpRequest();
        Blob imageblob = null;
        imgreq.setMethod('GET');
        imgreq.setEndpoint(String.valueOf(imageData.get('filelocation')));
        
            try {  
                Http binding = new Http();
                HttpResponse imgres = binding.send(imgreq); 

                if (imgres.getStatusCode() == 200 ) {  
                    imageblob = imgres.getBodyAsBlob();
                } 
                else {  
                    throw new CalloutException(imgres.getBody()); 
                }   
            } 
            catch(Exception imageex) {  
                throw imageex;  
            }  
        
        // Create Customer Product Item record
        VET_Product_Item__c customerProd = new VET_Product_Item__c();

            // Assign Product Owner, if ownerId variable passed in
            if (ownerId != null){
                customerProd.VETProduct_Owner__c = ownerId;
            }  

            // Assign JSON values to record fields
            customerProd.VET_ViD__c = String.valueOf(rootData.get('vid'));
            customerProd.VET_SKU_dataUuid__c = String.valueOf(skuBlock.get('dataUuid'));
            customerProd.VET_SKU_dataVid__c = String.valueOf(skuBlock.get('dataVid'));
            customerProd.VET_SKU_productDescription__c = String.valueOf(baseData.get('description'));
            customerProd.VET_SKU_productname__c = String.valueOf(baseData.get('productname'));
            customerProd.VET_Last_Synch__c = DateTime.now();

            
            // Add Custom fields to Customer Product record
            String key = '';
            String value = '';
            String valueField = '';
            String keyField = '';
            Integer countofparams = 1;
                for(Object indParams : prodparames){
                    if (indParams != null){
                        String kvpair = String.valueof(indParams);
                        key = kvpair.substringBetween('key=',',');
                        value = kvpair.substringBetween('value=', '}');
                        valueField = 'VET_SKU_productparames_'+ countofparams + '__c';
                        keyField = 'VET_SKU_productparames_label_'+ countofparams + '__c';
                        customerProd.put(valueField,value);
                        customerProd.put(keyField,key);
                        countofparams = countofparams + 1;
                    } else System.debug('NULL');
                }
            try {  
                insert customerProd;
            } catch(Exception exCustProbItem) {  
                throw exCustProbItem; 
            } 

            // Link Customer Product to Service Appointment, if recordId is passed
            if (appointmentId != null){
                customerProd.VET_serviceappointment__c = appointmentId;
                ServiceAppointment appointmentlink = new ServiceAppointment();
                appointmentlink.Id = appointmentId;
                appointmentlink.Product_Item__c = customerProd.Id;
                try {  
                    update appointmentlink;
                } catch(Exception exApptItem) {  
                    throw exApptItem; 
                } 
            }  
            
            // Create a File for Product Image and associate to Customer Product record
            ContentVersion conVer = new ContentVersion();
            conVer.ContentLocation = 'S'; // S specify this document is in SF, use E for external files
            conVer.PathOnClient = String.valueOf(imageData.get('filename')); // The files name, extension is very important here which will help the file in preview.
            conVer.Title = String.valueOf(baseData.get('productname')); // Display name of the files
            conVer.VersionData = imageblob; // Blob of Image
            try {        
                insert conVer;
            } catch (Exception exconVer){
                throw exconVer;
            }

            //Create ContentDocumentLink
            Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId; // First get the content document Id from ContentVersion
            ContentDocumentLink cDe = new ContentDocumentLink();
            cDe.ContentDocumentId = conDoc;
            cDe.LinkedEntityId = customerProd.Id; // link to Customer Product Id inserted previously
            cDe.ShareType = 'I'; // Inferred permission, checkout description of ContentDocumentLink object for more details
            cDe.Visibility = 'InternalUsers';
            try {
                insert cDe;
            } catch (Exception exCde){
                throw exCde;
            }
                
        // --- end of Customer Product Item record creation -----

        // Create Product Item Tracking record
        for(Object indTracks : trackData){
            VET_TrackInfo__c trackProdItem = new VET_TrackInfo__c();
            if (indTracks != null){
                String trackinf = String.valueof(indTracks);
                trackProdItem.VET_Product_Item__c = customerProd.Id;
                trackProdItem.VET_trackInfo_name__c = trackinf.substringBetween('name=',',');
                trackProdItem.VET_trackInfo_timeStamp__c = Datetime.newInstance(Long.valueOf(trackinf.substringBetween('tracktime=', ',')));
                trackProdItem.VET_trackinfo_dataUuid__c = trackinf.substringBetween('dataUuid=',',');
                trackProdItem.VET_trackinfo_dataVid__c = trackinf.substringBetween('dataVid=',',');  
                trackProdItem.Status__c  =  'Existing';       
                trackProdItem.VET_trackinfo_lastsynch__c  =  DateTime.now();       
                try {    
                    insert trackProdItem;
                } catch (Exception extrackPItem) {
                    throw extrackPItem;
                }
            }
        }
        return true;
       } else {
           return false;
       }
    }
}