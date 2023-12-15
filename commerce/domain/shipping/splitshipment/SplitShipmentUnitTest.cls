/**
 * @description Sample unit test for SplitShipmentSample and SplitShipmentCallsSuper.
 */
@IsTest
global class SplitShipmentUnitTest {
    private static final String CART_NAME = 'My Cart';
    private static final String ACCOUNT_NAME = 'My Account';
    private static final String WEBSTORE_NAME = 'My WebStore';
    private static final String DELIVERYGROUP_NAME = 'Default Delivery Group';
    private static final String CART_ITEM1_NAME = 'My Cart Item 1';
    private static final String CART_ITEM2_NAME = 'My Cart Item 2';
    private static final String CART_ITEM3_NAME = 'My Cart Item 3';
    private static final String SKU1_NAME = 'My SKU 1';
    private static final String SKU2_NAME = 'My SKU 2';
    private static final String SKU3_NAME = 'My SKU 3';

    private static final MockDefaultSplitShipmentService mockService = new MockDefaultSplitShipmentService();
    private static final SplitShipmentCallsSuper splitShipmentCallsSuper = new SplitShipmentCallsSuper(mockService);
    private static final SplitShipmentSample splitShipmentSample = new SplitShipmentSample();

    /**
     * @description Verify that SplitShipmentService invoked the default implementation.
     */
    @IsTest
    public static void splitShipmentServiceShouldCallDefaultImplementation() {
        // Arrange
        // Create a Cart
        CartExtension.Cart cart = CartExtension.CartTestUtil.createCart();

        // Create item arrangement request
        CartExtension.ItemArrange itemArrange = createItemArrange(cart.getCartItems().get(0).getId(), null, null);
        List<CartExtension.ItemArrange> itemArrangeList = new List<CartExtension.ItemArrange>();
        itemArrangeList.add(itemArrange);

        CartExtension.ItemArrangementRequest request = new CartExtension.ItemArrangementRequest.Builder()
                .withCart(cart)
                .withItemArrangeList(itemArrangeList)
                .build();

        // Act
        Test.startTest();
        splitShipmentCallsSuper.arrangeItems(request);
        Test.stopTest();

        // Assert
        // Verify that the default implementation was called
        Assert.isTrue(cart.getName().contains('Default Split Shipment Service was invoked'));
    }

    /**
     * @description Verify that SplitShipmentService arranged CartItems by a "Product Conveyability" custom field.
     * The 'IsConveyable__c' custom checkbox field on Product2 signifies if the product can go on the conveyer belt
     * at a warehouse. Items that cannot go on the conveyer belt may be big, bulky, and/or heavy which may require
     * additional packaging and will take longer to get onto a delivery truck.
     */
    @IsTest
    public static void splitShipmentServiceShouldCreateDeliveryGroupBasedOnConveyability() {
        // Arrange
        // Create a Cart with CHECKOUT status
        Id cartId = createCartWithSpecifiedStatus(CartExtension.CartStatusEnum.CHECKOUT);

        // Create a default Cart Delivery Group
        Id defaultCartDeliveryGroupId = createDefaultCartDeliveryGroup(cartId);

        // Associate 3 items to the Cart
        Map<ID, ID> cartItemIdToProductIdMap = addThreeItemsToCart(cartId, defaultCartDeliveryGroupId);

        // Load the Cart
        CartExtension.Cart cart = CartExtension.CartTestUtil.getCart(cartId);

        // Create item arrangement request
        List<CartExtension.ItemArrange> itemArrangeList = new List<CartExtension.ItemArrange>();
        for (ID cartItemId : cartItemIdToProductIdMap.keySet()) {
            itemArrangeList.add(createItemArrange(cartItemId, null, cartItemIdToProductIdMap.get(cartItemId)));
        }

        CartExtension.ItemArrangementRequest request = new CartExtension.ItemArrangementRequest.Builder()
                .withCart(cart)
                .withItemArrangeList(itemArrangeList)
                .build();

        final String expectedNonConveyableCartDeliveryGroupName = 'Non-Conveyable Cart Delivery Group';

        // Act
        Test.startTest();
        splitShipmentSample.arrangeItems(request);
        Test.stopTest();

        // Assert
        // Verify that we have 2 CartDeliveryGroups, since a non-conveyable CartDeliveryGroup should have been created
        Assert.areEqual(2, cart.getCartDeliveryGroups().size());
        Assert.areEqual(DELIVERYGROUP_NAME, cart.getCartDeliveryGroups().get(0).getName());
        Assert.areEqual(expectedNonConveyableCartDeliveryGroupName, cart.getCartDeliveryGroups().get(1).getName());

        // Verify that no new CartItems were created
        Assert.areEqual(3, cart.getCartItems().size());

        // Verify that the first CartItem was moved to the non-conveyable CartDeliveryGroup
        Assert.areEqual(CART_ITEM1_NAME, cart.getCartItems().get(0).getName());
        Assert.areEqual(expectedNonConveyableCartDeliveryGroupName, cart.getCartItems().get(0).getCartDeliveryGroup().getName());

        // Verify that the second CartItem remained in the original, default CartDeliveryGroup
        Assert.areEqual(CART_ITEM2_NAME, cart.getCartItems().get(1).getName());
        Assert.areEqual(DELIVERYGROUP_NAME, cart.getCartItems().get(1).getCartDeliveryGroup().getName());

        // Verify that the third CartItem was also moved to the non-conveyable CartDeliveryGroup
        Assert.areEqual(CART_ITEM3_NAME, cart.getCartItems().get(2).getName());
        Assert.areEqual(expectedNonConveyableCartDeliveryGroupName, cart.getCartItems().get(2).getCartDeliveryGroup().getName());
    }

    /**
     * @description Create a WebCart with the specific status.
     * @param cartStatus Status of the Cart
     *
     * @return ID of the WebCart
     */
    private static ID createCartWithSpecifiedStatus(CartExtension.CartStatusEnum cartStatus) {
        Account account = new Account(Name = ACCOUNT_NAME);
        insert account;

        WebStore webStore = new WebStore(Name = WEBSTORE_NAME);
        insert webStore;

        WebCart webCart = new WebCart(
                Name = CART_NAME,
                WebStoreId = webStore.Id,
                AccountId = account.Id,
                Status = cartStatus.name());
        insert webCart;

        return webCart.Id;
    }

    /**
     * @description Set up the default CartDeliveryGroup and configure it such that it is meant only for conveyable products.
     * @param cartId ID of the WebCart that needs to be associated to the CartDeliveryGroup
     *
     * @return ID The ID of the newly created CartDeliveryGroup
     */
    private static ID createDefaultCartDeliveryGroup(ID cartId) {
        CartDeliveryGroup deliveryGroup = new CartDeliveryGroup(
            Name = DELIVERYGROUP_NAME,
            DeliverToName = 'Rob Gronkowski',
            IsDefault = true,
            CartId = cartId,
            IsConveyable__c = true);
        insert deliveryGroup;

        return deliveryGroup.Id;
    }

    /**
     * @description Add three items to the specified Cart.
     * @param cartId ID of the WebCart for which we need to add three items
     * @param deliveryGroupId ID of the CartDeliveryGroup
     *
     * @return Map CartItemIds that were added, along with their associated ProductId
     */
    private static Map<ID, ID> addThreeItemsToCart(ID cartId, ID deliveryGroupId) {
        // Configure the first product as non-conveyable
        Product2 testProduct1 = new Product2(name='My Product 1', IsConveyable__c = false);
        insert(testProduct1);

        CartItem cartItem1 = new CartItem(
                Name = CART_ITEM1_NAME,
                CartId = cartId,
                CartDeliveryGroupId = deliveryGroupId,
                Quantity = 10.0,
                SKU = SKU1_NAME,
                Product2Id=testProduct1.Id,
                Type = CartExtension.SalesItemTypeEnum.PRODUCT.name());
        insert cartItem1;

        // Configure the second product as conveyable
        Product2 testProduct2 = new Product2(name='My Product 2', IsConveyable__c = true);
        insert(testProduct2);

        CartItem cartItem2 = new CartItem(
                Name = CART_ITEM2_NAME,
                CartId = cartId,
                CartDeliveryGroupId = deliveryGroupId,
                Quantity = 2.0,
                SKU = SKU2_NAME,
                Product2Id=testProduct2.Id,
                Type = CartExtension.SalesItemTypeEnum.PRODUCT.name());
        insert cartItem2;

        // Configure the third product as non-conveyable
        Product2 testProduct3 = new Product2(name='My Product 3', IsConveyable__c = false);
        insert(testProduct3);

        CartItem cartItem3 = new CartItem(
                Name = CART_ITEM3_NAME,
                CartId = cartId,
                CartDeliveryGroupId = deliveryGroupId,
                Quantity = 5.0,
                SKU = SKU3_NAME,
                Product2Id=testProduct3.Id,
                Type = CartExtension.SalesItemTypeEnum.PRODUCT.name());
        insert cartItem3;

        // Return a map where the key -> value is: CartItemId -> ProductId
        return new Map<ID, ID>{ cartItem1.Id => testProduct1.Id, cartItem2.Id => testProduct2.Id, cartItem3.Id => testProduct3.Id };
    }

    /**
     * @description Create an ItemArrange object, provided the cartItemId and quantity
     * @param cartItemId ID of the CartItem
     * @param deliveryGroupId ID of the CartDeliveryGroup
     * @param productId ID of the Product2
     *
     * @return CartExtension.ItemArrange Holds details of how to arrange an item between CartDeliveryGroups
     */
    private static CartExtension.ItemArrange createItemArrange(ID cartItemId, ID deliveryGroupId, ID productId) {
        CartExtension.ItemArrange.Builder builder = new CartExtension.ItemArrange.Builder()
            .withCartItemId(cartItemId)
            .withProductId(productId);

        if (deliveryGroupId != null) {
            builder.withDeliveryGroupId(deliveryGroupId);
        } else {
            builder
                .withDeliverToCity('Foxborough')
                .withDeliverToCountry('United States')
                .withDeliverFromFirstName('Tom')
                .withDeliverFromLastName('Brady')
                .withDeliverToName('Rob Gronkowski')
                .withDeliverToPostalCode('02035')
                .withDeliverToState('Massachusetts')
                .withDeliverToStreet('2 Patriot Place')
                .withDeliverToCompanyName('New England Patriots');
        }

        return builder.build();
    }

    global class MockDefaultSplitShipmentService extends CartExtension.SplitShipmentServiceMock {

        global override void arrangeItems(CartExtension.ItemArrangementRequest request) {
            CartExtension.Cart cart = request.getCart();
            cart.setName(cart.getName() + ', ' + 'Default Split Shipment Service was invoked');
        }
    }
}