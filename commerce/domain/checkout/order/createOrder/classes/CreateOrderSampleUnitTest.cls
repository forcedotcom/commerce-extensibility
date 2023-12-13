/*
 * @description Example of unit test for CreateOrder extension point. This test is mocking out default implementation of CreateOrder Extension so
 * the test is isolated from the dependencies on other services that default implementation might have.
 */
@isTest
public class CreateOrderSampleUnitTest {
    
    @isTest
    public static void shouldRoundUpCostOfProduct() {
        CartExtension.Cart cart = arrangeCart(new Decimal[]{1.5});
        CreateOrderSample createOrder = new CreateOrderSampleMock();
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
        CreateOrderSample createOrder = new CreateOrderSampleMock();
        // Act
        Test.startTest();
        CartExtension.CreateOrderResponse response = createOrder.createOrder(new CartExtension.CreateOrderRequest(cart, '123'));
        Test.stopTest();
        // Assert
        Order order = response.getOrderGraph().getOrder();
        Assert.areEqual('Total rounded up cost of products: ' + (2.0 + 3.0), order.Description);
    }
    
    /*
     * Mock of CreateOrderSample class. It provides simplified implementation of cart to order mapping. 
     */    
    public class CreateOrderSampleMock extends CreateOrderSample {
        
        public override CartExtension.CreateOrderResponse callDefault(CartExtension.CreateOrderRequest request) {
            CartExtension.Cart cart = request.getCart();
            CartExtension.OrderGraph orderGraph = new CartExtension.OrderGraph();
            Order order = orderGraph.getOrder();
            System.assert(order.Id != null);
    
            order.AccountId = cart.getAccountId();
            order.OwnerId = cart.getOwnerId();
            order.SalesStoreId = cart.getWebStoreId();
            // cart does not support PoNumber yet
            //order.PoNumber = cart.getPoNumber();
            Address billingAddress = cart.getBillingAddress();
            if (billingAddress != null) {
                order.BillingStreet = billingAddress.Street;
                order.BillingCity = billingAddress.City;
                order.BillingState = billingAddress.State;
                order.BillingPostalCode = billingAddress.PostalCode;
                order.BillingCountry = billingAddress.Country;
                order.BillingLatitude = billingAddress.Latitude;
                order.BillingLongitude = billingAddress.Longitude;
                order.BillingEmailAddress = cart.getGuestEmailAddress();
                order.BillingPhoneNumber = cart.getGuestPhoneNumber();
                order.TaxLocaleType = cart.getTaxType().name();
                order.EffectiveDate = Date.today();
                order.Status = 'Activated';
                order.Description = 'testEPN';                
            }
    
            CartExtension.CartDeliveryGroupList cdgList = cart.getCartDeliveryGroups();
            for (Integer i = 0; i < cdgList.size(); i++) {
                CartExtension.CartDeliveryGroup cdg = cdgList.get(i);
                // create orderDeliveryGroup
                OrderDeliveryGroup odg = new OrderDeliveryGroup();
                odg.DeliverToName = cdg.getDeliverToName();
                odg.OrderDeliveryMethodId = cdg.getDeliveryMethodId();
                orderGraph.addNode(odg);
    
                // create orderItems
                CartExtension.CartItemList cartItemList = cart.getCartItems();
                for (Integer j = 0; j < cartItemList.size(); j++) {
                    CartExtension.CartItem cartItem = cartItemList.get(j);
                    OrderItem orderItem = new OrderItem();
                    orderItem.Product2Id = cartItem.getProduct2Id();
                    if (CartExtension.SalesItemTypeEnum.PRODUCT.equals(cartItem.getType())) {
                        orderItem.Type = 'Order Product';
                    } else {
                        orderItem.Type = 'Delivery charge';
                    }
                    orderItem.Quantity = cartItem.getQuantity();
                    orderItem.OrderDeliveryGroupId = odg.Id;
                    orderItem.ListPrice = cartItem.getListPrice();
                    orderItem.UnitPrice = cartItem.getNetUnitPrice();
                    if (orderItem.UnitPrice == null) {
                        orderItem.UnitPrice = cartItem.getSalesPrice() == null ? cartItem.getListPrice() : cartItem.getSalesPrice();
                    }
                    if (orderItem.ListPrice == null) {
                        orderItem.ListPrice = cartItem.getSalesPrice();
                    }
    
                    orderItem.GrossUnitPrice = cartItem.getNetUnitPrice();
                    orderItem.TotalLineAmount = cartItem.getTotalLineNetAmount();
                    orderItem.Description = cartItem.getName();
                    orderGraph.addNode(orderItem);
    
                }
            }
    
            CartExtension.CreateOrderResponse response = new CartExtension.CreateOrderResponse(orderGraph);
            return response;
        }

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