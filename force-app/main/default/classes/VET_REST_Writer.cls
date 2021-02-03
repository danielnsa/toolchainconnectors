public class VET_REST_Writer {
  
    @InvocableMethod
  
    public static void VET_REST_Writer(List<ID> ids) {
        // for each Transaction update called by the VeChain ReadWrite V1 process, invoke an outbound Async API call
        for (Id tId : ids){
            System.debug('tId: ' + tId);
            List<VET_TrackInfo__c> newTIds = [SELECT Id, toolChain_orderStatus__c FROM VET_TrackInfo__c WHERE Id=:tId LIMIT 1]; 
            if (newTIds[0].toolChain_orderStatus__c=='NEW'){
                VET_RESTAPI_Async.invokeToolChain(tId);
                System.debug('newTIds[0].toolChainResponseorderStatus__c: '+newTIds[0].toolChain_orderStatus__c);
            } else
                VET_RESTAPI_Async.pollToolChain(tId);
                System.debug('ELSE newTIds[0].toolChainResponseorderStatus__c: '+newTIds[0].toolChain_orderStatus__c);
            }
    }
}
