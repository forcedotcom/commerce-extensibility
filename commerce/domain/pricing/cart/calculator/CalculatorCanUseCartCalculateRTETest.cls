/**
 * @description A sample unit test for PricingCalculatorThrowsCartCalculateRTE.
 */
@IsTest
global class CalculatorCanUseCartCalculateRTETest {

    @IsTest
    public static void testCalculatorCanThrowCartCalculateRTE() {
        // Arrange
        CartExtension.Cart cart = CartExtension.CartTestUtil.createCart();
        PricingCalculatorThrowsCartCalculateRTE calculator = new PricingCalculatorThrowsCartCalculateRTE();
        CartExtension.OptionalBuyerActionDetails optionalBuyerActionDetails =
                CartExtension.OptionalBuyerActionDetails.empty();
        CartExtension.CartCalculateCalculatorRequest request =
                new CartExtension.CartCalculateCalculatorRequest(cart, optionalBuyerActionDetails);

        String expectedExceptionMsg = 'Runtime exception from custom Apex Calculator';

        try {
            // Act
            Test.startTest();
            calculator.calculate(request);
            Test.stopTest();

            // Assert
            Assert.fail('No exception was thrown, when CartExtension.CartCalculateRuntimeException was expected');
        } catch (CartExtension.CartCalculateRuntimeException e) {
            Assert.areEqual(expectedExceptionMsg, e.getMessage());
        } catch (Exception e) {
            Assert.fail('Some other Exception was thrown, when CartExtension.CartCalculateRuntimeException was expected');
        }
    }
}