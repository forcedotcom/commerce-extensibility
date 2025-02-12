/**
 * @description Custom Gift card adapter. This class will have operations like applyGiftCard(), redeemGiftCard(), refundGiftCard().
 In this sample implementation of applyGiftCard, if the https service is registered , we make a call to that third party service
 with giftCardNumber and pin passed as the input in the request. The response is expected to have appliedAmount
 and giftCardReference. If https service is not registered then we return a hardcoded values.
 */

global class GiftCardAdapter extends CartExtension.GiftCardAdapter{

    private static String httpHost = 'https://example.com';
    private static Boolean useHTTPService = false;

    public virtual override CartExtension.ApplyGiftCardResponse applyGiftCard(CartExtension.ApplyGiftCardRequest applyRequest){

        Double amount = applyRequest.getAmount();
        String giftCardCurrency = applyRequest.getCurrencyIsoCode();
        String giftCardCode = applyRequest.getGiftCardCode();
        String pin = applyRequest.getPin();

        CartExtension.ApplyGiftCardResponse response = null;

        if(useHTTPService) {
           response = applyGiftCardService(giftCardCode, pin, amount, giftCardCurrency);
        } else {
           response = applyGiftCardMockedService(giftCardCode, pin, amount, giftCardCurrency);
        }

        return response;

    }

    private CartExtension.ApplyGiftCardResponse applyGiftCardMockedService(String giftCardCode, String giftCardPin,
                                                Double amount, String giftCardCurrency) {
        CartExtension.ApplyGiftCardResponse applyResponse = new CartExtension.ApplyGiftCardResponse();

        applyResponse.setGiftCardReference('123456789');
        applyResponse.setAppliedAmount(50);
        applyResponse.setLastFour('6789');
        applyResponse.setStatus('Success');

        return applyResponse;


    }

   private CartExtension.ApplyGiftCardResponse applyGiftCardService(String giftCardCode, String giftCardPin, Double amount) {

       final Integer successfulHttpRequest = 200;
       CartExtension.ApplyGiftCardResponse applyResponse;

       Http http = new Http();
       HttpRequest request = new HttpRequest();
       request.setEndpoint(httpHost + '/apply-gift-card');
       request.setMethod('POST');
       HttpResponse response = http.send(request);


       if (response.getStatusCode() == successfulHttpRequest) {
           // Parse JSON response
           String responseBody = response.getBody();
           applyResponse = processSuccessResponseFromService(responseBody, amount);

       }else{
           // Read the error details
           String responseBody = response.getBody();
           applyResponse = processFailedResponseFromService(response);

       }
       return applyResponse;

   }

   private CartExtension.ApplyGiftCardResponse processSuccessResponseFromService(String thirdPartyResponse, Double amount) {
      CartExtension.ApplyGiftCardResponse applyResponse = new CartExtension.ApplyGiftCardResponse();

      // Parse JSON using JSON.deserialize or JSON.deserializeUntyped
      Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(thirdPartyResponse);

      String giftCardReference = (String)resultMap.get('giftCardReference');

      Double availableAmount = (Double)resultMap.get('availableAmount');
      if(availableAmount >= amount){
           applyResponse.setAppliedAmount(amount);
       } else if(availableAmount < amount && availableAmount>0){
           applyResponse.setAppliedAmount(availableAmount);
       } else if(availableAmount == 0){
           applyResponse.setAppliedAmount(0);
           applyResponse.setErrorMessage('Zero balance in gift card');
           applyResponse.setStatus('Fail');
           applyResponse.setGiftCardReference(giftCardReference);
           applyResponse.setLastFour(giftCardReference.substring(giftCardReference.length() - 4));
           return applyResponse;

       }
       applyResponse.setGiftCardReference(giftCardReference);
       applyResponse.setLastFour(giftCardReference.substring(giftCardReference.length() - 4));
       applyResponse.setStatus('Success');

       return applyResponse;
     }

   private CartExtension.ApplyGiftCardResponse processFailedResponseFromService(HttpResponse response) {

       CartExtension.ApplyGiftCardResponse applyResponse = new CartExtension.ApplyGiftCardResponse();

       // Read the error details
       String responseBody = response.getBody();

       System.debug('Error Status Code: ' + response.getStatusCode());
       System.debug('Error Body: ' + responseBody);

       // Optional: Parse error if response is JSON
       if (response.getHeader('Content-Type').contains('application/json')) {
           Map<String, Object> errorMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

           String errorMessage = (String) errorMap.get('message');
           System.debug('Error Message: ' + errorMessage);
           applyResponse.setStatus('Fail');
           applyResponse.setErrorMessage(errorMessage);
       }
       return applyResponse;
   }

   public void shouldUseHttpService(Boolean input){
           useHTTPService = input;
   }

}