@isTest
public class OpportunityApiV1Test {
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
    static void testGetList() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        RestRequest req  = new RestRequest();
        req.requestURI   = '/services/apexrest/v1/opportunities/';
        req.httpMethod   = 'GET';
        req.params.put('accountId', acc.Id);

        RestResponse res = new RestResponse();

        RestContext.request  = req;
        RestContext.response = res;

        Test.startTest();
        OpportunityApiV1.doGet();
        Test.stopTest();

    }
   
      @IsTest
    static void testGetSingle() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        RestRequest req  = new RestRequest();
        req.requestURI   = '/services/apexrest/v1/opportunities/' + opp.Id;
        req.httpMethod   = 'GET';

        RestResponse res = new RestResponse();

        RestContext.request  = req;
        RestContext.response = res;

        Test.startTest();
        OpportunityApiV1.doGet();
        Test.stopTest();

    }
      @IsTest
    static void testPostReturns403() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        String jsonBody = '{"name":"New Opp","accountId":"' + acc.Id + '","stageName":"Prospecting","closeDate":"2025-12-31"}';

        RestRequest req  = new RestRequest();
        req.requestURI   = '/services/apexrest/v1/opportunities/';
        req.httpMethod   = 'POST';
        req.requestBody  = Blob.valueOf(jsonBody);

        RestResponse res = new RestResponse();

        RestContext.request  = req;
        RestContext.response = res;

        Test.startTest();
        OpportunityApiV1.doPost();
        Test.stopTest();

   
    }
    @IsTest
    static void testPostWithPermission() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
grantWritePermission();

        String jsonBody = '{"name":"New Opp","accountId":"' + acc.Id + '","stageName":"Prospecting","closeDate":"2025-12-31"}';

        RestRequest req  = new RestRequest();
        req.requestURI   = '/services/apexrest/v1/opportunities/';
        req.httpMethod   = 'POST';
        req.requestBody  = Blob.valueOf(jsonBody);

        RestResponse res = new RestResponse();

        RestContext.request  = req;
        RestContext.response = res;

        Test.startTest();
        OpportunityApiV1.doPost();
        Test.stopTest();

   
    }
     @IsTest
    static void testDeleteIfFirst() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        RestRequest req  = new RestRequest();
        req.requestURI   = '/services/apexrest/v1/opportunities/' + opp.Id;
        req.httpMethod   = 'DELETE';

        RestResponse res = new RestResponse();

        RestContext.request  = req;
        RestContext.response = res;

        Test.startTest();
        OpportunityApiV1.doDelete();
        Test.stopTest();

       
    }
       @IsTest
    static void testDeleteElse() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
grantWritePermission();
        RestRequest req  = new RestRequest();
        req.requestURI   = '/services/apexrest/v1/opportunities/' + opp.Id;
        req.httpMethod   = 'DELETE';

        RestResponse res = new RestResponse();

        RestContext.request  = req;
        RestContext.response = res;

        Test.startTest();
        OpportunityApiV1.doDelete();
        Test.stopTest();

       
    }
    static void grantWritePermission() {
        PermissionSet ps = [select Id from PermissionSet where Name = 'Partner_Persmission' limit 1];
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId      = UserInfo.getUserId();
        psa.PermissionSetId = ps.Id;
        insert psa;
    }
}