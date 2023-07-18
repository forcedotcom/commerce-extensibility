/**
 * An Apex Class which tests the ShippingCartCalculatorSample
 */
@IsTest
global with sharing class ShippingCartCalculatorSampleTest {

    @IsTest
    static void testCartWithNoCartDeliveryGroup() {
        // Arrange
        CartExtension.Cart cart = CartExtension.CartTestUtil.createCart();
        CartExtension.CartDeliveryGroupList deliveryGroups = cart.getCartDeliveryGroups();
        CartExtension.CartDeliveryGroup deliveryGroup = deliveryGroups.get(0);
        deliveryGroups.remove(deliveryGroup);

        // Act
        Test.startTest();
        CartExtension.CartCalculateCalculatorRequest request = new CartExtension.CartCalculateCalculatorRequest(cart);
        ShippingCartCalculatorSample calculator = new ShippingCartCalculatorSample();
        calculator.calculate(request);
        Test.stopTest();

        // Assert
        CartExtension.CartValidationOutputList cartValidationOutputs = cart.getCartValidationOutputs();
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
        CartExtension.CartValidationOutputList cartValidationOutputs = cart.getCartValidationOutputs();
        System.assertEquals(0, cartValidationOutputs.size());

        // Test if CartDeliveryGroupMethod is created
        CartExtension.CartDeliveryGroupList deliveryGroups = cart.getCartDeliveryGroups();
        CartExtension.CartDeliveryGroup deliveryGroup = deliveryGroups.get(0);

        CartExtension.CartDeliveryGroupMethodList deliveryMethods = deliveryGroup.getCartDeliveryGroupMethods();
        System.assertEquals(2, deliveryMethods.size());
        CartExtension.CartDeliveryGroupMethod deliveryMethod = deliveryMethods.get(0);
        System.assertEquals(10.99, deliveryMethod.getShippingFee());
        System.assertEquals('Ground Shipping', deliveryMethod.getName());
        System.assertEquals('USPS', deliveryMethod.getCarrier());
        System.assertEquals('Ground Shipping', deliveryMethod.getClassOfService());
        CartExtension.CartDeliveryGroupMethod deliveryMethod = deliveryMethods.get(1);
        System.assertEquals(15.99, deliveryMethod.getShippingFee());
        System.assertEquals('Next Day Air', deliveryMethod.getName());
        System.assertEquals('UPS', deliveryMethod.getCarrier());
        System.assertEquals('Next Day Air', deliveryMethod.getClassOfService());
    }
}