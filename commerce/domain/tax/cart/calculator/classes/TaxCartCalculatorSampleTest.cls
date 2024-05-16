/**
 * @description A Sample unit test for TaxCartCalculatorSample.
 */
@IsTest
public class TaxCartCalculatorSampleTest {

    private static final String CART_NAME = 'My Cart';
    private static final String ACCOUNT_NAME = 'My Account';
    private static final String WEBSTORE_NAME = 'My WebStore';
    private static final String DELIVERYGROUP_NAME = 'My Delivery Group';
    private static final String CART_ITEM1_NAME = 'My Cart Item 1';
    private static final String CART_ITEM2_NAME = 'My Cart Item 2';
    private static final String CART_ITEM3_NAME = 'My Cart Item 3';
    private static final String SKU1_NAME = 'My SKU 1';
    private static final String SKU2_NAME = 'My SKU 2';
    private static final String SKU3_NAME = 'My SKU 3';
    private static final Decimal ESTIMATED_PRICE = 350.00;
    private static final Decimal ACTUAL_PRICE_SKU1 = 100.00;
    private static final Decimal ACTUAL_PRICE_SKU2 = 200.00;
    private static final Decimal ACTUAL_PRICE_SKU3 = 300.00;

    @IsTest
    static void testCalculate_withEmptyDeliveryAddress() {
    	// Arrange
        CartExtension.Cart cart = arrangeAndLoadCartWithSpecifiedStatusAndThreeItems(CartExtension.CartStatusEnum.ACTIVE);
        CartExtension.CartCalculateCalculatorRequest request = new CartExtension.CartCalculateCalculatorRequest(cart, CartExtension.OptionalBuyerActionDetails.empty());
        TaxCartCalculatorSample calculator = new TaxCartCalculatorSample();

        // Act
        Test.startTest();
        calculator.calculate(request);
        Test.stopTest();

        // Assert
        cart = request.getCart();
        CartExtension.CartItemList cartItemCollection = cart.getCartItems();
        Assert.areEqual(0, cartItemCollection.get(0).getCartTaxes().size());
    }

    @IsTest
    static void testCalculate_withEmptyCartItems() {
    	// Arrange
        CartExtension.Cart cart = arrangeAndLoadCartWithNoCartItems(CartExtension.CartStatusEnum.ACTIVE);
        CartExtension.CartDeliveryGroup deliveryGroup = cart.getCartDeliveryGroups().get(0);
        deliveryGroup.setDeliverToStreet('newStreet');
        deliveryGroup.setDeliverToCity('newCity');
        deliveryGroup.setDeliverToState('Washington');
        deliveryGroup.setDeliverToCountry('US');
        deliveryGroup.setDeliverToPostalCode('987654');
        deliveryGroup.setDeliverToLatitude(48.1);
        deliveryGroup.setDeliverToLongitude(33.2);
        deliveryGroup.setDeliverToGeocodeAccuracy(null);
        CartExtension.CartCalculateCalculatorRequest request = new CartExtension.CartCalculateCalculatorRequest(cart, CartExtension.OptionalBuyerActionDetails.empty());
        TaxCartCalculatorSample calculator = new TaxCartCalculatorSample();

        // Act
        Test.startTest();
        calculator.calculate(request);
        Test.stopTest();

        // Assert
        cart = request.getCart();
        CartExtension.CartItemList cartItemCollection = cart.getCartItems();
        Assert.areEqual(0, cartItemCollection.size());
    }

    @IsTest
    static void testCalculate_withZeroPrice() {
    	// Arrange
        CartExtension.Cart cart = arrangeAndLoadCartWithSpecifiedStatus(CartExtension.CartStatusEnum.ACTIVE);
        CartExtension.CartDeliveryGroup deliveryGroup = cart.getCartDeliveryGroups().get(0);
        deliveryGroup.setDeliverToStreet('newStreet');
        deliveryGroup.setDeliverToCity('newCity');
        deliveryGroup.setDeliverToState('Washington');
        deliveryGroup.setDeliverToCountry('US');
        deliveryGroup.setDeliverToPostalCode('987654');
        deliveryGroup.setDeliverToLatitude(48.1);
        deliveryGroup.setDeliverToLongitude(33.2);
        deliveryGroup.setDeliverToGeocodeAccuracy(null);
        CartExtension.CartCalculateCalculatorRequest request = new CartExtension.CartCalculateCalculatorRequest(cart, CartExtension.OptionalBuyerActionDetails.empty());
        TaxCartCalculatorSample calculator = new TaxCartCalculatorSample();

        // Act
        Test.startTest();
        calculator.calculate(request);
        Test.stopTest();

        // Assert
        cart = request.getCart();
        CartExtension.CartItemList cartItemCollection = cart.getCartItems();
        Iterator<CartExtension.CartItem> cartItemCollectionIterator = cartItemCollection.iterator();
        while (cartItemCollectionIterator.hasNext()) {
            CartExtension.CartItem cartItem = cartItemCollectionIterator.next();
            Assert.areEqual(0.00, cartItem.getNetUnitPrice());
            Assert.areEqual(0.00, cartItem.getGrossUnitPrice());
        }
    }

    @IsTest
    static void testCalculate_withDeliveryAddress() {
    	// Arrange
        CartExtension.Cart cart = arrangeAndLoadCartWithSpecifiedStatus(CartExtension.CartStatusEnum.ACTIVE);
        CartExtension.CartDeliveryGroup deliveryGroup = cart.getCartDeliveryGroups().get(0);
        deliveryGroup.setDeliverToStreet('newStreet');
        deliveryGroup.setDeliverToCity('newCity');
        deliveryGroup.setDeliverToState('Washington');
        deliveryGroup.setDeliverToCountry('US');
        deliveryGroup.setDeliverToPostalCode('987654');
        deliveryGroup.setDeliverToLatitude(48.1);
        deliveryGroup.setDeliverToLongitude(33.2);
        deliveryGroup.setDeliverToGeocodeAccuracy(null);
        cart.getCartItems().get(0).setTotalPrice(100.00);
        CartExtension.CartCalculateCalculatorRequest request = new CartExtension.CartCalculateCalculatorRequest(cart, CartExtension.OptionalBuyerActionDetails.empty());
        TaxCartCalculatorSample calculator = new TaxCartCalculatorSample();

        // Act
        Test.startTest();
        calculator.calculate(request);
        Test.stopTest();

        // Assert
        cart = request.getCart();
        CartExtension.CartItemList cartItemCollection = cart.getCartItems();
        Iterator<CartExtension.CartItem> cartItemCollectionIterator = cartItemCollection.iterator();
        while (cartItemCollectionIterator.hasNext()) {
            CartExtension.CartItem cartItem = cartItemCollectionIterator.next();
            Assert.areEqual(100.00, cartItem.getNetUnitPrice());
            Assert.areEqual(108.00, cartItem.getGrossUnitPrice());
        }
    }

    @IsTest
    static void testCalculate_withShippingChargeItem() {
    	// Arrange
        CartExtension.Cart cart = arrangeAndLoadCartWithShippingChargeItem(CartExtension.CartStatusEnum.ACTIVE);
        CartExtension.CartDeliveryGroup deliveryGroup = cart.getCartDeliveryGroups().get(0);
        deliveryGroup.setDeliverToStreet('newStreet');
        deliveryGroup.setDeliverToCity('newCity');
        deliveryGroup.setDeliverToState('Washington');
        deliveryGroup.setDeliverToCountry('US');
        deliveryGroup.setDeliverToPostalCode('987654');
        deliveryGroup.setDeliverToLatitude(48.1);
        deliveryGroup.setDeliverToLongitude(33.2);
        deliveryGroup.setDeliverToGeocodeAccuracy(null);
        cart.getCartItems().get(0).setTotalPrice(100.00);
        CartExtension.CartCalculateCalculatorRequest request = new CartExtension.CartCalculateCalculatorRequest(cart, CartExtension.OptionalBuyerActionDetails.empty());
        TaxCartCalculatorSample calculator = new TaxCartCalculatorSample();

        // Act
        Test.startTest();
        calculator.calculate(request);
        Test.stopTest();

        // Assert
        cart = request.getCart();
        CartExtension.CartItemList cartItemCollection = cart.getCartItems();
        Assert.areEqual(2, cartItemCollection.size());
    }

    @IsTest
    static void testCalculate_withNetPrice() {
    	// Arrange
        CartExtension.Cart cart = arrangeAndLoadCartWithSpecifiedStatus(CartExtension.CartStatusEnum.ACTIVE);
        CartExtension.CartDeliveryGroup deliveryGroup = cart.getCartDeliveryGroups().get(0);
        deliveryGroup.setDeliverToStreet('newStreet');
        deliveryGroup.setDeliverToCity('newCity');
        deliveryGroup.setDeliverToState('Washington');
        deliveryGroup.setDeliverToCountry('US');
        deliveryGroup.setDeliverToPostalCode('987654');
        deliveryGroup.setDeliverToLatitude(48.1);
        deliveryGroup.setDeliverToLongitude(33.2);
        deliveryGroup.setDeliverToGeocodeAccuracy(null);
        cart.getCartItems().get(0).setTotalPrice(100.00);
        cart.getCartItems().get(0).setNetUnitPrice(200.00);
        CartExtension.CartCalculateCalculatorRequest request = new CartExtension.CartCalculateCalculatorRequest(cart, CartExtension.OptionalBuyerActionDetails.empty());
        TaxCartCalculatorSample calculator = new TaxCartCalculatorSample();

        // Act
        Test.startTest();
        calculator.calculate(request);
        Test.stopTest();

        // Assert
        cart = request.getCart();
        CartExtension.CartItemList cartItemCollection = cart.getCartItems();
        Iterator<CartExtension.CartItem> cartItemCollectionIterator = cartItemCollection.iterator();
        while (cartItemCollectionIterator.hasNext()) {
            CartExtension.CartItem cartItem = cartItemCollectionIterator.next();
            Assert.areEqual(100.00, cartItem.getNetUnitPrice());
            Assert.areEqual(108.00, cartItem.getGrossUnitPrice());
        }
    }

    @IsTest
    static void testCalculate_withPriceAdjustments() {
    	// Arrange
        CartExtension.Cart cart = arrangeAndLoadCartWithAdjustments(CartExtension.CartStatusEnum.ACTIVE);
        CartExtension.CartDeliveryGroup deliveryGroup = cart.getCartDeliveryGroups().get(0);
        deliveryGroup.setDeliverToStreet('newStreet');
        deliveryGroup.setDeliverToCity('newCity');
        deliveryGroup.setDeliverToState('Washington');
        deliveryGroup.setDeliverToCountry('US');
        deliveryGroup.setDeliverToPostalCode('987654');
        deliveryGroup.setDeliverToLatitude(48.1);
        deliveryGroup.setDeliverToLongitude(33.2);
        deliveryGroup.setDeliverToGeocodeAccuracy(null);

        CartExtension.CartItemPriceAdjustment newItemPriceAdjustment = new CartExtension.CartItemPriceAdjustment
        							(CartExtension.CartAdjustmentTargetTypeEnum.ITEM, 1,
                                    CartExtension.PriceAdjustmentSourceEnum.PROMOTION,
                                    CartExtension.AdjustmentTypeEnum.ADJUSTMENT_AMOUNT, -2, '0c8RO0000005qNPYAY');
        newItemPriceAdjustment.setPriority(2);
        newItemPriceAdjustment.setAdjustmentValue(3);
        CartExtension.CartItemPriceAdjustmentList cartItemPriceAdjustments = cart.getCartItems().get(0).getCartItemPriceAdjustments();
        cartItemPriceAdjustments.add(newItemPriceAdjustment);

        cart.getCartItems().get(0).setTotalPrice(100.00);
        cart.getCartItems().get(0).setNetUnitPrice(200.00);
        CartExtension.CartCalculateCalculatorRequest request = new CartExtension.CartCalculateCalculatorRequest(cart, CartExtension.OptionalBuyerActionDetails.empty());
        TaxCartCalculatorSample calculator = new TaxCartCalculatorSample();

        // Act
        Test.startTest();
        calculator.calculate(request);
        Test.stopTest();

        // Assert
        cart = request.getCart();
        CartExtension.CartItemList cartItemCollection = cart.getCartItems();
        Iterator<CartExtension.CartItem> cartItemCollectionIterator = cartItemCollection.iterator();
        while (cartItemCollectionIterator.hasNext()) {
            CartExtension.CartItem cartItem = cartItemCollectionIterator.next();
            Assert.areEqual(33.666666666666664, cartItem.getNetUnitPrice());
            Assert.areEqual(36.36, cartItem.getGrossUnitPrice());
        }
    }

    /**
     * @description Create and return a WebCart with the specified status and 3 items.
     *
     * @param cartStatus The status of the cart.
     *
     * @return <<CartExtension.Cart>>
     */
    private static ID arrangeCartWithSpecifiedStatus(CartExtension.CartStatusEnum cartStatus) {
        Account account = new Account(Name = ACCOUNT_NAME);
        insert account;

        WebStore webStore = new WebStore(Name = WEBSTORE_NAME, OptionsCartCalculateEnabled = true);
        insert webStore;

        WebCart webCart = new WebCart(
                Name = CART_NAME,
                WebStoreId = webStore.Id,
                AccountId = account.Id,
                Status = cartStatus.name());
        insert webCart;
        return webCart.Id;
    }

    private static List<ID> arrangeThreeCartItems(ID cartId) {
        CartDeliveryGroup deliveryGroup = new CartDeliveryGroup(Name = DELIVERYGROUP_NAME, CartId = cartId);
        insert deliveryGroup;

        CartItem cartItem1 = new CartItem(
                Name = CART_ITEM1_NAME,
                CartId = cartId,
                CartDeliveryGroupId = deliveryGroup.Id,
                Quantity = 3,
                SKU = SKU1_NAME,
                Type = CartExtension.SalesItemTypeEnum.PRODUCT.name());
        insert cartItem1;

        CartItem cartItem2 = new CartItem(
                Name = CART_ITEM2_NAME,
                CartId = cartId,
                CartDeliveryGroupId = deliveryGroup.Id,
                Quantity = 3,
                SKU = SKU2_NAME,
                Type = CartExtension.SalesItemTypeEnum.PRODUCT.name());
        insert cartItem2;

        CartItem cartItem3 = new CartItem(
                Name = CART_ITEM3_NAME,
                CartId = cartId,
                CartDeliveryGroupId = deliveryGroup.Id,
                Quantity = 3,
                SKU = SKU3_NAME,
                Type = CartExtension.SalesItemTypeEnum.PRODUCT.name());
        insert cartItem3;
        return new List<ID>{cartItem1.Id, cartItem2.Id, cartItem3.Id};
    }

    private static CartExtension.Cart arrangeAndLoadCartWithSpecifiedStatusAndThreeItems(CartExtension.CartStatusEnum cartStatus) {
        Id cartId = arrangeCartWithSpecifiedStatus(cartStatus);
        arrangeThreeCartItems(cartId);
        return CartExtension.CartTestUtil.getCart(cartId);
    }

    private static List<ID> arrangeOneCartItemsWithShippingChargeType(ID cartId) {
        CartDeliveryGroup deliveryGroup = new CartDeliveryGroup(Name = DELIVERYGROUP_NAME, CartId = cartId);
        insert deliveryGroup;

        CartItem cartItem1 = new CartItem(
                Name = CART_ITEM1_NAME,
                CartId = cartId,
                CartDeliveryGroupId = deliveryGroup.Id,
                Quantity = 3,
                SKU = SKU1_NAME,
                Type = CartExtension.SalesItemTypeEnum.CHARGE.name());
        insert cartItem1;

        CartItem cartItem2 = new CartItem(
                Name = CART_ITEM2_NAME,
                CartId = cartId,
                CartDeliveryGroupId = deliveryGroup.Id,
                Quantity = 3,
                SKU = SKU2_NAME,
                Type = CartExtension.SalesItemTypeEnum.PRODUCT.name());
        insert cartItem2;

        return new List<ID>{cartItem1.Id, cartItem2.Id};
    }

    private static CartExtension.Cart arrangeAndLoadCartWithShippingChargeItem(CartExtension.CartStatusEnum cartStatus) {
        Id cartId = arrangeCartWithSpecifiedStatus(cartStatus);
        arrangeOneCartItemsWithShippingChargeType(cartId);
        return CartExtension.CartTestUtil.getCart(cartId);
    }

    private static List<ID> arrangeOneCartItemWithPriceAdjustments(ID cartId) {
        CartDeliveryGroup deliveryGroup = new CartDeliveryGroup(Name = DELIVERYGROUP_NAME, CartId = cartId);
        insert deliveryGroup;

        CartItem cartItem = new CartItem(
                Name = CART_ITEM1_NAME,
                CartId = cartId,
                CartDeliveryGroupId = deliveryGroup.Id,
                Quantity = 3,
                SKU = SKU1_NAME,
                Type = CartExtension.SalesItemTypeEnum.PRODUCT.name());
        insert cartItem;
        return new List<ID>{cartItem.Id};
    }

    private static CartExtension.Cart arrangeAndLoadCartWithAdjustments(CartExtension.CartStatusEnum cartStatus) {
        Id cartId = arrangeCartWithSpecifiedStatus(cartStatus);
        arrangeOneCartItemWithPriceAdjustments(cartId);
        return CartExtension.CartTestUtil.getCart(cartId);
    }

    private static List<ID> arrangeDeliveryGroup(ID cartId) {
        CartDeliveryGroup deliveryGroup = new CartDeliveryGroup(Name = DELIVERYGROUP_NAME, CartId = cartId);
        insert deliveryGroup;
        return new List<ID>{};
    }

    private static CartExtension.Cart arrangeAndLoadCartWithNoCartItems(CartExtension.CartStatusEnum cartStatus) {
        Id cartId = arrangeCartWithSpecifiedStatus(cartStatus);
        arrangeDeliveryGroup(cartId);
        return CartExtension.CartTestUtil.getCart(cartId);
    }

    private static CartExtension.Cart arrangeAndLoadCartWithSpecifiedStatus(CartExtension.CartStatusEnum cartStatus) {
        Id cartId = arrangeCartWithSpecifiedStatus(cartStatus);
        arrangeCartItemsWithDeliveryAddress(cartId);
        return CartExtension.CartTestUtil.getCart(cartId);
    }

    private static List<ID> arrangeCartItemsWithDeliveryAddress(ID cartId) {
        CartDeliveryGroup deliveryGroup = new CartDeliveryGroup(Name = DELIVERYGROUP_NAME, CartId = cartId);
        insert deliveryGroup;

        CartItem cartItem1 = new CartItem(
                Name = CART_ITEM1_NAME,
                CartId = cartId,
                CartDeliveryGroupId = deliveryGroup.Id,
                Quantity = 1,
                SKU = SKU1_NAME,
                Type = CartExtension.SalesItemTypeEnum.PRODUCT.name());
        insert cartItem1;

        return new List<ID>{cartItem1.Id};
    }

}
