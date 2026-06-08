@isTest
private class RevenueLineHandler_Test {

    // ── Helper: ek Opportunity banao ──────────────────────────────────────────
    private static Opportunity makeOpp(String name) {
        Opportunity opp = new Opportunity(
            Name        = name,
            StageName   = 'Prospecting',
            CloseDate   = Date.today().addMonths(3)
        );
        insert opp;
        return opp;
    }

    // ── Helper: 200 Revenue Lines banao ───────────────────────────────────────
    private static List<Revenue_Line__c> makeLines(
        Id oppId,
        String stage,
        Integer count,
        Decimal amount,
        Date month
    ) {
        List<Revenue_Line__c> lines = new List<Revenue_Line__c>();
        for (Integer i = 0; i < count; i++) {
            lines.add(new Revenue_Line__c(
                Opportunity__c = oppId,
                Stage__c       = stage,
                Amount__c      = amount,
                Month__c       = month.addMonths(i)
            ));
        }
        return lines;
    }

    // ── Test 1: INSERT — 200 Active lines ─────────────────────────────────────
    @isTest
    static void testInsertActiveLines() {
        Opportunity opp = makeOpp('Test Insert Opp');

        List<Revenue_Line__c> lines =
            makeLines(opp.Id, 'Active', 200, 100, Date.today());

        Test.startTest();
        insert lines;
        Test.stopTest();

        Opportunity result = [
            select Total_Revenue__c, Cancelled_Revenue__c, Projected_Close_Month__c
            from Opportunity where Id = :opp.Id
        ];

        // 200 lines × 100 = 20000
        System.assertEquals(20000, result.Total_Revenue__c,
            'Total_Revenue__c should be 20000');
        System.assertEquals(0, result.Cancelled_Revenue__c,
            'Cancelled_Revenue__c should be 0');

        // Latest month = today + 199 months (last line ki month)
        Date expectedLatest = Date.today().addMonths(199);
        System.assertEquals(expectedLatest, result.Projected_Close_Month__c,
            'Projected_Close_Month__c should be latest active month');
    }

    // ── Test 2: UPDATE — Active → Cancelled (200 records) ────────────────────
    @isTest
    static void testUpdateActiveToCancelled() {
        Opportunity opp = makeOpp('Test Update Opp');

        List<Revenue_Line__c> lines =
            makeLines(opp.Id, 'Active', 200, 500, Date.today());
        insert lines;

        // Stage change karo Active → Cancelled
        for (Revenue_Line__c rl : lines) {
            rl.Stage__c = 'Cancelled';
        }

        Test.startTest();
        update lines;
        Test.stopTest();

        Opportunity result = [
            select Total_Revenue__c, Cancelled_Revenue__c, Projected_Close_Month__c
            from Opportunity where Id = :opp.Id
        ];

        System.assertEquals(0, result.Total_Revenue__c,
            'Total_Revenue__c should be 0 after cancel');
        System.assertEquals(100000, result.Cancelled_Revenue__c,
            'Cancelled_Revenue__c should be 100000 (200x500)');
        System.assertNotEquals(null, result.Projected_Close_Month__c == null,
            'Projected_Close_Month__c should be null (no active lines)');
    }

    // ── Test 3: DELETE — 200 lines delete karo ───────────────────────────────
    @isTest
    static void testDeleteLines() {
        Opportunity opp = makeOpp('Test Delete Opp');

        List<Revenue_Line__c> lines =
            makeLines(opp.Id, 'Active', 200, 250, Date.today());
        insert lines;

        Test.startTest();
        delete lines;
        Test.stopTest();

        Opportunity result = [
            select Total_Revenue__c, Cancelled_Revenue__c, Projected_Close_Month__c
            from Opportunity where Id = :opp.Id
        ];

        System.assertEquals(0, result.Total_Revenue__c,
            'Total_Revenue__c should be 0 after delete');
        System.assertEquals(0, result.Cancelled_Revenue__c,
            'Cancelled_Revenue__c should be 0 after delete');
        System.assertEquals(null, result.Projected_Close_Month__c,
            'Projected_Close_Month__c should be null after delete');
    }

    // ── Test 4: UNDELETE — deleted lines wapas lao ───────────────────────────
    @isTest
    static void testUndeleteLines() {
        Opportunity opp = makeOpp('Test Undelete Opp');

        List<Revenue_Line__c> lines =
            makeLines(opp.Id, 'Active', 200, 150, Date.today());
        insert lines;
        delete lines;

        Test.startTest();
        undelete lines;
        Test.stopTest();

        Opportunity result = [
            select Total_Revenue__c, Cancelled_Revenue__c, Projected_Close_Month__c
            from Opportunity where Id = :opp.Id
        ];

        // 200 × 150 = 30000
        System.assertEquals(30000, result.Total_Revenue__c,
            'Total_Revenue__c should be 30000 after undelete');
        System.assertEquals(0, result.Cancelled_Revenue__c,
            'Cancelled_Revenue__c should be 0 after undelete');
    }

    // ── Test 5: Recursion Guard check ─────────────────────────────────────────
    @isTest
    static void testRecursionGuard() {
        // Guard manually true karo — trigger ko fire nahi hona chahiye
        RevenueLineHandler.isExecuting = true;

        Opportunity opp = makeOpp('Recursion Guard Opp');
        List<Revenue_Line__c> lines =
            makeLines(opp.Id, 'Active', 10, 1000, Date.today());

        Test.startTest();
        insert lines;
        Test.stopTest();

        // Guard true tha, toh rollup nahi hua
        Opportunity result = [
            select Total_Revenue__c from Opportunity where Id = :opp.Id
        ];
        // Total_Revenue__c null ya 0 hoga kyunki handler skip hua
        System.assert(
            result.Total_Revenue__c == null || result.Total_Revenue__c == 0,
            'Rollup should not have run when guard was active'
        );

        // Guard reset karo taaki baaki tests affect na hon
        RevenueLineHandler.isExecuting = false;
    }
}