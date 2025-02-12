@isTest
global class GiftCardMockHttpResponseSuccess implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        System.assertEquals('https://example.com/apply-gift-card', req.getEndpoint());
        System.assertEquals('POST', req.getMethod());

        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"giftCardReference":"111111111","availableAmount":20}');
        res.setStatusCode(200);
        return res;
    }
}