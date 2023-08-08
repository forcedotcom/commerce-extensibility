/**
 * A Sample unit test for <<CartCalculate>>.
 */
@IsTest
public class CartCalculateSampleUnitTest {
    private static final String ACCOUNT_NAME = 'My Account';
    private static final String WEBSTORE_NAME = 'My WebStore';
    private static final String CART_NAME = 'My Cart';
    private static final String DELIVERYGROUP_NAME = 'My Delivery Group';
    private static final String CARTITEM_NAME = 'My Cart Item';

    @IsTest
    public static void shouldRunPricingAndPromotionsWhenBuyerAddsToCart() {
        // Arrange
        // Create a cart
        CartExtension.Cart cart = CartExtension.CartTestUtil.createCart();

        // Set up BuyerActions as if the Buyer has added an item to cart
        CartExtension.BuyerActionsMock buyerActions = new CartExtension.BuyerActionsMock();
        buyerActions.setCartItemChanged(true);

        // Create orchestrator request, with empty BuyerActionDetails (no optimizations will be applied in calculators)
        CartExtension.CartCalculateOrchestratorRequest request = new CartExtension.CartCalculateOrchestratorRequest(
            cart, buyerActions, CartExtension.OptionalBuyerActionDetails.empty());

        final CartCalculateExecutorForUnitTest executor = new CartCalculateExecutorForUnitTest();
        CartCalculateSample cartCalculateSample = new CartCalculateSample(executor);

        Test.startTest();

        // Act
        cartCalculateSample.calculate(request);
        Test.stopTest();

        // Assert
        // Verify that no CVO was created
        CartExtension.CartValidationOutputList cartValidationOutputs = cart.getCartValidationOutputs();
        System.assertEquals(0, cartValidationOutputs.size());

        // Verify that the pricing and promotions calculators made changes
        System.assert(cart.getName().contains('CartRepricedWithEstimate'));
        System.assert(cart.getName().contains('PromotionsRecalculated'));
        System.assert(!cart.getName().contains('InventoryChecked'));
        System.assert(!cart.getName().contains('ShippingRecalculated'));
        System.assert(!cart.getName().contains('TaxesRecalculated'));
        System.assert(!cart.getName().contains('PostShippingCompleted'));
    }

    @IsTest
    public static void shouldRunPricingPromotionsAndInventoryWhenBuyerStartsCheckout() {
        // Arrange
        // Create a cart with CartStatus set to CHECKOUT
        Schema.Account testAccount = new Schema.Account(Name=ACCOUNT_NAME);
        insert testAccount;

        Schema.WebStore testWebStore = new Schema.WebStore(Name=WEBSTORE_NAME);
        insert testWebStore;

        Schema.Account account = [SELECT Id FROM Account WHERE Name=:ACCOUNT_NAME LIMIT 1];
        Schema.WebStore webStore = [SELECT Id FROM WebStore WHERE Name=:WEBSTORE_NAME LIMIT 1];

        Schema.WebCart testCart = new WebCart(Name=CART_NAME, WebStoreId=webStore.Id, AccountId=account.Id, Status=CartExtension.CartStatusEnum.CHECKOUT.name());
        insert testCart;

        Schema.WebCart webCart = [SELECT Id FROM WebCart WHERE Name=:CART_NAME LIMIT 1];
        Schema.CartDeliveryGroup testDeliveryGroup = new Schema.CartDeliveryGroup(Name=DELIVERYGROUP_NAME, CartId=webCart.Id);
        insert testDeliveryGroup;

        Schema.CartDeliveryGroup deliveryGroup = [SELECT Id FROM CartDeliveryGroup WHERE Name=:DELIVERYGROUP_NAME LIMIT 1];
        Schema.CartItem testCartItem = new Schema.CartItem(Name=CARTITEM_NAME, CartId=webCart.Id, CartDeliveryGroupId=deliveryGroup.Id);
        insert testCartItem;

        CartExtension.Cart cart = CartExtension.CartTestUtil.getCart(webCart.Id);

        // Set up BuyerActions as if the Buyer has started Checkout
        final boolean isCheckoutStarted = true;
        CartExtension.BuyerActionsMock buyerActions = new CartExtension.BuyerActionsMock();
        buyerActions.setCheckoutStarted(isCheckoutStarted);

        // Set up BuyerActionDetails as if the Buyer has started Checkout
        CartExtension.BuyerActionDetails buyerActionDetails = new CartExtension.BuyerActionDetails.Builder().withCheckoutStarted(isCheckoutStarted).build();

        // Create orchestrator request
        CartExtension.CartCalculateOrchestratorRequest request = new CartExtension.CartCalculateOrchestratorRequest(
            cart, buyerActions, CartExtension.OptionalBuyerActionDetails.of(buyerActionDetails));

        final CartCalculateExecutorForUnitTest executor = new CartCalculateExecutorForUnitTest();
        CartCalculateSample cartCalculateSample = new CartCalculateSample(executor);

        Test.startTest();

        // Act
        cartCalculateSample.calculate(request);
        Test.stopTest();

        // Assert
        // Verify that no CVO was created
        CartExtension.CartValidationOutputList cartValidationOutputs = cart.getCartValidationOutputs();
        System.assertEquals(0, cartValidationOutputs.size());

        // Verify that the pricing, promotions, and inventory calculators made changes
        System.assert(cart.getName().contains('CartRepricedWithExternalCallout'));
        System.assert(cart.getName().contains('PromotionsRecalculated'));
        System.assert(cart.getName().contains('InventoryChecked'));
        System.assert(!cart.getName().contains('ShippingRecalculated'));
        System.assert(!cart.getName().contains('TaxesRecalculated'));
        System.assert(!cart.getName().contains('PostShippingCompleted'));
    }

    @IsTest
    public static void shouldRunShippingTaxesAndPostShippingWhenBuyerUpdatesShippingAddress() {
        // Arrange
        // Create a cart
        CartExtension.Cart cart = CartExtension.CartTestUtil.createCart();

        // Set up BuyerActions as if the Buyer has updated their shipping address
        CartExtension.BuyerActionsMock buyerActions = new CartExtension.BuyerActionsMock();
        buyerActions.setDeliveryGroupChanged(true);

        // Create orchestrator request, with empty BuyerActionDetails (no optimizations will be applied in calculators)
        CartExtension.CartCalculateOrchestratorRequest request = new CartExtension.CartCalculateOrchestratorRequest(
            cart, buyerActions, CartExtension.OptionalBuyerActionDetails.empty());

        final CartCalculateExecutorForUnitTest executor = new CartCalculateExecutorForUnitTest();
        CartCalculateSample cartCalculateSample = new CartCalculateSample(executor);

        Test.startTest();

        // Act
        cartCalculateSample.calculate(request);
        Test.stopTest();

        // Assert
        // Verify that no CVO was created
        CartExtension.CartValidationOutputList cartValidationOutputs = cart.getCartValidationOutputs();
        System.assertEquals(0, cartValidationOutputs.size());

        // Verify that the shipping, taxes, and post shipping calculators made changes
        System.assert(!cart.getName().contains('CartRepriced'));
        System.assert(!cart.getName().contains('PromotionsRecalculated'));
        System.assert(!cart.getName().contains('InventoryChecked'));
        System.assert(cart.getName().contains('ShippingRecalculated'));
        System.assert(cart.getName().contains('TaxesRecalculated'));
        System.assert(cart.getName().contains('PostShippingCompleted'));
    }

    @IsTest
    public static void shouldRunPostShippingAndTaxesWhenBuyerSelectsDeliveryMethod() {
        // Arrange
        // Create a cart
        CartExtension.Cart cart = CartExtension.CartTestUtil.createCart();

        // Set up BuyerActions as if the Buyer selected a Delivery Method
        CartExtension.BuyerActionsMock buyerActions = new CartExtension.BuyerActionsMock();
        buyerActions.setDeliveryMethodSelected(true);

        // Create orchestrator request, with empty BuyerActionDetails (no optimizations will be applied in calculators)
        CartExtension.CartCalculateOrchestratorRequest request = new CartExtension.CartCalculateOrchestratorRequest(
            cart, buyerActions, CartExtension.OptionalBuyerActionDetails.empty());

        final CartCalculateExecutorForUnitTest executor = new CartCalculateExecutorForUnitTest();
        CartCalculateSample cartCalculateSample = new CartCalculateSample(executor);

        Test.startTest();

        // Act
        cartCalculateSample.calculate(request);
        Test.stopTest();

        // Assert
        // Verify that no CVO was created
        CartExtension.CartValidationOutputList cartValidationOutputs = cart.getCartValidationOutputs();
        System.assertEquals(0, cartValidationOutputs.size());

        // Verify that the taxes and post shipping calculators made changes
        System.assert(!cart.getName().contains('CartRepriced'));
        System.assert(!cart.getName().contains('PromotionsRecalculated'));
        System.assert(!cart.getName().contains('InventoryChecked'));
        System.assert(!cart.getName().contains('ShippingRecalculated'));
        System.assert(cart.getName().contains('TaxesRecalculated'));
        System.assert(cart.getName().contains('PostShippingCompleted'));
    }

    @IsTest
    public static void shouldRunPromotionsWhenBuyerAddsCoupon() {
        // Arrange
        // Create a cart
        CartExtension.Cart cart = CartExtension.CartTestUtil.createCart();

        // Set up BuyerActions as if the Buyer added a coupon
        CartExtension.BuyerActionsMock buyerActions = new CartExtension.BuyerActionsMock();
        buyerActions.setCouponChanged(true);

        // Create orchestrator request, with empty BuyerActionDetails (no optimizations will be applied in calculators)
        CartExtension.CartCalculateOrchestratorRequest request = new CartExtension.CartCalculateOrchestratorRequest(
            cart, buyerActions, CartExtension.OptionalBuyerActionDetails.empty());

        final CartCalculateExecutorForUnitTest executor = new CartCalculateExecutorForUnitTest();
        CartCalculateSample cartCalculateSample = new CartCalculateSample(executor);

        Test.startTest();

        // Act
        cartCalculateSample.calculate(request);
        Test.stopTest();

        // Assert
        // Verify that no CVO was created
        CartExtension.CartValidationOutputList cartValidationOutputs = cart.getCartValidationOutputs();
        System.assertEquals(0, cartValidationOutputs.size());

        // Verify that the promotions calculator made changes
        System.assert(!cart.getName().contains('CartRepriced'));
        System.assert(cart.getName().contains('PromotionsRecalculated'));
        System.assert(!cart.getName().contains('InventoryChecked'));
        System.assert(!cart.getName().contains('ShippingRecalculated'));
        System.assert(!cart.getName().contains('TaxesRecalculated'));
        System.assert(!cart.getName().contains('PostShippingCompleted'));
    }
}