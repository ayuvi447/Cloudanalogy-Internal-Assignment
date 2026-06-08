public class RevenueRollupHandler {

    public static Boolean isExecuting = false;

    public static void recalculateOpportunity(Set<Id> oppIds) {

        if (isExecuting || oppIds == null || oppIds.isEmpty()) {
            return;
        }

        isExecuting = true;

        try {

            Map<Id, Decimal> activeRevenueMap = new Map<Id, Decimal>();
            Map<Id, Decimal> cancelledRevenueMap = new Map<Id, Decimal>();
            Map<Id, Date> projectedMonthMap = new Map<Id, Date>();

            List<AggregateResult> results = [
                SELECT
                    Opportunity__c oppId, Stage__c stage, SUM(Amount__c) totalAmount, MAX(Month__c) latestMonth FROM Revenue_Line__c Where Opportunity__c In :oppIds Group By Opportunity__c, Stage__c
            ];

            for (AggregateResult ar : results) {

                Id oppId = (Id) ar.get('oppId');
                String stage = (String) ar.get('stage');
                Decimal amount = (Decimal) ar.get('totalAmount');
                Date latestMonth = (Date) ar.get('latestMonth');

                if (stage == 'Active') {

                    activeRevenueMap.put(oppId, amount);

                    if (latestMonth != null) {
                        projectedMonthMap.put(oppId, latestMonth);
                    }

                } else if (stage == 'Cancelled') {

                    cancelledRevenueMap.put(oppId, amount);
                }
            }

            List<Opportunity> oppsToUpdate = new List<Opportunity>();

            for (Opportunity opp : [
                SELECT Id,Total_Revenue__c,Cancelled_Revenue__c, Projected_Close_Month__c From Opportunity Where Id IN :oppIds
            ]) {

                opp.Total_Revenue__c =
                    activeRevenueMap.containsKey(opp.Id)
                    ? activeRevenueMap.get(opp.Id)
                    : 0;

                opp.Cancelled_Revenue__c =
                    cancelledRevenueMap.containsKey(opp.Id)
                    ? cancelledRevenueMap.get(opp.Id)
                    : 0;

                opp.Projected_Close_Month__c =
                    projectedMonthMap.containsKey(opp.Id)
                    ? projectedMonthMap.get(opp.Id)
                    : null;

                oppsToUpdate.add(opp);
            }

            if (!oppsToUpdate.isEmpty()) {
                System.debug('Executed class');
                update oppsToUpdate;
            }

        } catch (Exception e) {

            System.debug('Revenue Rollup Error: ' + e.getMessage());
            System.debug('Revenue Rollup Stack: ' + e.getStackTraceString());

        } finally {

            isExecuting = false;
        }
    }
}