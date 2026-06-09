public with sharing class Docusign {

    // Get DocuSign Account Details
    public static void getAccountDetails() {

        HttpRequest req = new HttpRequest();
        req.setEndpoint(
            'callout:Docusign_Integration/v2.1/accounts/eb74dedd-0f91-44dd-8705-9b1acf288100'
        );
        req.setMethod('GET');

        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug('Status: ' + res.getStatusCode());
        System.debug('Body: ' + res.getBody());
    }

    // Send Envelope
    public static void sendEnvelope() {

        String body = JSON.serialize(
            new Map<String, Object>{
                'emailSubject' => 'Salesforce Test Envelope Test 2',
                'documents' => new List<Object>{
                    new Map<String, Object>{
                        'documentBase64' => EncodingUtil.base64Encode(
                            Blob.valueOf(
                                'Hello from Salesforce Vicky, this is second file'
                            )
                        ),
                        'name' => 'test.txt',
                        'fileExtension' => 'txt',
                        'documentId' => '1'
                    }
                },
                'recipients' => new Map<String, Object>{
                    'signers' => new List<Object>{
                        new Map<String, Object>{
                            'email' => 'vickytech080@gmail.com',
                            'name' => 'Vicky',
                            'recipientId' => '1'
                        }
                    }
                },
                'status' => 'sent'
            }
        );

        HttpRequest req = new HttpRequest();
        req.setEndpoint(
            'callout:Docusign_Integration/v2.1/accounts/eb74dedd-0f91-44dd-8705-9b1acf288100/envelopes'
        );
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(body);

        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug('Status: ' + res.getStatusCode());
        System.debug('Response: ' + res.getBody());
    }

    // Execute from Anonymous Window:

// Verify account access
//Docusign.getAccountDetails();

// Send envelope
//Docusign.sendEnvelope(); 
}





