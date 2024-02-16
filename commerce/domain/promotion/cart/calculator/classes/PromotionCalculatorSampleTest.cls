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
    private static final String PRODUCT_NAME = '01tSB000000I0knYAC';
    private static final Decimal SALES_PRICE = 80.00;
    private static final Decimal DISCOUNT_VALUE = -5.0;
    private static final Decimal TOTAL_ADJUSTMENT_AMOUNT = -4.0;

    private static final PromotionCalculatorSample promotionCalculator = new PromotionCalculatorSample();

    /**
     * @description Verify that Promotion is correctly applied on cart item.
     */
    @IsTest
    public static void testPromotionAndPriceAdjustments() {
        // Arrange
        // Create a Cart with CHECKOUT status
        Id cartId = createCartWithSpecifiedStatus(CartExtension.CartStatusEnum.CHECKOUT);

        // Associate an item to the Cart and load the cart
        CartExtension.Cart cart = addItemToCart(cartId);

        // Act
        Test.startTest();
        promotionCalculator.calculate(new CartExtension.CartCalculateCalculatorRequest(cart, CartExtension.OptionalBuyerActionDetails.empty()));
        Test.stopTest();

        // Assert
        // Verify that we have 1 CartItem
        Assert.areEqual(1, cart.getCartItems().size());

        // Verify that the CartItem has 1 price adjustment with correct adjustment type and value
        Assert.areEqual(1, cart.getCartItems().get(0).getCartItemPriceAdjustments().size());
        Assert.areEqual(Cartextension.AdjustmentTypeEnum.ADJUSTMENT_PERCENTAGE, cart.getCartItems().get(0).getCartItemPriceAdjustments().get(0).getAdjustmentType());
        Assert.areEqual(DISCOUNT_VALUE, cart.getCartItems().get(0).getCartItemPriceAdjustments().get(0).getAdjustmentValue());
        Assert.areEqual(TOTAL_ADJUSTMENT_AMOUNT, cart.getCartItems().get(0).getCartItemPriceAdjustments().get(0).getTotalAmount());

        // Verify CartItem adjustment and total price
		Assert.areEqual(TOTAL_ADJUSTMENT_AMOUNT, cart.getCartItems().get(0).getTotalPromoAdjustmentAmount());
        Assert.areEqual(TOTAL_ADJUSTMENT_AMOUNT, cart.getCartItems().get(0).getTotalAdjustmentAmount());
        Assert.areEqual((SALES_PRICE - TOTAL_ADJUSTMENT_AMOUNT), cart.getCartItems().get(0).getTotalPriceAfterAllAdjustments());
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
    private static CartExtension.Cart addItemToCart(ID cartId) {
        CartDeliveryGroup deliveryGroup = new CartDeliveryGroup(Name = DELIVERYGROUP_NAME, CartId = cartId);
        insert deliveryGroup;

        CartItem cartItem1 = new CartItem(
            Name = CART_ITEM1_NAME,
            CartId = cartId,
            CartDeliveryGroupId = deliveryGroup.Id,
            Quantity = 1,
            Product2Id = PRODUCT_NAME,
            SalesPrice = SALES_PRICE,
            Type = CartExtension.SalesItemTypeEnum.PRODUCT.name());
        insert cartItem1;

        // Return Cart
        return CartExtension.CartTestUtil.getCart(cartId);
    }
}
