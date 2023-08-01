/**
 * A Sample unit test for <<CartCalculate>>.
 */
@IsTest
public class CartCalculateSampleUnitTest {

    @IsTest
    public static void shouldRunPricingAndPromotionsWhenBuyerAddsToCart() {
        // Arrange
        // Create a cart
        CartExtension.Cart cart = CartExtension.CartTestUtil.createCart();

        // Set up BuyerActions as if the Buyer has added an item to cart
        CartExtension.BuyerActionsMock buyerActions = new CartExtension.BuyerActionsMock();
        buyerActions.setCartItemChanged(true);

        // Set up BuyerActionDetails as if the Buyer has added an item to cart
        final boolean isCheckoutStarted = false;
        CartExtension.BuyerActionDetails buyerActionDetails = new CartExtension.BuyerActionDetails(
            isCheckoutStarted,
            new List<CartExtension.CartDeliveryGroupChange>(),
            new List<CartExtension.CartItemChange>(),
            new List<CartExtension.CouponChange>());

        CartExtension.OptionalBuyerActionDetails optionalBuyerActionDetails = new CartExtension.OptionalBuyerActionDetails();
        optionalBuyerActionDetails.of(buyerActionDetails);

        CartExtension.CartCalculateOrchestratorRequest request = new CartExtension.CartCalculateOrchestratorRequest(cart, buyerActions, optionalBuyerActionDetails);

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
        System.assert(cart.getName().contains('CartRepriced'));
        System.assert(cart.getName().contains('PromotionsRecalculated'));
        System.assert(!cart.getName().contains('InventoryChecked'));
        System.assert(!cart.getName().contains('ShippingRecalculated'));
        System.assert(!cart.getName().contains('TaxesRecalculated'));
        System.assert(!cart.getName().contains('PostShippingCompleted'));
    }

    @IsTest
    public static void shouldRunPricingPromotionsAndInventoryWhenBuyerStartsCheckout() {
        // Arrange
        // Create a cart
        CartExtension.Cart cart = CartExtension.CartTestUtil.createCart();

        // Set up BuyerActions as if the Buyer has started Checkout
        CartExtension.BuyerActionsMock buyerActions = new CartExtension.BuyerActionsMock();
        buyerActions.setCheckoutStarted(true);

        // Set up BuyerActionDetails as if the Buyer has started Checkout
        final boolean isCheckoutStarted = true;
        CartExtension.BuyerActionDetails buyerActionDetails = new CartExtension.BuyerActionDetails(
            isCheckoutStarted,
            new List<CartExtension.CartDeliveryGroupChange>(),
            new List<CartExtension.CartItemChange>(),
            new List<CartExtension.CouponChange>());

        CartExtension.OptionalBuyerActionDetails optionalBuyerActionDetails = new CartExtension.OptionalBuyerActionDetails();
        optionalBuyerActionDetails.of(buyerActionDetails);

        CartExtension.CartCalculateOrchestratorRequest request = new CartExtension.CartCalculateOrchestratorRequest(cart, buyerActions, optionalBuyerActionDetails);

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
        System.assert(cart.getName().contains('CartRepriced'));
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

        // Set up BuyerActionDetails as if the Buyer has updated their shipping address
        final boolean isCheckoutStarted = false;
        CartExtension.BuyerActionDetails buyerActionDetails = new CartExtension.BuyerActionDetails(
            isCheckoutStarted,
            new List<CartExtension.CartDeliveryGroupChange>(),
            new List<CartExtension.CartItemChange>(),
            new List<CartExtension.CouponChange>());

        CartExtension.OptionalBuyerActionDetails optionalBuyerActionDetails = new CartExtension.OptionalBuyerActionDetails();
        optionalBuyerActionDetails.of(buyerActionDetails);

        CartExtension.CartCalculateOrchestratorRequest request = new CartExtension.CartCalculateOrchestratorRequest(cart, buyerActions, optionalBuyerActionDetails);

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

        // Set up BuyerActionDetails as if the Buyer selected a Delivery Method
        final boolean isCheckoutStarted = false;
        CartExtension.BuyerActionDetails buyerActionDetails = new CartExtension.BuyerActionDetails(
            isCheckoutStarted,
            new List<CartExtension.CartDeliveryGroupChange>(),
            new List<CartExtension.CartItemChange>(),
            new List<CartExtension.CouponChange>());

        CartExtension.OptionalBuyerActionDetails optionalBuyerActionDetails = new CartExtension.OptionalBuyerActionDetails();
        optionalBuyerActionDetails.of(buyerActionDetails);

        CartExtension.CartCalculateOrchestratorRequest request = new CartExtension.CartCalculateOrchestratorRequest(cart, buyerActions, optionalBuyerActionDetails);

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
}