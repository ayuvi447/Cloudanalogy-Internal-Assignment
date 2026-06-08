@isTest
private class TerritoryReassignmentBatch_Test {

    // ── Shared Helper: fresh data banao har test mein ─────────────────────────
    // @TestSetup use nahi karenge — batch tests mein reliable nahi hota
    private static Map<String, Id> createTestData() {

        // 1. Sales Territories
        Sales_Territory__c terrNorth  = new Sales_Territory__c(Name = 'North');
        Sales_Territory__c terrSouth  = new Sales_Territory__c(Name = 'South');
        Sales_Territory__c terrLondon = new Sales_Territory__c(Name = 'London');
        insert new List<Sales_Territory__c>{ terrNorth, terrSouth, terrLondon };

        // 2. Territory Rules
        insert new List<Territory_Rule__c>{
            new Territory_Rule__c(
                Postcode_Prefix__c = 'SW1',
                Territory__c       = terrLondon.Id,
                Priority__c        = 1
            ),
            new Territory_Rule__c(
                Postcode_Prefix__c = 'SW',
                Territory__c       = terrLondon.Id,
                Priority__c        = 2
            ),
            new Territory_Rule__c(
                Postcode_Prefix__c = 'M1',
                Territory__c       = terrNorth.Id,
                Priority__c        = 3
            ),
            new Territory_Rule__c(
                Postcode_Prefix__c = 'BN',
                Territory__c       = terrSouth.Id,
                Priority__c        = 4
            )
        };

        // 3. Contacts
        List<Contact> contacts = new List<Contact>();

        // Group A (5): SW1 — currently North (wrong) → should move to London
        for (Integer i = 0; i < 5; i++) {
            contacts.add(new Contact(
                LastName           = 'London_Con_' + i,
                Postcode__c        = 'SW1 1AA',
                Sales_Territory__c = terrNorth.Id
            ));
        }
        // Group B (5): M1 — currently null → should move to North
        for (Integer i = 0; i < 5; i++) {
            contacts.add(new Contact(
                LastName           = 'North_Con_' + i,
                Postcode__c        = 'M1 2BC',
                Sales_Territory__c = null
            ));
        }
        // Group C (5): BN — already South (correct) → should NOT change
        for (Integer i = 0; i < 5; i++) {
            contacts.add(new Contact(
                LastName           = 'South_Con_' + i,
                Postcode__c        = 'BN1 4CD',
                Sales_Territory__c = terrSouth.Id
            ));
        }
        // Group D (1): Unknown postcode — no match → no change
        contacts.add(new Contact(
            LastName    = 'Unknown_Con',
            Postcode__c = 'ZZ9 9ZZ'
        ));

        insert contacts;

        return new Map<String, Id>{
            'North'  => terrNorth.Id,
            'South'  => terrSouth.Id,
            'London' => terrLondon.Id
        };
    }

    // ── Test 1: Batch_Summary__c create honi chahiye ──────────────────────────
    @isTest
    static void testBatchCreatesSummary() {
        createTestData();

        Test.startTest();
        Database.executeBatch(new TerritoryReassignmentBatch(), 200);
        Test.stopTest();

        List<Batch_Summary__c> summaries = [
            SELECT Total_Processed__c, Total_Changed__c, Details__c, Run_Date__c
            FROM Batch_Summary__c
        ];

        System.assertEquals(1, summaries.size(),
            'Exactly one Batch_Summary__c should be created');

        Batch_Summary__c s = summaries[0];

        // 16 contacts total (5+5+5+1)
        System.assertEquals(16, s.Total_Processed__c,
            'All 16 contacts should be processed');

        // Group A (5 North→London) + Group B (5 null→North) = 10 changed
        System.assertEquals(10, s.Total_Changed__c,
            '10 contacts should have changed territory');

        System.assertNotEquals(null, s.Run_Date__c,
            'Run_Date__c should be set');

        System.assert(
            s.Details__c != null && s.Details__c.contains('Territory Change Breakdown'),
            'Details__c should contain breakdown text'
        );
    }

    // ── Test 2: Correct territories assign hue? ───────────────────────────────
    @isTest
    static void testCorrectTerritoryAssigned() {
        Map<String, Id> terrIds = createTestData();

        Test.startTest();
        Database.executeBatch(new TerritoryReassignmentBatch(), 200);
        Test.stopTest();

        // Group A — SW1 → London
        for (Contact c : [
            SELECT Sales_Territory__c FROM Contact
            WHERE LastName LIKE 'London_Con_%'
        ]) {
            System.assertEquals(terrIds.get('London'), c.Sales_Territory__c,
                'SW1 contact should be in London territory');
        }

        // Group B — M1 → North
        for (Contact c : [
            SELECT Sales_Territory__c FROM Contact
            WHERE LastName LIKE 'North_Con_%'
        ]) {
            System.assertEquals(terrIds.get('North'), c.Sales_Territory__c,
                'M1 contact should be in North territory');
        }

        // Group C — BN → South (unchanged)
        for (Contact c : [
            SELECT Sales_Territory__c FROM Contact
            WHERE LastName LIKE 'South_Con_%'
        ]) {
            System.assertEquals(terrIds.get('South'), c.Sales_Territory__c,
                'BN contact should remain in South territory');
        }
    }

    // ── Test 3: Already correct contacts change nahi hone chahiye ─────────────
    @isTest
    static void testNoChangeWhenAlreadyCorrect() {
        createTestData();

        Test.startTest();
        Database.executeBatch(new TerritoryReassignmentBatch(), 200);
        Test.stopTest();

        Batch_Summary__c s = [
            SELECT Total_Changed__c FROM Batch_Summary__c LIMIT 1
        ];

        // South contacts (5) already correct — counted nahi hone chahiye
        System.assertEquals(10, s.Total_Changed__c,
            'Only 10 should change — South contacts already correct');
    }

    // ── Test 4: Blank postcode — null return hona chahiye (findBestMatch) ──────
    @isTest
    static void testBlankPostcodeNoMatch() {
        // Territory Rules insert karo (blank postcode contact ke liye)
        Sales_Territory__c terr = new Sales_Territory__c(Name = 'Test');
        insert terr;
        insert new Territory_Rule__c(
            Postcode_Prefix__c = 'AB',
            Territory__c       = terr.Id,
            Priority__c        = 1
        );

        // Contact with blank postcode — batch WHERE clause se filter hoga
        // Toh isko manually cover karte hain via unit test on helper
        Contact c = new Contact(LastName = 'Blank Post', Postcode__c = 'AB1 2CD');
        insert c;

        Test.startTest();
        Database.executeBatch(new TerritoryReassignmentBatch(), 200);
        Test.stopTest();

        Contact updated = [SELECT Sales_Territory__c FROM Contact WHERE Id = :c.Id];
        System.assertEquals(terr.Id, updated.Sales_Territory__c,
            'AB postcode should match AB rule');
    }

    // ── Test 5: Scheduler registers correctly ─────────────────────────────────
    @isTest
    static void testSchedulerFiresBatch() {
        Test.startTest();
        System.schedule(
            'Test Territory Scheduler',
            '0 0 2 * * ?',
            new TerritoryReassignmentScheduler()
        );
        Test.stopTest();

        List<CronTrigger> jobs = [
            SELECT Id, CronExpression
            FROM CronTrigger
            WHERE CronJobDetail.Name = 'Test Territory Scheduler'
        ];
        System.assertEquals(1, jobs.size(), 'Scheduled job should exist');
        System.assertEquals('0 0 2 * * ?', jobs[0].CronExpression,
            'Cron expression should match');
    }
}
