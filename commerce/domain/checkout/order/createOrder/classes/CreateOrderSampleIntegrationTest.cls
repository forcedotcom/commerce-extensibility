/*
 * @description Example of "integration" test for CreateOrder extension point. This test is calling real default implementation of CreateOrder Extension.
 * Please be aware that this test might fail in some orgs in case when default implementation suppose to call other services that are not properly set up / stubbed for the test.
 */
@isTest
public class CreateOrderSampleIntegrationTest {
    @isTest
    public static void shouldRoundUpCostOfProduct() {
        CartExtension.Cart cart = arrangeCart(new Decimal[]{1.5});
        CreateOrderSample createOrder = new CreateOrderSample();
        // Act
        Test.startTest();
        CartExtension.CreateOrderResponse response = createOrder.createOrder(new CartExtension.CreateOrderRequest(cart, '123'));
        Test.stopTest();
        // Assert
        Order order = response.getOrderGraph().getOrder();
        Assert.areEqual('Total rounded up cost of products: 2.0', order.Description);
    }

    @isTest
    public static void shouldRoundUpCostOfSeveralProducts() {
        CartExtension.Cart cart = arrangeCart(new Decimal[]{1.5, 2.6});
        CreateOrderSample createOrder = new CreateOrderSample();
        // Act
        Test.startTest();
        CartExtension.CreateOrderResponse response = createOrder.createOrder(new CartExtension.CreateOrderRequest(cart, '123'));
        Test.stopTest();
        // Assert
        Order order = response.getOrderGraph().getOrder();
        Assert.areEqual('Total rounded up cost of products: ' + (2.0 + 3.0), order.Description);
    }

        private static CartExtension.Cart arrangeCart(Decimal[] itemsSalePrice) {
        Account testAccount = new Account(Name='My Account');
        insert testAccount;

        WebStore testWebStore = new WebStore(Name='My WebStore');
        insert testWebStore;

        WebCart testCart = new WebCart(Name='My Cart', WebStoreId=testWebStore.Id, AccountId=testAccount.Id);
        insert testCart;

        CartDeliveryGroup testDeliveryGroup = new CartDeliveryGroup(Name='My Delivery Group', CartId=testCart.Id);
        insert testDeliveryGroup;

        Product2 testShippingChargeProduct = new Product2(Name = 'Test Shipping Charge', IsActive = true);
        insert testShippingChargeProduct;

        CartDeliveryGroupMethod testCartDeliveryGroupMethod = new CartDeliveryGroupMethod(Carrier = 'My Carrier', ClassOfService = 'My Class of Service',
                CartDeliveryGroupId = testDeliveryGroup.Id, WebCartId=testCart.Id, ProductId = testShippingChargeProduct.Id,
                Name = 'Test Name', ShippingFee = 1.2);
        insert testCartDeliveryGroupMethod;

        testDeliveryGroup.SelectedDeliveryMethodId = testCartDeliveryGroupMethod.Id;
        update testDeliveryGroup;

        for (Decimal salesPrice : itemsSalePrice) {
            CartItem testCartItem = new CartItem(Name='My Cart Item', SalesPrice = salesPrice, CartId=testCart.Id, CartDeliveryGroupId=testDeliveryGroup.Id);
            insert testCartItem;
        }

        WebCartAdjustmentBasis testCartAdjustmentBasis = new WebCartAdjustmentBasis(Name='My Coupon', WebCartId=testCart.Id);
        insert testCartAdjustmentBasis;

        return CartExtension.CartTestUtil.getCart(testCart.Id);
    }

}