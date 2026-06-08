@IsTest  // Test class of 9th question 
private class AccountContactSyncHandlerTest{
    @IsTest
    static void testBulk250Accounts(){
        List<Account> AccountList = new List<Account>();
        for(Integer i = 1; i<=250; i++){
            AccountList.add(new Account(
                Name='Test Account'+i,
                Industry='Test Industry'+i
            ));
        }
        insert AccountList;

        // create contacts
        List<Contact> contactList = new List<Contact>();
        for(Account acc : AccountList){
            contactList.add(new Contact(
                LastName = 'Test lastName',
                AccountId = acc.Id
            ));
        } 



        
    // create opportunities for the first 100 accounts

    List<Opportunity> opportunityList = new List<Opportunity>();

    for(Integer i = 1; i<=250; i++){
        opportunityList.add(new Opportunity(
            Name = 'Existing Opportunity'+i,
            AccountId = AccountList[i].Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(
                30
            )
        ));
    }

    insert opportunityList;

    Test.startTest();
    List<Contact> updatedContacts = [
    SELECT Id, Description
    FROM Contact
    WHERE AccountId IN :accountList
];

    System.assertEquals(250, updatedContacts.size());
    Integer autoOppCount = [Select COUNT() from Opportunity Where Name LIKE '%Auto Opp'];
    // if the handler class logic is correct then

    System.assertEquals(150, autoOppCount);     

        // Governor Limit Validation
        System.assert(Limits.getQueries() < 100);
        System.assert(Limits.getDMLStatements() < 150);
    }

    





     
}