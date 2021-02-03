public with sharing class VET_RESTAPI_Async {
    
    // Variables across classes  
      // Record and General Config Variables for ToolChain
        String nonce = '3806143519628774'; 
        DateTime dt = DateTime.now(); 
        Integer timestamp = Integer.valueOf(dt.getTime()/1000); 
        Double gpslat = 1.3521;
        Double gpslon = 103.9198;
        String submitStatus = 'SUBMIT';
        String requestNo =  String.valueOf((dt.getTime()/1000)+Integer.valueof((Math.random() * 100)));  
      // In Session Variables from and for ToolChain
        ToolChainDCPs__C tSet = ToolChainDCPs__c.getInstance();
        VET_TrackInfo__c vetTrackItem = new VET_TrackInfo__c();
        List<toolChainToken__b> tokenStore =  new List<toolChainToken__b>(); 
        Id transactionId = null;
        String name = null;
        String tokenJSON = null;
        String tChainToken = null;
        String createprocessJSON = null;
        String toolChain_JSON_Response = null;
        String toolChainResponseCode = null;
        String toolChainResponseOrderStatus = null;
        String toolChainResponseMsg = null;
    
    
    
    // Constructor Class called by VET_REST_Writer to create initial Track Info creation
    @future(callout=true)
    public static void invokeToolChain(Id transactionId)
    {

        VET_RESTAPI_Async thisCall = new VET_RESTAPI_Async();
        thisCall.transactionId = transactionId;
        System.debug('thisCall.transactionId: '+thisCall.transactionId);
        System.debug('ToolChainDCPs__c tSet.trackinfoDCPUUID__c: '+thisCall.tSet.trackinfoDCPUUID__c);
       
        // Retrieve the Product Track Item record associated in the "transactionId" parameter & assign valuew to this.vetTrackItem variable
        List<VET_TrackInfo__c> newTrackInfo = [SELECT Id, VET_trackinfo_lastsynch__c, toolChainResponseCode__c,toolChainResponseMsg__c, toolChain_orderStatus__c, toolChain_JSON_Response__c, JSON_Out__c, VET_Product_Item__r.VET_ViD__c, VET_trackInfo_timeStamp__c, VET_trackInfo_name__c, VET_update_request_no__c FROM VET_TrackInfo__c WHERE Id=:thisCall.transactionId LIMIT 1];
        thisCall.vetTrackItem = newTrackInfo[0];
        System.debug('thisCall.vetTrackItemtoolChainResponseorderStatus__c: '+thisCall.vetTrackItem.VET_trackInfo_name__c);
            
        // Create outbound Toolchain JSON body & assign valuew to this.createprocessJSON variable
        try {  
            thisCall.createtoolChainJSON();
            System.debug('thisCall.createtoolChainJSON(): '+thisCall.createprocessJSON);
        } catch(Exception ex) {  
            throw ex;
        }

        // Invoke call to Toolchain for token & assign in this session to this.tChainToken variable
        try {
            thisCall.getToolchainToken();
            System.debug('this.getToolchainToken(): '+thisCall.tChainToken);
        } catch(Exception ex) {  
            throw ex;
        }

        // Invoke call to Toolchain to initiate Track Info update
        try {
            thisCall.createTrackingInfo();
            System.debug('this.toolChain_JSON_Response(): '+thisCall.toolChain_JSON_Response);
        } catch(Exception ex) {  
            throw ex;
        }
            
        // Update this.vetTrackItem and associated record
        thisCall.vetTrackItem.JSON_Out__c = thisCall.createprocessJSON;
        thisCall.vetTrackItem.toolChainResponseCode__c = thisCall.toolChainResponseCode;
        thisCall.vetTrackItem.toolChainResponseMsg__c = thisCall.toolChainResponseMsg;
        thisCall.vetTrackItem.toolChain_orderStatus__c = thisCall.toolChainResponseOrderStatus;
        thisCall.vetTrackItem.toolChain_JSON_Response__c = thisCall.toolChain_JSON_Response;
        thisCall.vetTrackItem.VET_trackinfo_lastsynch__c = Datetime.now();
        thisCall.vetTrackItem.VET_update_request_no__c = thisCall.requestNo;
        update thisCall.vetTrackItem;

    } 
        
    // Constructor Class called by VET_REST_Writer to create initial Track Info creation
    @future(callout=true)
    public static void pollToolChain(Id transactionId)
    {
        VET_RESTAPI_Async thisCall = new VET_RESTAPI_Async();
        thisCall.transactionId = transactionId;
        System.debug('thisCall.transactionId: '+thisCall.transactionId);
       
        // Retrieve the Product Track Item record associated in the "transactionId" parameter & assign valuew to this.vetTrackItem variable
        List<VET_TrackInfo__c> newTrackInfo = [SELECT Id, VET_trackinfo_lastsynch__c, toolChainResponseCode__c,toolChainResponseMsg__c, toolChain_orderStatus__c, toolChain_JSON_Response__c, JSON_Out__c, VET_Product_Item__r.VET_ViD__c, VET_trackInfo_timeStamp__c, VET_trackInfo_name__c, VET_update_request_no__c FROM VET_TrackInfo__c WHERE Id=:thisCall.transactionId LIMIT 1];
        thisCall.vetTrackItem = newTrackInfo[0];
        System.debug('thisCall.vetTrackItemtoolChainResponseorderStatus__c: '+thisCall.vetTrackItem.VET_trackInfo_name__c);

        // Retrieve original JSON created in the 1syt outbound Toolchain call from the JSON_Out__c field
        thisCall.createprocessJSON = thisCall.vetTrackItem.JSON_Out__c;

        // Invoke call to Toolchain for token & assign in this session to this.tChainToken variable
        try {
            thisCall.getToolchainToken();
            System.debug('this.getToolchainToken(): '+thisCall.tChainToken);
        } catch(Exception ex) {  
            throw ex;
        }

        // Invoke call to Toolchain to poll the Track Info update
        try {
            thisCall.createTrackingInfo();
            System.debug('this.toolChain_JSON_Response(): '+thisCall.toolChain_JSON_Response);
        } catch(Exception ex) {  
            throw ex;
        }
                
        // Update this.vetTrackItem and associated record
        thisCall.vetTrackItem.toolChainResponseCode__c = thisCall.toolChainResponseCode;
        thisCall.vetTrackItem.toolChainResponseMsg__c = thisCall.toolChainResponseMsg;
        thisCall.vetTrackItem.toolChain_orderStatus__c = thisCall.toolChainResponseOrderStatus;
        thisCall.vetTrackItem.toolChain_JSON_Response__c = thisCall.toolChain_JSON_Response;
        thisCall.vetTrackItem.VET_trackinfo_lastsynch__c = Datetime.now();
        update thisCall.vetTrackItem;
    }  

     // Function to create outbound ToolChain JSON  
     public void createtoolChainJSON() {
                
        System.debug('vetProdItem.VET_Product_Item__c.VET_ViD__c: ' + this.vetTrackItem.VET_Product_Item__r.VET_ViD__c);
        List<String> createdcpvidArray = new List<String>{string.valueof(this.vetTrackItem.VET_Product_Item__r.VET_ViD__c)}; //ViD list array details
                
        Map<String,Object> createdcpvidlist = new Map<String,Object>(); //ViD list details
        createdcpvidlist.put('vidlist', createdcpvidArray);
        createdcpvidlist.put('type', 0);
        createdcpvidlist.put('num', '');

        Map<String,Object> createdcpgps = new Map<String,Object>(); //GPS list details
        createdcpgps.put('lat', this.gpslat);
        createdcpgps.put('lon', this.gpslon);

        Map<String,Object> createdcustom = new Map<String,Object>(); //Custom section  details
        createdcustom.put('vidlist', createdcpvidlist);
        createdcustom.put('department', this.tSet.Department__c);
        createdcustom.put('gps', createdcpgps);
        createdcustom.put('tracktime', this.timestamp);
        this.vetTrackItem.VET_trackInfo_timeStamp__c = this.dt;

        Map<String,Object> createdbase = new Map<String,Object>(); //Base section  details
        createdbase.put('timestamp', this.timestamp);
        createdbase.put('name', this.vetTrackItem.VET_trackInfo_name__c);

        Map<String,Object> createddatavalue = new Map<String,Object>(); //dataValue section details
        createddatavalue.put('custom', createdcustom);
        createddatavalue.put('base', createdbase);

        Map<String,Object> createdatalanddcp = new Map<String,Object>(); // defaultLangDCPValue section details
        createdatalanddcp.put('dataValue', createddatavalue);
               
        Map<String,Object> createdataMap = new Map<String,Object>(); // main JSON body
        createdataMap.put('defaultLangDCPValue', createdatalanddcp);
        createdataMap.put('dcpInstanceUUID', this.tSet.trackinfoDCPUUID__c);
        createdataMap.put('toolchainOperatorUUID', this.tSet.toolchainOperatorUUID__c);
        createdataMap.put('projectUUID', this.tSet.projectUUID__c);
        createdataMap.put('submitStatus', this.submitStatus);
        createdataMap.put('requestNo', this.requestNo);
                    
        this.createprocessJSON = JSON.serialize(createdataMap);
        this.vetTrackItem.JSON_Out__c = this.createprocessJSON;
        System.debug('this.createprocessJSON: '+this.createprocessJSON);
    }    

    // Function to call ToolChain get Token 
    public void getToolchainToken() {
        System.debug('Start of getToolchainToken');
        
        this.tokenStore.addAll([SELECT expireTime__c, token__c FROM toolChainToken__b WHERE expireTime__c >: this.dt]);
        System.debug('tokenStore.addAll '+this.tokenStore.size());

        if (this.tokenStore.size()>0){
            this.tChainToken = this.tokenStore[0].token__c;
            System.debug('getToolchainToken - using token from tokenStore: '+this.tokenStore[0].token__c);
        } 
        
        else {
            System.debug('getToolchainToken - Request a new token: '+this.tChainToken);

            String tokenResponse = null;

            // Create Token Query JSON Body 
            String sigString = 'appid=' + this.tSet.AppID__c + '&appkey=' + this.tSet.AppKey__c + '&nonce=' + this.nonce + '&timestamp=' + this.timestamp; 
            Blob sigBlob = Blob.valueOf(sigString); 
            Blob hash = Crypto.generateDigest('SHA-256', sigBlob); 
            String signature = EncodingUtil.convertToHex(hash); 
            String tracktime = String.valueOf(dt.getTime()/1000);
            
            Map<String,Object> tokendataMap = new Map<String,Object>();
            tokendataMap.put('source', this.tSet.mySource__c);
            tokendataMap.put('timestamp', this.timestamp);
            tokendataMap.put('signature', signature);
            tokendataMap.put('nonce', this.nonce);
            tokendataMap.put('appid', this.tSet.AppID__c);    
            this.tokenJSON = JSON.serialize(tokendataMap); // Assign Token string to public variable

            System.debug('Token jsonbody: '+this.tokenJSON);

            // Initiate ToolChain callout to token method
            if(String.isNotBlank(this.tokenJSON)) {
                HttpRequest httpRequest = new HttpRequest();  
                httpRequest.setEndpoint(this.tSet.toolChaintokenURL__c);
                httpRequest.setMethod('POST');   
                httpRequest.setHeader('Accept', 'application/json');        
                httpRequest.setHeader('Content-Type', 'application/json');
                httpRequest.setBody(this.tokenJSON);
                httpRequest.setTimeout(120000); 
                    
                try {  
                    Http http = new Http();   
                    HttpResponse httpResponse = http.send(httpRequest);

                    System.debug('getToolchainToken HttpResponse: '+httpResponse.getStatusCode());  

                    if (httpResponse.getStatusCode() == 200 ) {  
                        tokenResponse = httpResponse.getBody();
                        System.debug('getToolchainToken tokenResponse: '+tokenResponse);

                        // Retrieve and store the token from the ToolChain response
                        map<String, Object> mapJsonData = new map<String, Object>();
                        if(!String.isBlank(tokenResponse)) {
                            // Deserialise tokenResponse & progress to key sections in JSON
                            mapJsonData = (map<String, Object>)JSON.deserializeUntyped(tokenResponse);
                            Map<String,Object> tokenData = (Map<String,Object>)mapJsonData.get('data');
                            String tctoken = String.valueOf(tokenData.get('token'));
                            Integer tokenUTC = Integer.valueOf(tokenData.get('expireTime'));
                            Datetime exptime = Datetime.newInstanceGmt(1970, 1, 1, 0, 0, 0);
                            exptime.addSeconds(tokenUTC);
                            System.debug('getToolchainToken exptime: '+exptime.addSeconds(tokenUTC));
                            If (exptime.addSeconds(tokenUTC) > Datetime.now()){
                                System.debug('getToolchainToken exptime SUCCESS!');
                                
                                // Clear out old tokens in Big Object
                                Database.deleteImmediate(this.tokenStore);

                                // Add new token
                                toolChainToken__b newToken = new toolChainToken__b();
                                newToken.expireTime__c = exptime.addSeconds(tokenUTC);
                                newToken.token__c = tctoken;
                                database.insertImmediate(newToken);
                            }

                            this.tChainToken = tctoken;
                            System.debug('getToolchainToken this.tChainToken: '+this.tChainToken);
                        }
                    } 
                    else {
                        this.toolChainResponseOrderStatus = 'ERROR - getToolchainToken: '+this.toolChainResponseOrderStatus;
                        System.debug('getToolchainToken CalloutException: '+httpResponse.getBody());  
                    }   
                } 
                    catch(Exception ex) {  
                    throw ex;  
                }  
            }
        }
    }
   
    // Function to call ToolChain process create 
    public void createTrackingInfo() {
        System.debug('Start of invokeInitialprocessCreate + this.createprocessJSON: '+ this.createprocessJSON); 
        System.debug('Start of invokeInitialprocessCreate + this.tChainToken: '+ this.tChainToken); 
        String createResponse = null;
       
        // Create first callout request
        if(String.isNotBlank(this.createprocessJSON)) {
            HttpRequest httpRequest = new HttpRequest();
            httpRequest.setEndpoint(this.tSet.toolChaincreateURL__c);
            httpRequest.setMethod('POST');   
            httpRequest.setHeader('Accept', 'application/json');        
            httpRequest.setHeader('Content-Type', 'application/json');
            httpRequest.setHeader('x-api-token', this.tChainToken);
            httpRequest.setBody(this.createprocessJSON);
            httpRequest.setTimeout(120000); 
    
            try {  
                Http http = new Http();   
                HttpResponse httpResponse = http.send(httpRequest);

                if (httpResponse.getStatusCode() == 200 ) {  
                    createResponse = httpResponse.getBody();
                    System.debug('createTrackingInfo create Response: '+createResponse);

                    // Retrieve and store the token from the ToolChain response
                    map<String, Object> mapJsonData = new map<String, Object>();
                    if(!String.isBlank(createResponse)) {
                        // Deserialise tokenResponse & progress to key sections in JSON
                        this.toolChain_JSON_Response=createResponse;
                        mapJsonData = (map<String, Object>)JSON.deserializeUntyped(createResponse);
                        System.debug('createTrackingInfo mapJsonData: '+mapJsonData);
                        this.toolChainResponseCode = String.valueOf(mapJsonData.get('code'));
                        this.toolChainResponseMsg = String.valueOf(mapJsonData.get('message'));
                        Map<String,Object> createData = (Map<String,Object>)mapJsonData.get('data');
                        if ((this.toolChainResponseCode.compareTo('common.success')==0 && (this.toolChainResponseMsg.compareTo('success')==0))) {
                            this.toolChainResponseOrderStatus = String.valueOf(createData.get('orderStatus'));
                            System.debug('createTrackingInfo process JSON -  Success: '+this.toolChainResponseOrderStatus);
                        } else {
                            this.toolChainResponseOrderStatus = 'ERROR - createTrackingInfo: '+this.toolChainResponseOrderStatus;
                            System.debug('createTrackingInfo process JSON -  Error: '+this.toolChainResponseOrderStatus);
                        } 
                    }
                } 
                else {  
                    this.toolChainResponseOrderStatus = 'ERROR - getToolchainToken: '+string.valueOf(httpResponse.getBody());    
                    }   
            } 
                catch(Exception ex) {  
                throw ex;  
            }  
    
        }
    }




}
