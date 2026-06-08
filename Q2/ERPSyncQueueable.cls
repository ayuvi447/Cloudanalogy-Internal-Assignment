public class ERPSyncQueueable implements Queueable, Database.AllowsCallouts {
private List<Id> accountIds;
private Integer retryCount;

public ERPSyncQueueable(List<Id> accountIds, Integer retryCount) {
    this.accountIds = accountIds;
    this.retryCount = retryCount;
}

public void execute(QueueableContext context) {

    ERP_Config__mdt config = [
        SELECT Endpoint_URL__c,
               Timeout_ms__c,
               Max_Retries__c
        FROM ERP_Config__mdt
        LIMIT 1
    ];

    Integer maxRetries = Integer.valueOf(config.Max_Retries__c);

    List<Id> batchIds = new List<Id>();

    for(Integer i = 0;
        i < 10 && i < accountIds.size();
        i++) {

        batchIds.add(accountIds[i]);
    }

    List<Account> accounts = [
        SELECT Id,
               Name,
               Phone,
               BillingCity,
               Sync_Status__c,
               Sync_Retry_Count__c
        FROM Account
        WHERE Id IN :batchIds
    ];

    HttpResponse res = makeCallout(accounts, config);

    if(res.getStatusCode() == 200){

        for(Account acc : accounts){
            acc.Sync_Status__c = 'Synced';
            acc.Last_Sync_Time__c = System.now();
            acc.Sync_Retry_Count__c = 0;
        }

        update accounts;

        List<Id> remainingIds = new List<Id>();

        for(Integer i = 10;
            i < accountIds.size();
            i++){

            remainingIds.add(accountIds[i]);
        }

        // TEST context me chaining mat karo
        if(!remainingIds.isEmpty()
           && !Test.isRunningTest()){

            System.enqueueJob(
                new ERPSyncQueueable(
                    remainingIds,
                    0
                )
            );
        }

    } else {

        if(retryCount < maxRetries){

            for(Account acc : accounts){

                Integer currentRetry =
                    acc.Sync_Retry_Count__c == null
                    ? 0
                    : Integer.valueOf(
                        acc.Sync_Retry_Count__c
                    );

                acc.Sync_Retry_Count__c =
                    currentRetry + 1;
            }

            update accounts;

            // TEST context me retry chain mat karo
            if(!Test.isRunningTest()){

                System.enqueueJob(
                    new ERPSyncQueueable(
                        accountIds,
                        retryCount + 1
                    )
                );
            }

        } else {

            List<Error_Log__c> errors =
                new List<Error_Log__c>();

            for(Account acc : accounts){

                acc.Sync_Status__c = 'Failed';

                errors.add(
                    new Error_Log__c(
                        Account__c = acc.Id,
                        Response_Body__c =
                            res.getBody(),
                        Error_Time__c =
                            System.now()
                    )
                );
            }

            update accounts;

            if(!errors.isEmpty()){
                insert errors;
            }

            List<Id> remainingIds =
                new List<Id>();

            for(Integer i = 10;
                i < accountIds.size();
                i++){

                remainingIds.add(accountIds[i]);
            }

            if(!remainingIds.isEmpty()
               && !Test.isRunningTest()){

                System.enqueueJob(
                    new ERPSyncQueueable(
                        remainingIds,
                        0
                    )
                );
            }
        }
    }
}

private HttpResponse makeCallout(
    List<Account> accounts,
    ERP_Config__mdt config
){

    String body =
        JSON.serialize(accounts);

    HttpRequest req =
        new HttpRequest();

    req.setEndpoint(
        config.Endpoint_URL__c
    );

    req.setMethod('POST');

    req.setHeader(
        'Content-Type',
        'application/json'
    );

    req.setBody(body);

    req.setTimeout(
        Integer.valueOf(
            config.Timeout_ms__c
        )
    );

    Http http = new Http();

    return http.send(req);
}


}
