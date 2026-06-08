@isTest
private class ERPSyncFailureTest {

    @isTest
    static void testFailure(){

        Account acc =
            new Account(
                Name='Failed Acc',
                Sync_Status__c='Pending'
            );

        insert acc;

        Test.setMock(
            HttpCalloutMock.class,
            new ERPCalloutMockFailure()
        );

        Test.startTest();

        System.enqueueJob(
            new ERPSyncQueueable(
                new List<Id>{acc.Id},
                3
            )
        );

        Test.stopTest();

        Account updated =
        [
            SELECT Sync_Status__c
            FROM Account
            WHERE Id=:acc.Id
        ];

        System.assertEquals(
            'Failed',
            updated.Sync_Status__c
        );

        System.assert(
            [SELECT Count()
             FROM Error_Log__c] > 0
        );
    }
}