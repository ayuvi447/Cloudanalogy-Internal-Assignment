trigger RevenueLineTrigger on Revenue_Line__c (
    after insert,
    after update,
    after delete,
    after undelete
) {

    // Prevent recursive execution
    if (RevenueLineHandler.isExecuting) {
        return;
    }

    // Store all affected Opportunity Ids
    Set<Id> opportunityIds = new Set<Id>();

    // Get records based on trigger context
    List<Revenue_Line__c> revenueLines = Trigger.isDelete
        ? Trigger.old
        : Trigger.new;

    // Collect Opportunity Ids from current records
    for (Revenue_Line__c revenueLine : revenueLines) {
        if (revenueLine.Opportunity__c != null) {
            opportunityIds.add(revenueLine.Opportunity__c);
        }
    }

    // In update scenario, include old Opportunity Ids as well
    // to handle cases where the parent Opportunity changes
    if (Trigger.isUpdate) {
        for (Revenue_Line__c oldRevenueLine : Trigger.old) {
            if (oldRevenueLine.Opportunity__c != null) {
                opportunityIds.add(oldRevenueLine.Opportunity__c);
            }
        }
    }

    // Recalculate rollup values on related Opportunities
    if (!opportunityIds.isEmpty()) {
        RevenueLineHandler.rollupToOpportunity(opportunityIds);
    }
}