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
        CartExtension.CartCalculationRequest request = new CartExtension.CartCalculationRequest(cart);
        ShippingCartCalculatorSample calculator = new ShippingCartCalculatorSample();
        calculator.calculate(request);
        Test.stopTest();

        // Assert
        CartExtension.CartValidationOutputCollection cartValidationOutputs = cart.getCartValidationOutputs();
        System.assertEquals(1, cartValidationOutputs.size());
        CartExtension.CartValidationOutput cvo =  cartValidationOutputs.get(0);
        System.assertEquals(CartExtension.CartValidationOutputTypeEnum.SHIPPING, cvo.getType());
        System.assertEquals('No Cart Delivery Groups have been defined', cvo.getMessage());
    }

     @IsTest
    static void testUnSuccesfulCalloutToExternalRateServiceWith4XXStatus() {
        // Arrange
        CartExtension.Cart cart = CartExtension.CartTestUtil.createCart();
        // Because test methods don't support Web service callouts, we create a mock response based on a static resource.
        // To create the static resource from the Developer Console, select File > New > Static Resource
        // The response should look like
        // [{"status":"calculated","rate":{"name":"Delivery Method 1","serviceName":"Test Carrier 1","serviceCode":"SNC9600","shipmentCost":11.99,"otherCost":5.99}},
        // {"status":"calculated","rate":{"name":"Delivery Method 2","serviceName":"Test Carrier 2","serviceCode":"SNC9600","shipmentCost":15.99,"otherCost":6.99}}]
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('EmptyJson');
        mock.setStatusCode(404);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');

        // Act
        Test.startTest();
        // Associate the callout with a mock response.
        Test.setMock(HttpCalloutMock.class, mock);
        CartExtension.CartCalculationRequest request = new CartExtension.CartCalculationRequest(cart);
        ShippingCartCalculatorSample calculator = new ShippingCartCalculatorSample();
        calculator.calculate(request);
        Test.stopTest();

        // Assert
        // Test if a CVO is created
        CartExtension.CartValidationOutputCollection cartValidationOutputs = cart.getCartValidationOutputs();
        System.assertEquals(1, cartValidationOutputs.size());
        CartExtension.CartValidationOutput cvo =  cartValidationOutputs.get(0);
        System.assertEquals(CartExtension.CartValidationOutputTypeEnum.SHIPPING, cvo.getType());
        System.assertEquals('We failed to calculate shipping options for your cart.', cvo.getMessage());
    }

     @IsTest
    static void testUnSuccesfulCalloutToExternalRateServiceWith5XXStatus() {
        // Arrange
        CartExtension.Cart cart = CartExtension.CartTestUtil.createCart();
        // Because test methods don't support Web service callouts, we create a mock response based on a static resource.
        // To create the static resource from the Developer Console, select File > New > Static Resource
        // The response should look like
        // [{"status":"calculated","rate":{"name":"Delivery Method 1","serviceName":"Test Carrier 1","serviceCode":"SNC9600","shipmentCost":11.99,"otherCost":5.99}},
        // {"status":"calculated","rate":{"name":"Delivery Method 2","serviceName":"Test Carrier 2","serviceCode":"SNC9600","shipmentCost":15.99,"otherCost":6.99}}]
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('EmptyJson');
        mock.setStatusCode(500);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');

        // Act
        Test.startTest();
        // Associate the callout with a mock response.
        Test.setMock(HttpCalloutMock.class, mock);
        CartExtension.CartCalculationRequest request = new CartExtension.CartCalculationRequest(cart);
        ShippingCartCalculatorSample calculator = new ShippingCartCalculatorSample();
        calculator.calculate(request);
        Test.stopTest();

        // Assert
        // Test if a CVO is created
        CartExtension.CartValidationOutputCollection cartValidationOutputs = cart.getCartValidationOutputs();
        System.assertEquals(1, cartValidationOutputs.size());
        CartExtension.CartValidationOutput cvo =  cartValidationOutputs.get(0);
        System.assertEquals(CartExtension.CartValidationOutputTypeEnum.SHIPPING, cvo.getType());
        System.assertEquals('We failed to calculate shipping options for your cart.', cvo.getMessage());
    }

     @IsTest
    static void testSuccesfulCalloutToExternalRateServiceWithNoOrderDeliveryMethod() {
        // Arrange
        CartExtension.Cart cart = CartExtension.CartTestUtil.createCart();
        // Because test methods don't support Web service callouts, we create a mock response based on a static resource.
        // To create the static resource from the Developer Console, select File > New > Static Resource
        // The response should look like
        // [{"status":"calculated","rate":{"name":"Delivery Method 1","serviceName":"Test Carrier 1","serviceCode":"SNC9600","shipmentCost":11.99,"otherCost":5.99}},
        // {"status":"calculated","rate":{"name":"Delivery Method 2","serviceName":"Test Carrier 2","serviceCode":"SNC9600","shipmentCost":15.99,"otherCost":6.99}}]
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('GetDeliveryRatesResource');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');

        // Act
        Test.startTest();
        // Associate the callout with a mock response.
        Test.setMock(HttpCalloutMock.class, mock);
        CartExtension.CartCalculationRequest request = new CartExtension.CartCalculationRequest(cart);
        ShippingCartCalculatorSample calculator = new ShippingCartCalculatorSample();
        calculator.calculate(request);
        Test.stopTest();

        // Assert
        // Test if a CVO is created
        CartExtension.CartValidationOutputCollection cartValidationOutputs = cart.getCartValidationOutputs();
        System.assertEquals(1, cartValidationOutputs.size());
        CartExtension.CartValidationOutput cvo =  cartValidationOutputs.get(0);
        System.assertEquals(CartExtension.CartValidationOutputTypeEnum.SHIPPING, cvo.getType());
        System.assertEquals('There was an issue calculating shipping options for your cart. Please contact your admin.', cvo.getMessage());
    }

     @IsTest
   static void testShippingMethodsAreCreated() {
     // Arrange
     // Create Product
     Product2 shippingChargeProduct = new Product2(
                  isActive = true,
                  Name = 'Shipping Charge for this delivery method'
      );
      insert(shippingChargeProduct);
      Id product2IdForThisDeliveryMethod = shippingChargeProduct.Id;

     // Create OrderDeliveryMethod
     OrderDeliveryMethod defaultOrderDeliveryMethod = new OrderDeliveryMethod(
                     Name = 'Delivery Method 1',
                     Carrier = 'Test Carrier 1',
                     isActive = true,
                     ProductId = product2IdForThisDeliveryMethod,
                     ClassOfService = 'SNC9600'
      );
      insert(defaultOrderDeliveryMethod);
      CartExtension.Cart cart = CartExtension.CartTestUtil.createCart();
       // Because test methods don't support Web service callouts, we create a mock response based on a static resource.
       // To create the static resource from the Developer Console, select File > New > Static Resource
       StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
       mock.setStaticResource('GetDeliveryRatesResource');
       mock.setStatusCode(200);
       mock.setHeader('Content-Type', 'application/json;charset=UTF-8');

       // Act
        Test.startTest();
       // Associate the callout with a mock response.
       Test.setMock(HttpCalloutMock.class, mock);
       CartExtension.CartCalculationRequest request = new CartExtension.CartCalculationRequest(cart);
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
