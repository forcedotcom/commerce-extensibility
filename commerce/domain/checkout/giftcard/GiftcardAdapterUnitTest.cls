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