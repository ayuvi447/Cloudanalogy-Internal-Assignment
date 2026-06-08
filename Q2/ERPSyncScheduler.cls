public class ERPSyncScheduler implements Schedulable {
    
    public void execute(SchedulableContext context) {
        List<Account> pendingAccounts = [
            Select Id FROM Account Where Sync_Status__c = 'Pending' LIMIT 50000];
    
        if (pendingAccounts.isEmpty()) {
            return; // Kuch nahi karna
        }
        // Sirf Ids ki list
        List<Id> accountIds = new List<Id>();
        for (Account acc : pendingAccounts) {
            accountIds.add(acc.Id);
        }
        // Pehla Queueable job enqueue
        System.enqueueJob(new ERPSyncQueueable(accountIds, 0));
    }
}