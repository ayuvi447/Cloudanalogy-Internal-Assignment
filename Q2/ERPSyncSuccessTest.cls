@isTest
private class ERPSyncSuccessTest {

    @isTest
    static void testSuccess(){

        List<Account> accounts =
            new List<Account>();

        for(Integer i=0;i<15;i++){
            accounts.add(
                new Account(
                    Name='Acc '+i,
                    Sync_Status__c='Pending',
                    Sync_Retry_Count__c=0
                )
            );
        }

        insert accounts;

        Test.setMock(
            HttpCalloutMock.class,
            new ERPCalloutMockSuccess()
        );

        Test.startTest();

        System.enqueueJob(
            new ERPSyncQueueable(
                new List<Id>{accounts[0].Id},
                0
            )
        );

        Test.stopTest();

        Account acc = [
            SELECT Sync_Status__c
            FROM Account
            WHERE Id=:accounts[0].Id
        ];

        System.assertEquals(
            'Synced',
            acc.Sync_Status__c
        );
    }
}