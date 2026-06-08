public class TerritoryReassignmentScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        // Batch size 200 — governor limits safe
        TerritoryReassignmentBatch batch = new TerritoryReassignmentBatch();
        Database.executeBatch(batch, 200);
    }
}