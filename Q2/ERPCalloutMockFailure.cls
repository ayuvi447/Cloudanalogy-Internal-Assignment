@isTest
global class ERPCalloutMockFailure
implements HttpCalloutMock {

    global HTTPResponse respond(HTTPRequest req){

        HttpResponse res =
            new HttpResponse();

        res.setStatusCode(500);
        res.setBody('ERP Error');

        return res;
    }
}