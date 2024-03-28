/**
 * @description Sample unit test for PromotionCalculatorSample.
 */
@IsTest
global class PromotionCalculatorSampleTest {
    private static final String CART_NAME = 'My Cart';
    private static final String ACCOUNT_NAME = 'My Account';
    private static final String WEBSTORE_NAME = 'My WebStore';
    private static final String DELIVERYGROUP_NAME = 'Default Delivery Group';
    private static final String CART_ITEM1_NAME = 'My Cart Item 1';
    private static final String CART_ITEM2_NAME = 'My Cart Item 2';
    private static final String TARGET_PRODUCT_ID = '01txx0000006lmuAAA';
    private static final String QUALIFIER_PRODUCT_ID = '01txx0000006lmmAAA';
    private static final Decimal TARGET_SALES_PRICE = 10.00;
    private static final Decimal QUALIFIER_SALES_PRICE = 20.00;
    private static final Decimal DISCOUNT_VALUE = -2.0;
    private static final Decimal TOTAL_ADJUSTMENT_AMOUNT = -4.0;

    private static final PromotionCalculatorSample promotionCalculator = new PromotionCalculatorSample();

    /**
     * @description Verify Promotion is correctly applied on cart item.
     */
    @IsTest
    public static void testPromotionAndPriceAdjustments_WithQualifierAndTargetItems() {
        // Arrange
        // Create a Cart with CHECKOUT status
        Id cartId = createCartWithSpecifiedStatus(CartExtension.CartStatusEnum.CHECKOUT);

        // Associate qualifying & target items to the Cart and load the cart
        CartExtension.Cart cart = addItemsToCart(cartId, 10, 3);

        // Act
        Test.startTest();
        promotionCalculator.calculate(new CartExtension.CartCalculateCalculatorRequest(cart, CartExtension.OptionalBuyerActionDetails.empty()));
        Test.stopTest();

        // Assert
        // Verify that we have 2 CartItems
        Assert.areEqual(2, cart.getCartItems().size());

        // Verify that the CartItem has 1 price adjustment with correct adjustment type and value
        Assert.areEqual(1, cart.getCartItems().get(1).getCartItemPriceAdjustments().size());
        Assert.areEqual(Cartextension.AdjustmentTypeEnum.ADJUSTMENT_AMOUNT, cart.getCartItems().get(1).getCartItemPriceAdjustments().get(0).getAdjustmentType());
        Assert.areEqual(DISCOUNT_VALUE, cart.getCartItems().get(1).getCartItemPriceAdjustments().get(0).getAdjustmentValue());
        Assert.areEqual(TOTAL_ADJUSTMENT_AMOUNT, cart.getCartItems().get(1).getCartItemPriceAdjustments().get(0).getTotalAmount());

        // Verify CartItem adjustment and total price
		Assert.areEqual(TOTAL_ADJUSTMENT_AMOUNT, cart.getCartItems().get(1).getTotalPromoAdjustmentAmount());
        Assert.areEqual(TOTAL_ADJUSTMENT_AMOUNT, cart.getCartItems().get(1).getTotalAdjustmentAmount());
        Assert.areEqual(((TARGET_SALES_PRICE * 3) - TOTAL_ADJUSTMENT_AMOUNT), cart.getCartItems().get(1).getTotalPriceAfterAllAdjustments());
    }

    /**
     * @description Verify Promotion is not applied when cart does not include enough qualifying or target items.
     */
    @IsTest
    public static void testPromotionAndPriceAdjustments_WithOutQualifierAndTargetItems() {
        // Arrange
        // Create a Cart with CHECKOUT status
        Id cartId = createCartWithSpecifiedStatus(CartExtension.CartStatusEnum.CHECKOUT);

        // Associate qualifying & target items to the Cart and load the cart
        CartExtension.Cart cart = addItemsToCart(cartId, 4, 1);

        // Act
        Test.startTest();
        promotionCalculator.calculate(new CartExtension.CartCalculateCalculatorRequest(cart, CartExtension.OptionalBuyerActionDetails.empty()));
        Test.stopTest();

        // Assert
        // Verify that we have 2 CartItems
        Assert.areEqual(2, cart.getCartItems().size());

        // Verify that the CartItem has 0 price adjustments.
        Assert.areEqual(0, cart.getCartItems().get(0).getCartItemPriceAdjustments().size());
        Assert.areEqual(0, cart.getCartItems().get(1).getCartItemPriceAdjustments().size());
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
     * @description Add an item to the specified Cart.
     * @param cartId ID of the WebCart for which we need to add three items
     *
     * @return Cart
     */
    private static CartExtension.Cart addItemsToCart(ID cartId, Decimal qualifierCount, Decimal targetCount) {
        CartDeliveryGroup deliveryGroup = new CartDeliveryGroup(Name = DELIVERYGROUP_NAME, CartId = cartId);
        insert deliveryGroup;

        CartItem cartItem1 = new CartItem(
            Name = CART_ITEM1_NAME,
            CartId = cartId,
            CartDeliveryGroupId = deliveryGroup.Id,
            Quantity = qualifierCount,
            Product2Id = QUALIFIER_PRODUCT_ID,
            SalesPrice = QUALIFIER_SALES_PRICE,
            Type = CartExtension.SalesItemTypeEnum.PRODUCT.name());
        insert cartItem1;

        CartItem cartItem2 = new CartItem(
                Name = CART_ITEM2_NAME,
                CartId = cartId,
                CartDeliveryGroupId = deliveryGroup.Id,
                Quantity = targetCount,
                Product2Id = TARGET_PRODUCT_ID,
                SalesPrice = TARGET_SALES_PRICE,
                Type = CartExtension.SalesItemTypeEnum.PRODUCT.name());
        insert cartItem2;

        // Return Cart
        return CartExtension.CartTestUtil.getCart(cartId);
    }
}
