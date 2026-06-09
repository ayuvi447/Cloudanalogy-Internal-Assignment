@RestResource(urlMapping='/v2/opportunities/*')
global class OpportunityApiV2 extends OpportunityApiV1 {
@HttpGet
    global static void doGet(){
        String lastPart=RestContext.Request.requestURI.substringAfterLast('/');
        if(lastPart.length()>=15){
          Opportunity opp=[select id, name ,stageName,amount,closeDate ,Gross_Margin1__c,(Select id,quantity, unitPrice from OpportunityLineItems) from Opportunity where id =:lastPart limit 1];
            RestContext.response.statusCode=200;
            RestContext.response.responseBody=Blob.valueOf(JSON.serialize(opp));
        }else{
            String accountId=RestContext.request.params.get('accountId');
            List<Opportunity> oppList=[select id,name,stagename,closedate,Gross_Margin1__c from Opportunity where AccountId=:accountId limit 10];
             RestContext.response.statusCode=200;
            RestContext.response.responseBody=Blob.valueOf(JSON.serialize(oppList));
        }
    }
}