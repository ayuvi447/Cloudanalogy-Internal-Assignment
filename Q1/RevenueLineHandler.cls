public class RevenueLineHandler {

    // Prevent recursive execution in the same transaction
    public static Boolean isExecuting = false;

    public static void rollupToOpportunity(Set<Id> opportunityIds) {

        isExecuting = true;

        try {

            // Aggregate revenue data grouped by Opportunity and Stage
            List<AggregateResult> aggregateResults = [select Opportunity__c oppId, Stage__c stage, sum(Amount__c) totalAmount, max(Month__c) latestMonth from Revenue_Line__c where Opportunity__c in :opportunityIds group by Opportunity__c, Stage__c];

            // Prepare Opportunity records for update
            Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();

            for (Id opportunityId : opportunityIds) {
                opportunityMap.put(
                    opportunityId,
                    new Opportunity(
                        Id = opportunityId,
                        Total_Revenue__c = 0,
                        Cancelled_Revenue__c = 0,
                        Projected_Close_Month__c = null
                    )
                );
            }

            // Process aggregate results
            for (AggregateResult result : aggregateResults) {

                Id opportunityId = (Id) result.get('oppId');
                String stage = (String) result.get('stage');
                Decimal totalAmount = (Decimal) result.get('totalAmount');
                Date latestMonth = (Date) result.get('latestMonth');

                Opportunity opportunityRecord = opportunityMap.get(opportunityId);

                if (stage == 'Active') {

                    opportunityRecord.Total_Revenue__c =
                        totalAmount != null ? totalAmount : 0;

                    if (latestMonth != null &&
                        (opportunityRecord.Projected_Close_Month__c == null ||
                         latestMonth > opportunityRecord.Projected_Close_Month__c)) {

                        opportunityRecord.Projected_Close_Month__c = latestMonth;
                    }

                } else if (stage == 'Cancelled') {

                    opportunityRecord.Cancelled_Revenue__c =
                        totalAmount != null ? totalAmount : 0;
                }
            }

            // Update all affected Opportunities
            if (!opportunityMap.isEmpty()) {
                update opportunityMap.values();
            }

        } finally {

            // Always release recursion guard
            isExecuting = false;
        }
    }
}