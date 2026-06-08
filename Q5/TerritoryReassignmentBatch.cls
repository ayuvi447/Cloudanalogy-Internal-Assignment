public class TerritoryReassignmentBatch implements Database.Batchable<SObject>, Database.Stateful {

    private List<Territory_Rule__c> rules;
    private Integer totalProcessed = 0;
    private Integer totalChanged = 0;
    private Map<String, Integer> changedByOldTerritory = new Map<String, Integer>();

    public Database.QueryLocator start(Database.BatchableContext bc) {

        rules = [select Id, Postcode_Prefix__c, Territory__c, Priority__c from Territory_Rule__c order by Priority__c asc];

        return Database.getQueryLocator([
            select Id, Postcode__c, Sales_Territory__c
            from Contact
            where Postcode__c != null
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {

        List<Contact> contacts = (List<Contact>)scope;
        List<Contact> toUpdate = new List<Contact>();

        for (Contact con : contacts) {
            totalProcessed++;

            Id matchedTerritoryId = findBestMatch(con.Postcode__c);

            if (matchedTerritoryId != null && matchedTerritoryId != con.Sales_Territory__c) {

                String oldTerr = con.Sales_Territory__c != null
                    ? con.Sales_Territory__c
                    : 'Unassigned';

                Integer existing = changedByOldTerritory.containsKey(oldTerr)
                    ? changedByOldTerritory.get(oldTerr)
                    : 0;

                changedByOldTerritory.put(oldTerr, existing + 1);

                con.Sales_Territory__c = matchedTerritoryId;
                toUpdate.add(con);
                totalChanged++;
            }
        }

        if (!toUpdate.isEmpty()) {
            Database.update(toUpdate, false);
        }
    }

    public void finish(Database.BatchableContext bc) {

        String details = 'Territory Change Breakdown:\n';

        for (String terrId : changedByOldTerritory.keySet()) {
            details += '• ' + terrId + ' → ' + changedByOldTerritory.get(terrId) + ' changed\n';
        }

        Batch_Summary__c summary = new Batch_Summary__c(
            Total_Processed__c = totalProcessed,
            Total_Changed__c = totalChanged,
            Details__c = details,
            Run_Date__c = DateTime.now()
        );

        insert summary;
    }

    private Id findBestMatch(String postcode) {

        if (String.isBlank(postcode)) {
            return null;
        }

        String upperPostcode = postcode.toUpperCase().trim();
        Id bestTerritoryId = null;
        Integer bestPrefixLength = -1;

        for (Territory_Rule__c rule : rules) {

            if (String.isBlank(rule.Postcode_Prefix__c)) {
                continue;
            }

            String prefix = rule.Postcode_Prefix__c.toUpperCase().trim();

            if (upperPostcode.startsWith(prefix)) {

                if (prefix.length() > bestPrefixLength) {
                    bestPrefixLength = prefix.length();
                    bestTerritoryId = rule.Territory__c;
                }
            }
        }

        return bestTerritoryId;
    }
}