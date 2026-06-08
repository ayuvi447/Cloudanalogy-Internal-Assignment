public with sharing class AccountContactSyncHandler {

    public static void processAccounts(
        List<Account> accounts
    ) {

        Set<Id> accountIds = new Set<Id>();

        List<Account> accountsToUpdate =
            new List<Account>();

        for(Account acc : accounts){

            accountIds.add(acc.Id);

            if(acc.Rating == null){
                accountsToUpdate.add(
                    new Account(
                        Id = acc.Id,
                        Rating = 'Cold'
                    )
                );
            }
        }

        Map<Id,List<Contact>> accountContacts =
            new Map<Id,List<Contact>>();

        for(Contact c : [
            SELECT Id,
                   AccountId,
                   Description
            FROM Contact
            WHERE AccountId IN :accountIds
        ]){
            if(!accountContacts.containsKey(c.AccountId)){
                accountContacts.put(
                    c.AccountId,
                    new List<Contact>()
                );
            }

            accountContacts.get(
                c.AccountId
            ).add(c);
        }

        List<Contact> contactsToUpdate =
            new List<Contact>();

        for(Account acc : accounts){

            if(accountContacts.containsKey(acc.Id)){

                for(Contact c :
                    accountContacts.get(acc.Id)){

                    c.Description =
                        acc.Industry;

                    contactsToUpdate.add(c);
                }
            }
        }

        Set<Id> accountsWithOpenOpps =
            new Set<Id>();

        for(Opportunity opp : [
            SELECT Id,
                   AccountId
            FROM Opportunity
            WHERE AccountId IN :accountIds
            AND StageName != 'Closed Won'
        ]){
            accountsWithOpenOpps.add(
                opp.AccountId
            );
        }

        List<Opportunity> oppsToInsert =
            new List<Opportunity>();

        for(Account acc : accounts){

            if(accountsWithOpenOpps.contains(acc.Id)){

                oppsToInsert.add(
                    new Opportunity(
                        AccountId = acc.Id,
                        Name = acc.Name +
                               ' - Auto Opp',
                        StageName = 'Prospecting',
                        CloseDate =
                            Date.today()
                            .addDays(30)
                    )
                );
            }
        }

        if(!contactsToUpdate.isEmpty()){
            update contactsToUpdate;
        }

        if(!oppsToInsert.isEmpty()){
            insert oppsToInsert;
        }

        if(!accountsToUpdate.isEmpty()){
            update accountsToUpdate;
        }
    }
}