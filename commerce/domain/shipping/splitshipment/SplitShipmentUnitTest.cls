/**
 * @description Sample unit test for SplitShipmentSample and SplitShipmentCallsSuper.
 */
@IsTest
global class SplitShipmentUnitTest {

    private static final MockDefaultSplitShipmentService mockService = new MockDefaultSplitShipmentService();
    private static final SplitShipmentCallsSuper splitShipmentCallsSuper = new SplitShipmentCallsSuper(mockService);
    private static final SplitShipmentSample splitShipmentSample = new SplitShipmentSample();

    @IsTest
    public static void splitShipmentApexThatCallsSuperShouldInvokeDefaultSplitShipmentService() {
        // Arrange
        CartExtension.Cart cart = CartExtension.CartTestUtil.createCart();

        CartExtension.ItemArrange itemArrange = new CartExtension.ItemArrange.Builder()
                .withProductId('01txx0000006iP2AAI')
                .withQuantity(Decimal.valueOf(5))
                .withCartItemId(cart.getCartItems().get(0).getId())
                .withDeliveryGroupId(cart.getCartItems().get(0).getCartDeliveryGroup().getId())
                .withDeliveryGroupName(CartExtension.CartTestUtil.DELIVERYGROUP_NAME)
                .withDeliverToCity('Foxboro')
                .withDeliverToCountry('USA')
                .withDeliverFromFirstName('Tom')
                .withDeliverFromLastName('Brady')
                .withDeliverToName('Bill Belichick')
                .withDeliverToPostalCode('02035')
                .withDeliverToState('MA')
                .withDeliverToStreet('2 Patriot Place')
                .withDeliverToCompanyName('New England Patriots')
                .withDeliveryAddressId('8lW456789012679AAA')
                .build();

		List<CartExtension.ItemArrange> itemArrangeList = new List<CartExtension.ItemArrange>();
        itemArrangeList.add(itemArrange);

        CartExtension.ItemArrangementRequest request = new CartExtension.ItemArrangementRequest.Builder()
                .withCart(cart)
                .withItemArrangeList(itemArrangeList)
                .build();

        // Act
        splitShipmentCallsSuper.arrangeItems(request);

        // Assert
        Assert.isTrue(cart.getName().contains('Default Split Shipment Service was invoked'));
    }

    @IsTest
    public static void splitShipmentApexWithDeliveryGroupIdAndProductId() {
        // Arrange
        CartExtension.Cart cart = CartExtension.CartTestUtil.createCart();

        CartExtension.ItemArrange itemArrange = new CartExtension.ItemArrange.Builder()
                .withProductId('01txx0000006iP2AAI')
                .withQuantity(Decimal.valueOf(5))
                .withDeliveryGroupId(cart.getCartItems().get(0).getCartDeliveryGroup().getId())
                .build();

		List<CartExtension.ItemArrange> itemArrangeList = new List<CartExtension.ItemArrange>();
        itemArrangeList.add(itemArrange);

        CartExtension.ItemArrangementRequest request = new CartExtension.ItemArrangementRequest.Builder()
                .withCart(cart)
                .withItemArrangeList(itemArrangeList)
                .build();

        // Act
        splitShipmentSample.arrangeItems(request);

        // Assert
        Assert.isTrue(cart.getCartDeliveryGroups().size() == 1);
        Assert.isTrue(cart.getCartItems().size() == 2);
        Assert.isTrue(cart.getCartItems().get(1).getQuantity() == 5.0);
    }

    @IsTest
    public static void splitShipmentApexWithDeliveryGroupIdAndCartItemId() {
        // Arrange
        CartExtension.Cart cart = CartExtension.CartTestUtil.createCart();

        CartExtension.ItemArrange itemArrange = new CartExtension.ItemArrange.Builder()
                .withCartItemId(cart.getCartItems().get(0).getId())
                .withQuantity(Decimal.valueOf(5))
                .withDeliveryGroupId(cart.getCartItems().get(0).getCartDeliveryGroup().getId())
                .build();

		List<CartExtension.ItemArrange> itemArrangeList = new List<CartExtension.ItemArrange>();
        itemArrangeList.add(itemArrange);

        CartExtension.ItemArrangementRequest request = new CartExtension.ItemArrangementRequest.Builder()
                .withCart(cart)
                .withItemArrangeList(itemArrangeList)
                .build();

        // Act
        splitShipmentSample.arrangeItems(request);

        // Assert
        Assert.isTrue(cart.getCartDeliveryGroups().size() == 1);
        Assert.isTrue(cart.getCartItems().size() == 1);
        Assert.isTrue(cart.getCartItems().get(0).getQuantity() == 5.0);
    }

    @IsTest
    public static void splitShipmentApexWithAddressAndProductIdKeepingExistingCDG() {
        // Arrange
        CartExtension.Cart cart = CartExtension.CartTestUtil.createCart();

        CartExtension.CartDeliveryGroup cartDeliveryGroup = cart.getCartDeliveryGroups().get(0);
        setAddressFields(cartDeliveryGroup);

        CartExtension.ItemArrange itemArrange = new CartExtension.ItemArrange.Builder()
                .withProductId('01txx0000006iP2AAI')
                .withQuantity(Decimal.valueOf(5))
                .withDeliveryGroupName(CartExtension.CartTestUtil.DELIVERYGROUP_NAME)
                .withDeliverToCity('Foxboro')
                .withDeliverToCountry('USA')
                .withDeliverFromFirstName('Tom')
                .withDeliverFromLastName('Brady')
                .withDeliverToName('Bill Belichick')
                .withDeliverToPostalCode('02035')
                .withDeliverToState('MA')
                .withDeliverToStreet('2 Patriot Place')
                .withDeliverToCompanyName('New England Patriots')
                .build();

		List<CartExtension.ItemArrange> itemArrangeList = new List<CartExtension.ItemArrange>();
        itemArrangeList.add(itemArrange);

        CartExtension.ItemArrangementRequest request = new CartExtension.ItemArrangementRequest.Builder()
                .withCart(cart)
                .withItemArrangeList(itemArrangeList)
                .build();

        // Act
        splitShipmentSample.arrangeItems(request);

        // Assert
        Assert.isTrue(cart.getCartDeliveryGroups().size() == 1);
        Assert.isTrue(cart.getCartItems().size() == 2);
        Assert.isTrue(cart.getCartItems().get(1).getQuantity() == 5.0);
        Assert.isTrue(cart.getCartDeliveryGroups().get(0).getDeliverToAddress().getCity() == 'Foxboro');
    }

    @IsTest
    public static void splitShipmentApexWithAddressAndProductIdCreatingNewCDG() {
        // Arrange
        CartExtension.Cart cart = CartExtension.CartTestUtil.createCart();

        CartExtension.CartDeliveryGroup cartDeliveryGroup = cart.getCartDeliveryGroups().get(0);
        setAddressFields(cartDeliveryGroup);

        CartExtension.ItemArrange itemArrange = new CartExtension.ItemArrange.Builder()
                .withProductId('01txx0000006iP2AAI')
                .withQuantity(Decimal.valueOf(5))
                .withDeliveryGroupName(CartExtension.CartTestUtil.DELIVERYGROUP_NAME)
                .withDeliverToCity('Fremont')
                .withDeliverToCountry('USA')
                .withDeliverFromFirstName('Michael')
                .withDeliverFromLastName('Jackson')
                .withDeliverToName('Michael Jackson')
                .withDeliverToPostalCode('94539')
                .withDeliverToState('CA')
                .withDeliverToStreet('10 Guy St')
                .withDeliverToCompanyName('Jackson 5')
                .build();

		List<CartExtension.ItemArrange> itemArrangeList = new List<CartExtension.ItemArrange>();
        itemArrangeList.add(itemArrange);

        CartExtension.ItemArrangementRequest request = new CartExtension.ItemArrangementRequest.Builder()
                .withCart(cart)
                .withItemArrangeList(itemArrangeList)
                .build();

        // Act
        splitShipmentSample.arrangeItems(request);

        // Assert
        Assert.isTrue(cart.getCartDeliveryGroups().size() == 2);
        Assert.isTrue(cart.getCartItems().size() == 2);
        Assert.isTrue(cart.getCartItems().get(1).getQuantity() == 5.0);
        Assert.isTrue(cart.getCartDeliveryGroups().get(0).getDeliverToAddress().getCity() == 'Foxboro');
        Assert.isTrue(cart.getCartDeliveryGroups().get(1).getDeliverToAddress().getCity() == 'Fremont');
    }

    @IsTest
    public static void splitShipmentApexWithAddressIdAndProductIdCreatingNewCDG() {
        // Arrange
        CartExtension.Cart cart = CartExtension.CartTestUtil.createCart();

        CartExtension.CartDeliveryGroup cartDeliveryGroup = cart.getCartDeliveryGroups().get(0);
        setAddressFields(cartDeliveryGroup);

        ContactPointAddress contactPointAddress = new ContactPointAddress();
        insertContactPointAddress(cart, contactPointAddress);

        CartExtension.ItemArrange itemArrange = new CartExtension.ItemArrange.Builder()
                .withProductId('01txx0000006iP2AAI')
                .withQuantity(Decimal.valueOf(5))
                .withDeliveryGroupName('New Cart Delivery Group')
                .withDeliveryAddressId(contactPointAddress.Id)
                .build();

		List<CartExtension.ItemArrange> itemArrangeList = new List<CartExtension.ItemArrange>();
        itemArrangeList.add(itemArrange);

        CartExtension.ItemArrangementRequest request = new CartExtension.ItemArrangementRequest.Builder()
                .withCart(cart)
                .withItemArrangeList(itemArrangeList)
                .build();

        // Act
        splitShipmentSample.arrangeItems(request);

        // Assert
        Assert.isTrue(cart.getCartDeliveryGroups().size() == 2);
        Assert.isTrue(cart.getCartItems().size() == 2);
        Assert.isTrue(cart.getCartItems().get(1).getQuantity() == 5.0);
        Assert.isTrue(cart.getCartDeliveryGroups().get(0).getName() == CartExtension.CartTestUtil.DELIVERYGROUP_NAME);
        Assert.isTrue(cart.getCartDeliveryGroups().get(1).getName() == 'New Cart Delivery Group');
    }

    @IsTest
    public static void splitShipmentApexWithAddressIdAndProductIdKeepingExistingCDG() {
        // Arrange
        CartExtension.Cart cart = CartExtension.CartTestUtil.createCart();

        CartExtension.CartDeliveryGroup cartDeliveryGroup = cart.getCartDeliveryGroups().get(0);
        setAddressFields(cartDeliveryGroup);

        ContactPointAddress contactPointAddress = new ContactPointAddress();
        insertContactPointAddress(cart, contactPointAddress);

        CartExtension.ItemArrange itemArrange = new CartExtension.ItemArrange.Builder()
                .withProductId('01txx0000006iP2AAI')
                .withQuantity(Decimal.valueOf(5))
                .withDeliveryGroupName(CartExtension.CartTestUtil.DELIVERYGROUP_NAME)
                .withDeliveryAddressId(contactPointAddress.Id)
                .build();

		List<CartExtension.ItemArrange> itemArrangeList = new List<CartExtension.ItemArrange>();
        itemArrangeList.add(itemArrange);

        CartExtension.ItemArrangementRequest request = new CartExtension.ItemArrangementRequest.Builder()
                .withCart(cart)
                .withItemArrangeList(itemArrangeList)
                .build();

        // Act
        splitShipmentSample.arrangeItems(request);

        // Assert
        Assert.isTrue(cart.getCartDeliveryGroups().size() == 1);
        Assert.isTrue(cart.getCartItems().size() == 2);
        Assert.isTrue(cart.getCartItems().get(1).getQuantity() == 5.0);
    }

    /**
     * @description Set the necessary delivery address fields within the Cart Delivery Group.
     * @param cartDeliveryGroup The Cart Delivery Group to update 
     */
    private static void setAddressFields(CartExtension.CartDeliveryGroup cartDeliveryGroup) {
        cartDeliveryGroup.setDeliverToCity('Foxboro');
        cartDeliveryGroup.setDeliverToCountry('USA');
        cartDeliveryGroup.setDeliverToFirstName('Tom');
        cartDeliveryGroup.setDeliverToLastName('Brady');
        cartDeliveryGroup.setDeliverToName('Bill Belichick');
        cartDeliveryGroup.setDeliverToPostalCode('02035');
        cartDeliveryGroup.setDeliverToState('MA');
        cartDeliveryGroup.setDeliverToStreet('2 Patriot Place');
        cartDeliveryGroup.setCompanyName('New England Patriots');
    }

    /**
     * @description Create a new ContactPointAddress record in the DB
     * @param cart Representation of a `WebCart` record
     * @param contactPointAddress Contact Point Address record to insert
     */
    private static void insertContactPointAddress(CartExtension.Cart cart, ContactPointAddress contactPointAddress) {
        contactPointAddress.ParentId = cart.getAccountId();
        contactPointAddress.Name = 'ContactPointAddress';
        contactPointAddress.Street = '2 Patriot Place';
        contactPointAddress.City = 'Foxboro';
        contactPointAddress.Country = 'USA';
        contactPointAddress.PostalCode = '02035';
        contactPointAddress.State = 'MA';

        insert contactPointAddress;
    }

    /**
     * @description Mock version of Split Shipment Service.
     */
    global class MockDefaultSplitShipmentService extends CartExtension.SplitShipmentServiceMock {

        global override void arrangeItems(CartExtension.ItemArrangementRequest request) {
            CartExtension.Cart cart = request.getCart();
            cart.setName(cart.getName() + ', ' + 'Default Split Shipment Service was invoked');
        }
    }
}