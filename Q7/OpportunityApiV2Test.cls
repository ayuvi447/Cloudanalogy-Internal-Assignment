@isTest
public class OpportunityApiV2Test {
    @TestSetup
    static void createTestData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
       
        Opportunity opp = new Opportunity();
        opp.Name      = 'Test Opportunity';
        opp.AccountId = acc.Id;
        opp.StageName = 'Prospecting';
        opp.CloseDate = Date.today().addDays(30);
        insert opp;
    }
@IsTest
    static void testV2GetWorks() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        RestRequest req  = new RestRequest();
        req.requestURI   = '/services/apexrest/v2/opportunities/' + opp.Id;
        req.httpMethod   = 'GET';

        RestResponse res = new RestResponse();

        RestContext.request  = req;
        RestContext.response = res;

        Test.startTest();
        OpportunityApiV2.doGet();
        Test.stopTest();

    }
    @IsTest
    static void testV2GetWorksForElse() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        RestRequest req  = new RestRequest();
        req.requestURI   = '/services/apexrest/v2/opportunities/';
        req.httpMethod   = 'GET';

        RestResponse res = new RestResponse();

        RestContext.request  = req;
        RestContext.response = res;

        Test.startTest();
        OpportunityApiV2.doGet();
        Test.stopTest();

    }
}
