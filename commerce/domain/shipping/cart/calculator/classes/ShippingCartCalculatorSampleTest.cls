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
        CartExtension.CartCalculateCalculatorRequest request = new CartExtension.CartCalculateCalculatorRequest(cart, CartExtension.OptionalBuyerActionDetails.empty());
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
		getDefaultShippingChargeProduct2Id();

        // Act
        Test.startTest();
        CartExtension.CartCalculateCalculatorRequest request = new CartExtension.CartCalculateCalculatorRequest(cart, CartExtension.OptionalBuyerActionDetails.empty());
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
        CartExtension.CartDeliveryGroupMethod deliveryMethod01 = deliveryMethods.get(0);
        System.assertEquals(10.99, deliveryMethod01.getShippingFee());
        System.assertEquals('Ground Shipping', deliveryMethod01.getName());
        System.assertEquals('USPS', deliveryMethod01.getCarrier());
        System.assertEquals('Ground Shipping', deliveryMethod01.getClassOfService());
        System.assertEquals(1, deliveryMethod01.getTransitTimeMin());
        System.assertEquals(3, deliveryMethod01.getTransitTimeMax());
        System.assertEquals('D', deliveryMethod01.getTransitTimeUnit());
        System.assertEquals(1, deliveryMethod01.getProcessTime());
        System.assertEquals('W', deliveryMethod01.getProcessTimeUnit());
        CartExtension.CartDeliveryGroupMethod deliveryMethod02 = deliveryMethods.get(1);
        System.assertEquals(15.99, deliveryMethod02.getShippingFee());
        System.assertEquals('Next Day Air', deliveryMethod02.getName());
        System.assertEquals('UPS', deliveryMethod02.getCarrier());
        System.assertEquals('Next Day Air', deliveryMethod02.getClassOfService());
        System.assertEquals(1, deliveryMethod02.getTransitTimeMin());
        System.assertEquals(4, deliveryMethod02.getTransitTimeMax());
        System.assertEquals('D', deliveryMethod02.getTransitTimeUnit());
        System.assertEquals(1, deliveryMethod02.getProcessTime());
        System.assertEquals('D', deliveryMethod02.getProcessTimeUnit());
    }
    private Id getDefaultShippingChargeProduct2Id() {
            // In this example we will name the product representing shipping charges 'Shipping Charge'.
            // Check to see if a Product2 with that name already exists.
            // If it doesn't exist, create one.
            String shippingChargeProduct2Name = 'Shipping Charge';
            List<Product2> shippingChargeProducts = [SELECT Id FROM Product2 WHERE Name = :shippingChargeProduct2Name];
            if (shippingChargeProducts.isEmpty()) {
                Product2 shippingChargeProduct = new Product2(
                    isActive = true,
                    Name = shippingChargeProduct2Name
                );
                insert(shippingChargeProduct);
                return shippingChargeProduct.Id;
            } else {
                return shippingChargeProducts[0].Id;
            }
        }
}
