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
    private static final String SKU1_NAME = 'My SKU 1';
    private static final String SKU2_NAME = 'My SKU 2';

    private static final MockDefaultSplitShipmentService mockService = new MockDefaultSplitShipmentService();
    private static final SplitShipmentCallsSuper splitShipmentCallsSuper = new SplitShipmentCallsSuper(mockService);
    private static final SplitShipmentSample splitShipmentSample = new SplitShipmentSample();

    @IsTest
    public static void splitShipmentApexThatCallsSuperShouldInvokeDefaultSplitShipmentService() {
        // Arrange
        // Create a Cart
        CartExtension.Cart cart = CartExtension.CartTestUtil.createCart();

        // Arrange CartItem1 such that a CartDeliveryGroup can have at most quantity 5 of this particular CartItem
        CartExtension.ItemArrange itemArrange = createItemArrange(cart.getCartItems().get(0).getId(), 5.0);
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

    @IsTest
    public static void splitShipmentApexShouldNotCreateNewDeliveryGroupsBasedOnCartItemQuantity() {
        // Arrange
        // Create a Cart with CHECKOUT status
        Id cartId = createCartWithSpecifiedStatus(CartExtension.CartStatusEnum.CHECKOUT);

        // Associate 2 CartItems with the specified quantities to the Cart
        Decimal cartItem1Quantity = 100.0;
        Decimal cartItem2Quantity = 2.0;
        List<ID> Ids = addTwoItemsToCart(cartId, cartItem1Quantity, cartItem2Quantity);

        CartExtension.Cart cart = CartExtension.CartTestUtil.getCart(cartId);

        // Arrange CartItem1 such that a CartDeliveryGroup can have at most quantity 100 of this particular CartItem
        CartExtension.ItemArrange itemArrange1 = createItemArrange(Ids[0], 100.0);

        // Arrange CartItem2 such that a CartDeliveryGroup can have at most quantity 10 of this particular CartItem
        CartExtension.ItemArrange itemArrange2 = createItemArrange(Ids[1], 10.0);

        List<CartExtension.ItemArrange> itemArrangeList = new List<CartExtension.ItemArrange>();
        itemArrangeList.add(itemArrange1);
        itemArrangeList.add(itemArrange2);

        CartExtension.ItemArrangementRequest request = new CartExtension.ItemArrangementRequest.Builder()
                .withCart(cart)
                .withItemArrangeList(itemArrangeList)
                .build();

        // Act
        Test.startTest();
        splitShipmentSample.arrangeItems(request);
        Test.stopTest();

        // Assert
        // Verify that no new CartDeliveryGroup was created
        Assert.areEqual(1, cart.getCartDeliveryGroups().size());

        // Verify that no new CartItems were created and that the original CartItems were kept as is
        Assert.areEqual(2, cart.getCartItems().size());
        Assert.areEqual(cartItem1Quantity, cart.getCartItems().get(0).getQuantity());
        Assert.areEqual(CART_ITEM1_NAME, cart.getCartItems().get(0).getName());
        Assert.areEqual(cartItem2Quantity, cart.getCartItems().get(1).getQuantity());
        Assert.areEqual(CART_ITEM2_NAME, cart.getCartItems().get(1).getName());
    }

    @IsTest
    public static void splitShipmentApexShouldCreateNewDeliveryGroupsBasedOnCartItemQuantity() {
        // Arrange
        // Create a Cart with CHECKOUT status
        Id cartId = createCartWithSpecifiedStatus(CartExtension.CartStatusEnum.CHECKOUT);

        // Associate 2 CartItems with the specified quantities to the Cart
        Decimal cartItem1Quantity = 100.0;
        Decimal cartItem2Quantity = 2.0;
        List<ID> Ids = addTwoItemsToCart(cartId, cartItem1Quantity, cartItem2Quantity);

        CartExtension.Cart cart = CartExtension.CartTestUtil.getCart(cartId);

        // Arrange CartItem1 such that a CartDeliveryGroup can have at most quantity 45 of this particular CartItem
        CartExtension.ItemArrange itemArrange1 = createItemArrange(Ids[0], 45.0);

        // Arrange CartItem2 such that a CartDeliveryGroup can have at most quantity 10 of this particular CartItem
        CartExtension.ItemArrange itemArrange2 = createItemArrange(Ids[1], 10.0);

        List<CartExtension.ItemArrange> itemArrangeList = new List<CartExtension.ItemArrange>();
        itemArrangeList.add(itemArrange1);
        itemArrangeList.add(itemArrange2);

        CartExtension.ItemArrangementRequest request = new CartExtension.ItemArrangementRequest.Builder()
                .withCart(cart)
                .withItemArrangeList(itemArrangeList)
                .build();

        // Act
        Test.startTest();
        splitShipmentSample.arrangeItems(request);
        Test.stopTest();

        // Assert
        // Verify that 2 new CartDeliveryGroups were created (totaling 3)
        Assert.areEqual(3, cart.getCartDeliveryGroups().size());

        // Verify that 2 new CartItems were created (totaling 4)
        Assert.areEqual(4, cart.getCartItems().size());

        // Verify that the quantity for the (original) CartItem1 was reduced from 100.0 to 45.0
        Assert.areEqual(45.0, cart.getCartItems().get(0).getQuantity());
        Assert.areEqual(CART_ITEM1_NAME, cart.getCartItems().get(0).getName());

        // Verify that the quantity for CartItem2 remained the same
        Assert.areEqual(cartItem2Quantity, cart.getCartItems().get(1).getQuantity());
        Assert.areEqual(CART_ITEM2_NAME, cart.getCartItems().get(1).getName());

        // Verify that new CartItems were created to account for the remaining quantity from the original CartItem1
        Assert.areEqual(45.0, cart.getCartItems().get(2).getQuantity());
        Assert.areEqual('My Cart Item 3', cart.getCartItems().get(2).getName());
        Assert.areEqual(10.0, cart.getCartItems().get(3).getQuantity());
        Assert.areEqual('My Cart Item 4', cart.getCartItems().get(3).getName());
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
     * @description Add two items with the specified quantities to the WebCart.
     * @param cartId ID of the WebCart for which we need to add two items
     * @param cartItem1Quantity Quantity of the first CartItem
     * @param cartItem2Quantity Quantity of the second CartItem
     *
     * @return List IDs associated to the newly added CartItems
     */
    private static List<ID> addTwoItemsToCart(ID cartId, Decimal cartItem1Quantity, Decimal cartItem2Quantity) {
        CartDeliveryGroup deliveryGroup = new CartDeliveryGroup(Name = DELIVERYGROUP_NAME, CartId = cartId);
        insert deliveryGroup;

        CartItem cartItem1 = new CartItem(
                Name = CART_ITEM1_NAME,
                CartId = cartId,
                CartDeliveryGroupId = deliveryGroup.Id,
                Quantity = cartItem1Quantity,
                SKU = SKU1_NAME,
                Type = CartExtension.SalesItemTypeEnum.PRODUCT.name());
        insert cartItem1;

        CartItem cartItem2 = new CartItem(
                Name = CART_ITEM2_NAME,
                CartId = cartId,
                CartDeliveryGroupId = deliveryGroup.Id,
                Quantity = cartItem2Quantity,
                SKU = SKU2_NAME,
                Type = CartExtension.SalesItemTypeEnum.PRODUCT.name());
        insert cartItem2;

        return new List<ID>{ cartItem1.Id, cartItem2.Id };
    }

    /**
     * @description Create an ItemArrange object, provided the cartItemId and quantity
     * @param cartItemId ID of the CartItem
     * @param quantity Maximum quantity that a CartDeliveryGroup can have for this particular CartItem
     *
     * @return CartExtension.ItemArrange Holds details of how to arrange an item between CartDeliveryGroups
     */
    private static CartExtension.ItemArrange createItemArrange(ID cartItemId, Decimal quantity) {
        return new CartExtension.ItemArrange.Builder()
                .withCartItemId(cartItemId)
                .withQuantity(quantity)
                .withDeliverToCity('Foxborough')
                .withDeliverToCountry('United States')
                .withDeliverFromFirstName('Tom')
                .withDeliverFromLastName('Brady')
                .withDeliverToName('Bill Belichick')
                .withDeliverToPostalCode('02035')
                .withDeliverToState('Massachusetts')
                .withDeliverToStreet('2 Patriot Place')
                .withDeliverToCompanyName('New England Patriots')
                .build();
    }

    global class MockDefaultSplitShipmentService extends CartExtension.SplitShipmentServiceMock {

        global override void arrangeItems(CartExtension.ItemArrangementRequest request) {
            CartExtension.Cart cart = request.getCart();
            cart.setName(cart.getName() + ', ' + 'Default Split Shipment Service was invoked');
        }
    }
}