/**
 * An Apex Class which tests the ShippingCartCalculatorSample
 */
@IsTest
global with sharing class ShippingCartCalculatorSampleTest {

    @IsTest
    static void testCartWithNoCartDeliveryGroup() {
        // Arrange
        CartExtension.Cart cart = CartExtension.CartTestUtil.createCart();
        CartExtension.CartDeliveryGroupCollection deliveryGroups = cart.getCartDeliveryGroups();
        CartExtension.CartDeliveryGroup deliveryGroup = deliveryGroups.get(0);
        deliveryGroups.remove(deliveryGroup);

        // Act
        Test.startTest();
        CartExtension.CartCalculateCalculatorRequest request = new CartExtension.CartCalculateCalculatorRequest(cart);
        ShippingCartCalculatorSample calculator = new ShippingCartCalculatorSample();
        calculator.calculate(request);
        Test.stopTest();

        // Assert
        CartExtension.CartValidationOutputCollection cartValidationOutputs = cart.getCartValidationOutputs();
        System.assertEquals(1, cartValidationOutputs.size());
        CartExtension.CartValidationOutput cvo = cartValidationOutputs.get(0);
        System.assertEquals(CartExtension.CartValidationOutputTypeEnum.SHIPPING, cvo.getType());
        System.assertEquals('No Cart Delivery Groups have been defined', cvo.getMessage());
    }

    @IsTest
    static void testShippingMethodsAreCreated() {
        // Arrange
        CartExtension.Cart cart = CartExtension.CartTestUtil.createCart();

        // Act
        Test.startTest();
        CartExtension.CartCalculateCalculatorRequest request = new CartExtension.CartCalculateCalculatorRequest(cart);
        ShippingCartCalculatorSample calculator = new ShippingCartCalculatorSample();
        calculator.calculate(request);
        Test.stopTest();

        // Assert
        // Test if no CVO is created
        CartExtension.CartValidationOutputCollection cartValidationOutputs = cart.getCartValidationOutputs();
        System.assertEquals(0, cartValidationOutputs.size());

        // Test if CartDeliveryGroupMethod is created
        CartExtension.CartDeliveryGroupCollection deliveryGroups = cart.getCartDeliveryGroups();
        CartExtension.CartDeliveryGroup deliveryGroup = deliveryGroups.get(0);

        CartExtension.CartDeliveryGroupMethodCollection deliveryMethodCollection = deliveryGroup.getCartDeliveryGroupMethods();
        System.assertEquals(1, deliveryMethodCollection.size());
        CartExtension.CartDeliveryGroupMethod deliveryMethod = deliveryMethodCollection.get(0);
        System.assertEquals(11.99, deliveryMethod.getShippingFee());
        System.assertEquals('Delivery Method 1', deliveryMethod.getName());
        System.assertEquals('SNC9600', deliveryMethod.getExternalProvider());
    }
}