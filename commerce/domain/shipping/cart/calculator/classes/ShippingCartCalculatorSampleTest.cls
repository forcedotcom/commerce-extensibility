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
        System.assertEquals('DAYS', deliveryMethod01.getTransitTimeUnit().toString());
        System.assertEquals(1, deliveryMethod01.getProcessTime());
        System.assertEquals('WEEKS', deliveryMethod01.getProcessTimeUnit().toString());

        CartExtension.CartDeliveryGroupMethod deliveryMethod02 = deliveryMethods.get(1);
        System.assertEquals(15.99, deliveryMethod02.getShippingFee());
        System.assertEquals('Next Day Air', deliveryMethod02.getName());
        System.assertEquals('UPS', deliveryMethod02.getCarrier());
        System.assertEquals('Next Day Air', deliveryMethod02.getClassOfService());
        System.assertEquals(1, deliveryMethod02.getTransitTimeMin());
        System.assertEquals(4, deliveryMethod02.getTransitTimeMax());
        System.assertEquals('DAYS', deliveryMethod02.getTransitTimeUnit().toString());
        System.assertEquals(1, deliveryMethod02.getProcessTime());
        System.assertEquals('DAYS', deliveryMethod02.getProcessTimeUnit().toString());
    }
    private static Id getDefaultShippingChargeProduct2Id() {

            // Check to see if a Product2 with name 'Shipping Charge' already exists.
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

    @IsTest
    static void testShippingMethodsAreCreated_retainSelectedDeliveryMethod() {
        // Arrange
        CartExtension.Cart cart = CartExtension.CartTestUtil.createCart();
		getDefaultShippingChargeProduct2Id();

        // Act
        Test.startTest();
        CartExtension.CartCalculateCalculatorRequest request = new CartExtension.CartCalculateCalculatorRequest(cart, CartExtension.OptionalBuyerActionDetails.empty());
        ShippingCartCalculatorSample calculator = new ShippingCartCalculatorSample();
        //calculator.calculate(request);

        // Assert
        // Test if no CVO is created
        CartExtension.CartValidationOutputList cartValidationOutputs = cart.getCartValidationOutputs();
        System.assertEquals(0, cartValidationOutputs.size());

        //find prevSelectDeliveryMethod for first cart DG
        CartExtension.CartDeliveryGroupList deliveryGroups = cart.getCartDeliveryGroups();
        CartExtension.CartDeliveryGroup deliveryGroup1 = deliveryGroups.get(0);
        CartExtension.CartDeliveryGroupMethod prevSelectDeliveryMethod = deliveryGroup1.getSelectedCartDeliveryGroupMethod();

        //find delivery methods
        CartExtension.CartDeliveryGroupMethodList deliveryMethods = deliveryGroup1.getCartDeliveryGroupMethods();

        //identify the delivery method id which is not matching with the selected delivery method id
        CartExtension.CartDeliveryGroupMethod nonMatchingCDGM = null;
        for (Integer j = (deliveryMethods.size() - 1); j >= 0; j--) {
            CartExtension.CartDeliveryGroupMethod cdgm = deliveryMethods.get(j);
           if(prevSelectDeliveryMethod==null || cdgm.getId() != prevSelectDeliveryMethod.getId()) {
               nonMatchingCDGM = cdgm;
               break;
           }
        }
        //udpate cart delivery group with new selected deliver method id which is not matching
        deliveryGroup1.setSelectedCartDeliveryGroupMethod(nonMatchingCDGM);

        // call calculator
        calculator.calculate(request);


        // Test if CartDeliveryGroupMethod is created
        deliveryGroups = cart.getCartDeliveryGroups();

        CartExtension.CartDeliveryGroup deliveryGroup = deliveryGroups.get(0);
        System.assertEquals(2, deliveryMethods.size());
        CartExtension.CartDeliveryGroupMethod deliveryMethod01 = deliveryMethods.get(0);
        System.assertEquals(10.99, deliveryMethod01.getShippingFee());
        System.assertEquals('Ground Shipping', deliveryMethod01.getName());
        System.assertEquals('USPS', deliveryMethod01.getCarrier());
        System.assertEquals('Ground Shipping', deliveryMethod01.getClassOfService());
        System.assertEquals(1, deliveryMethod01.getTransitTimeMin());
        System.assertEquals(3, deliveryMethod01.getTransitTimeMax());
        System.assertEquals('DAYS', deliveryMethod01.getTransitTimeUnit().toString());
        System.assertEquals(1, deliveryMethod01.getProcessTime());
        System.assertEquals('WEEKS', deliveryMethod01.getProcessTimeUnit().toString());

        CartExtension.CartDeliveryGroupMethod deliveryMethod02 = deliveryMethods.get(1);
        System.assertEquals(15.99, deliveryMethod02.getShippingFee());
        System.assertEquals('Next Day Air', deliveryMethod02.getName());
        System.assertEquals('UPS', deliveryMethod02.getCarrier());
        System.assertEquals('Next Day Air', deliveryMethod02.getClassOfService());
        System.assertEquals(1, deliveryMethod02.getTransitTimeMin());
        System.assertEquals(4, deliveryMethod02.getTransitTimeMax());
        System.assertEquals('DAYS', deliveryMethod02.getTransitTimeUnit().toString());
        System.assertEquals(1, deliveryMethod02.getProcessTime());
        System.assertEquals('DAYS', deliveryMethod02.getProcessTimeUnit().toString());
        Test.stopTest();
    }

}
