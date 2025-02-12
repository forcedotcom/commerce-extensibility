@IsTest
global class GiftcardAdapterUnitTest{

    /**
     * @description Verify that SplitShipmentService invoked the default implementation.
     */
    @IsTest
    public static void applyGiftCard(){
        CartExtension.ApplyGiftCardRequest applyRequest = new CartExtension.ApplyGiftCardRequest('123456789', '1234', 50,'USD');
        GiftCardAdapterSample adapter = new GiftCardAdapterSample();

        // Act
        Test.startTest();
        CartExtension.ApplyGiftCardResponse applyResponse = adapter.applyGiftCard(applyRequest);
        Test.stopTest();


        // Assert
        System.assertEquals(applyResponse.getGiftCardReference, '123456789')
        System.assertEquals(applyResponse.getStatus(), 'Success');
        System.assertEquals(applyResponse.getAppliedAmount(), 50);
        System.assertEquals(applyResponse.getErrorMessage(), null);
    }

    @IsTest
    public static void applyGiftCardWithThirdPartyServiceSuccess(){
        CartExtension.ApplyGiftCardRequest applyRequest = new CartExtension.ApplyGiftCardRequest('111111111', '1234', 50,'USD');
        GiftCardAdapter adapter = new GiftCardAdapter();

        adapter.shouldUseHttpService(true);

        // Set mock callout class
        System.Test.setMock(HttpCalloutMock.class, new GiftCardMockHttpResponseSuccess());
        // Act
        Test.startTest();
        CartExtension.ApplyGiftCardResponse applyResponse = adapter.applyGiftCard(applyRequest);
        Test.stopTest();

        System.assertEquals(applyResponse.getGiftCardReference(), '111111111');
        System.assertEquals(applyResponse.getStatus(), 'Success');
        System.assertEquals(applyResponse.getAppliedAmount(), 20);
        System.assertEquals(applyResponse.getLastFour(), '1111');


    }

    @IsTest
    public static void applyGiftCardWithThirdPartyServiceFail(){
        CartExtension.ApplyGiftCardRequest applyRequest = new CartExtension.ApplyGiftCardRequest('111111111', '1234', 50,'USD');
        GiftCardAdapter adapter = new GiftCardAdapter();

        adapter.shouldUseHttpService(true);

        // Set mock callout class
        System.Test.setMock(HttpCalloutMock.class, new GiftCardMockHttpResponseFail());
        // Act
        Test.startTest();
        CartExtension.ApplyGiftCardResponse applyResponse = adapter.applyGiftCard(applyRequest);
        Test.stopTest();

        System.assertEquals(applyResponse.getStatus(), 'Fail');
    }

    @IsTest
    public static void applyGiftCardWithDefaultImplementation(){
        CartExtension.ApplyGiftCardRequest applyRequest = new CartExtension.ApplyGiftCardRequest('987654321', '1234', 50,'USD');
        GiftCardAdapterDefault defaultAdapter = new GiftCardAdapterDefault();
        try{
            // Act
            Test.startTest();
            defaultAdapter.applyGiftCard(applyRequest);
            Test.stopTest();

            // If an exception was not thrown, fail the test
            System.assert(false, 'Expected exception was not thrown');
        }catch(CalloutException e){
            // Assert that the exception was thrown
            System.assert(e.getMessage().contains('Native gift card is not supported'));
        }
    }
}