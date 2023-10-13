/**
 * @description A Sample unit test for EstimatedActualPricingCalculator.
 */
@IsTest
public class EstimatedActualPricingCalculatorTest {

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
    public static void shouldEstimatePricesUsingDefaultServiceWhenCartActive() {
        // Arrange
        CartExtension.Cart cart = arrangeAndLoadCartWithSpecifiedStatusAndThreeItems(CartExtension.CartStatusEnum.ACTIVE);
        // construct our calculator with mocked executor that stubs behavior of super.calculate()
        EstimatedActualPricingCalculator calculator = new EstimatedActualPricingCalculator(new DefaultPricingMockExecutor());

        // Act
        Test.startTest();
        calculator.calculate(new CartExtension.CartCalculateCalculatorRequest(cart, CartExtension.OptionalBuyerActionDetails.empty()));
        Test.stopTest();

        // Assert
        assertNoCartValidationOutputs(cart);
        assertCartItemPrices(cart, SKU1_NAME, ESTIMATED_PRICE, SKU2_NAME, ESTIMATED_PRICE, SKU3_NAME, ESTIMATED_PRICE);
    }

    @IsTest
    public static void shouldPriceItemsUsingExternalServiceWhenCheckout() {
        // Arrange
        CartExtension.Cart cart = arrangeAndLoadCartWithSpecifiedStatusAndThreeItems(CartExtension.CartStatusEnum.CHECKOUT);
        // mock http callout to 3rd party service
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());
        // construct our calculator in "http callout enabled" mode
        EstimatedActualPricingCalculator calculator = new EstimatedActualPricingCalculator(True, False);

        // Act
        Test.startTest();
        calculator.calculate(new CartExtension.CartCalculateCalculatorRequest(cart, CartExtension.OptionalBuyerActionDetails.empty()));
        Test.stopTest();

        // Assert
        assertNoCartValidationOutputs(cart);
        assertCartItemPrices(cart, SKU1_NAME, ACTUAL_PRICE_SKU1, SKU2_NAME, ACTUAL_PRICE_SKU2, SKU3_NAME, ACTUAL_PRICE_SKU3);
    }

    @IsTest
    public static void shouldCreateErrorMessageWhenExternalServiceIsDown() {
        // Arrange
        CartExtension.Cart cart = arrangeAndLoadCartWithSpecifiedStatusAndThreeItems(CartExtension.CartStatusEnum.CHECKOUT);
        // mock failed http callout
        Test.setMock(HttpCalloutMock.class, new FailedCalloutMock());
        // construct our calculator in "http callout enabled" mode
        EstimatedActualPricingCalculator calculator = new EstimatedActualPricingCalculator(True, False);

        // Act
        Test.startTest();
        calculator.calculate(new CartExtension.CartCalculateCalculatorRequest(cart, CartExtension.OptionalBuyerActionDetails.empty()));
        Test.stopTest();

        // Assert
        Assert.areEqual(1, cart.getCartValidationOutputs().size());
        Assert.areEqual(EstimatedActualPricingCalculator.GENERAL_ERROR_MESSAGE_EN,
                        cart.getCartValidationOutputs().iterator().next().getMessage());
        assertCartItemPrices(cart, SKU1_NAME, Null, SKU2_NAME, Null, SKU3_NAME, Null);
    }

    @IsTest
    public static void shouldPriceOneItemWhenBuyerActionDetailsProvided() {
        // Arrange
        CartExtension.Cart cart = arrangeAndLoadCartWithSpecifiedStatusAndThreeItems(CartExtension.CartStatusEnum.CHECKOUT);
        EstimatedActualPricingCalculator calculator = new EstimatedActualPricingCalculator();
        // Arrange buyer updated cart item with SKU3_NAME
        List<CartExtension.CartItemChange> changedCartItems = new List<CartExtension.CartItemChange>();
        Iterator<CartExtension.CartItem> cartItemsIterator = cart.getCartItems().iterator();
        while (cartItemsIterator.hasNext()) {
            CartExtension.CartItem cartItem = cartItemsIterator.next();
            if (cartItem.getSku() == SKU3_NAME) {
                changedCartItems.add(
                        new CartExtension.CartItemChange.Builder()
                                .withChangedItem(CartExtension.OptionalCartItem.of(cartItem))
                                .withAdded(true)
                                .build());
            }
        }
        CartExtension.BuyerActionDetails buyerActionDetails = new CartExtension.BuyerActionDetails.Builder()
                                                                    .withCartItemChanges(changedCartItems).build();

        // Act
        Test.startTest();
        calculator.calculate(new CartExtension.CartCalculateCalculatorRequest(cart, CartExtension.OptionalBuyerActionDetails.of(buyerActionDetails)));
        Test.stopTest();

        // Assert
        assertNoCartValidationOutputs(cart);
        assertCartItemPrices(cart, SKU1_NAME, Null, SKU2_NAME, Null, SKU3_NAME, ACTUAL_PRICE_SKU3);
    }

    @IsTest
    public static void shouldClearExistingErrorWhenSuccessfulRepricing() {
        // Arrange
        Id cartId = arrangeCartWithSpecifiedStatus(CartExtension.CartStatusEnum.CHECKOUT);
        List<ID> cartItemIds = arrangeThreeCartItems(cartId);
        insert new CartValidationOutput(CartId = cartId, Level = 'Error',
                                        Message = EstimatedActualPricingCalculator.GENERAL_ERROR_MESSAGE_EN,
                                        Name = 'My Error CVO', RelatedEntityId = cartId, Type = 'Pricing');
        insert new CartValidationOutput(CartId = cartId, Level = 'Error',
                                        Message = EstimatedActualPricingCalculator.GENERAL_ERROR_MESSAGE_EN,
                                        Name = 'My Error CVO', RelatedEntityId = cartItemIds[2], Type = 'Pricing');
        CartExtension.Cart cart = CartExtension.CartTestUtil.getCart(cartId);
        EstimatedActualPricingCalculator calculator = new EstimatedActualPricingCalculator();

        // Act
        Test.startTest();
        calculator.calculate(new CartExtension.CartCalculateCalculatorRequest(cart, CartExtension.OptionalBuyerActionDetails.empty()));
        Test.stopTest();

        // Assert
        assertNoCartValidationOutputs(cart);
        assertCartItemPrices(cart, SKU1_NAME, ACTUAL_PRICE_SKU1, SKU2_NAME, ACTUAL_PRICE_SKU2, SKU3_NAME, ACTUAL_PRICE_SKU3);
    }

    @IsTest
    public static void shouldNotClearExistingErrorOfOtherTypesWhenRepricing() {
        // Arrange
        Id cartId = arrangeCartWithSpecifiedStatus(CartExtension.CartStatusEnum.CHECKOUT);
        List<ID> cartItemIds = arrangeThreeCartItems(cartId);
        insert new CartValidationOutput(CartId = cartId, Level = 'Error',
                                        Message = EstimatedActualPricingCalculator.GENERAL_ERROR_MESSAGE_EN,
                                        Name = 'My Error CVO', RelatedEntityId = cartId, Type = 'Shipping');
        CartExtension.Cart cart = CartExtension.CartTestUtil.getCart(cartId);
        EstimatedActualPricingCalculator calculator = new EstimatedActualPricingCalculator();

        // Act
        Test.startTest();
        calculator.calculate(new CartExtension.CartCalculateCalculatorRequest(cart, CartExtension.OptionalBuyerActionDetails.empty()));
        Test.stopTest();

        // Assert
        Iterator<CartExtension.CartValidationOutput> cvoIterator = cart.getCartValidationOutputs().iterator();
        Integer pricingCVOCounter = 0;
        Integer otherTypesCVOCounter = 0;
        while (cvoIterator.hasNext()) {
            if (cvoIterator.next().getType() == CartExtension.CartValidationOutputTypeEnum.PRICING) {
                pricingCVOCounter++;
            } else {
                otherTypesCVOCounter++;
            }
        }
        Assert.areEqual(0, pricingCVOCounter);
        Assert.areEqual(1, otherTypesCVOCounter);
        assertCartItemPrices(cart, SKU1_NAME, ACTUAL_PRICE_SKU1, SKU2_NAME, ACTUAL_PRICE_SKU2, SKU3_NAME, ACTUAL_PRICE_SKU3);
    }

    @IsTest
    public static void shouldNotClearExistingErrorForAnotherItemWhenBuyerActionDetailsProvided() {
        // Arrange
        Id cartId = arrangeCartWithSpecifiedStatus(CartExtension.CartStatusEnum.CHECKOUT);
        List<ID> cartItemIds = arrangeThreeCartItems(cartId);
        insert new CartValidationOutput(CartId = cartId, Level = 'Error',
                                        Message = EstimatedActualPricingCalculator.GENERAL_ERROR_MESSAGE_EN,
                                        Name = 'My Error CVO', RelatedEntityId = cartItemIds[2], Type = 'Pricing');
        CartExtension.Cart cart = CartExtension.CartTestUtil.getCart(cartId);
        // Arrange buyer updated cart item with SKU3_NAME
        List<CartExtension.CartItemChange> changedCartItems = new List<CartExtension.CartItemChange>();
        Iterator<CartExtension.CartItem> cartItemsIterator = cart.getCartItems().iterator();
        while (cartItemsIterator.hasNext()) {
            CartExtension.CartItem cartItem = cartItemsIterator.next();
            if (cartItem.getSku() == SKU1_NAME) {
                changedCartItems.add(
                        new CartExtension.CartItemChange.Builder()
                                .withChangedItem(CartExtension.OptionalCartItem.of(cartItem))
                                .withAdded(true)
                                .build());
            }
        }
        CartExtension.BuyerActionDetails buyerActionDetails = new CartExtension.BuyerActionDetails.Builder()
                                                                    .withCartItemChanges(changedCartItems).build();
        EstimatedActualPricingCalculator calculator = new EstimatedActualPricingCalculator();

        // Act
        Test.startTest();
        calculator.calculate(new CartExtension.CartCalculateCalculatorRequest(cart, CartExtension.OptionalBuyerActionDetails.of(buyerActionDetails)));
        Test.stopTest();

        // Assert
        Assert.areEqual(1, cart.getCartValidationOutputs().size());
        CartExtension.CartValidationOutput cvo = cart.getCartValidationOutputs().iterator().next();
        Assert.areEqual(cartItemIds[2], cvo.getRelatedEntityId());
        assertCartItemPrices(cart, SKU1_NAME, ACTUAL_PRICE_SKU1, SKU2_NAME, Null, SKU3_NAME, Null);
    }

    @IsTest
    public static void shouldClearExistingErrorForChangedItemWhenBuyerActionDetailsProvided() {
        // Arrange
        Id cartId = arrangeCartWithSpecifiedStatus(CartExtension.CartStatusEnum.CHECKOUT);
        List<ID> cartItemIds = arrangeThreeCartItems(cartId);
        insert new CartValidationOutput(CartId = cartId, Level = 'Error',
                                        Message = EstimatedActualPricingCalculator.GENERAL_ERROR_MESSAGE_EN,
                                        Name = 'My Error CVO', RelatedEntityId = cartItemIds[0], Type = 'Pricing');
        CartExtension.Cart cart = CartExtension.CartTestUtil.getCart(cartId);
        // Arrange buyer updated cart item with SKU3_NAME
        List<CartExtension.CartItemChange> changedCartItems = new List<CartExtension.CartItemChange>();
        Iterator<CartExtension.CartItem> cartItemsIterator = cart.getCartItems().iterator();
        while (cartItemsIterator.hasNext()) {
            CartExtension.CartItem cartItem = cartItemsIterator.next();
            if (cartItem.getSku() == SKU1_NAME) {
                changedCartItems.add(
                        new CartExtension.CartItemChange.Builder()
                                .withChangedItem(CartExtension.OptionalCartItem.of(cartItem))
                                .withAdded(true)
                                .build());
            }
        }
        CartExtension.BuyerActionDetails buyerActionDetails = new CartExtension.BuyerActionDetails.Builder()
                                                                    .withCartItemChanges(changedCartItems).build();
        EstimatedActualPricingCalculator calculator = new EstimatedActualPricingCalculator();

        // Act
        Test.startTest();
        calculator.calculate(new CartExtension.CartCalculateCalculatorRequest(cart, CartExtension.OptionalBuyerActionDetails.of(buyerActionDetails)));
        Test.stopTest();

        // Assert
        assertNoCartValidationOutputs(cart);
        assertCartItemPrices(cart, SKU1_NAME, ACTUAL_PRICE_SKU1, SKU2_NAME, Null, SKU3_NAME, Null);
    }

    @IsTest
    public static void shouldPopulateErrorForCartItemWhenNoPricingForCartItem() {
        // Arrange
        Id cartId = arrangeCartWithSpecifiedStatus(CartExtension.CartStatusEnum.CHECKOUT);
        List<ID> cartItemIds = arrangeThreeCartItems(cartId);
        CartExtension.Cart cart = CartExtension.CartTestUtil.getCart(cartId);
        // mock http callout
        Test.setMock(HttpCalloutMock.class, new Sku1PriceCalloutMock());
        // construct our calculator in "http callout enabled" mode
        EstimatedActualPricingCalculator calculator = new EstimatedActualPricingCalculator(True, False);

        // Act
        Test.startTest();
        calculator.calculate(new CartExtension.CartCalculateCalculatorRequest(cart, CartExtension.OptionalBuyerActionDetails.empty()));
        Test.stopTest();

        // Assert
        Assert.areEqual(2, cart.getCartValidationOutputs().size());
        Iterator<CartExtension.CartValidationOutput> cvoIterator = cart.getCartValidationOutputs().iterator();
        Boolean hasErrorForSku2 = False;
        Boolean hasErrorForSku3 = False;
        while (cvoIterator.hasNext()) {
            CartExtension.CartValidationOutput cvo = cvoIterator.next();
            String expected = Null;
            if (cvo.getRelatedEntityId() == cartItemIds[1]) {
                expected = String.format(EstimatedActualPricingCalculator.PRICING_FAILED_FOR_CART_ITEM_ERROR_MESSAGE_EN,
                                            new List<String>{SKU2_NAME});
                hasErrorForSku2 = True;
            } else if (cvo.getRelatedEntityId() == cartItemIds[2]) {
                expected = String.format(EstimatedActualPricingCalculator.PRICING_FAILED_FOR_CART_ITEM_ERROR_MESSAGE_EN,
                                            new List<String>{SKU3_NAME});
                hasErrorForSku3 = True;
            }
            Assert.areEqual(expected, cvo.getMessage());
        }
        Assert.isTrue(hasErrorForSku2);
        Assert.isTrue(hasErrorForSku3);
        assertCartItemPrices(cart, SKU1_NAME, ACTUAL_PRICE_SKU1, SKU2_NAME, Null, SKU3_NAME, Null);
    }

    @IsTest
    public static void shouldPopulateFrenchErrorMessageWhenBuyerLocaleIsFr() {
        // Arrange
        CartExtension.Cart cart = arrangeAndLoadCartWithSpecifiedStatusAndThreeItems(CartExtension.CartStatusEnum.CHECKOUT);
        // mock failed http callout
        Test.setMock(HttpCalloutMock.class, new FailedCalloutMock());
        // construct our calculator in "http callout enabled" mode
        EstimatedActualPricingCalculator calculator = new EstimatedActualPricingCalculator(True, False);

        // Arrange user with another locale
        String uniqueUserName = 'buyer' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
                            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='fr',
                            LocaleSidKey='fr', ProfileId = p.Id,
                            TimeZoneSidKey='America/Los_Angeles',
                            UserName=uniqueUserName);

        // Act as french user
        System.runAs(u) {
            Test.startTest();
            calculator.calculate(new CartExtension.CartCalculateCalculatorRequest(cart, CartExtension.OptionalBuyerActionDetails.empty()));
            Test.stopTest();
        }

        // Assert
        Assert.areEqual(1, cart.getCartValidationOutputs().size());
        Assert.areEqual(EstimatedActualPricingCalculator.GENERAL_ERROR_MESSAGE_FR,
                      cart.getCartValidationOutputs().iterator().next().getMessage());
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

    private static void assertNoCartValidationOutputs(CartExtension.Cart cart) {
        String errorString = '';
        Iterator<CartExtension.CartValidationOutput> cvoIterator = cart.getCartValidationOutputs().iterator();
        while (cvoIterator.hasNext()) {
            errorString += cvoIterator.next().getMessage() + '; ';
        }
        Assert.areEqual(0, cart.getCartValidationOutputs().size(), 'No CartValidationOutputs expected, but was: ' + errorString);
    }

    private static void assertCartItemPrices(CartExtension.Cart cart, String sku1, Decimal price1, String sku2,
                                                Decimal price2, String sku3, Decimal price3) {
        Iterator<CartExtension.CartItem> iterator = cart.getCartItems().iterator();
        Boolean hasSku1 = False;
        Boolean hasSku2 = False;
        Boolean hasSku3 = False;
        while (iterator.hasNext()) {
            CartExtension.CartItem item = iterator.next();
            String sku = item.getSku();
            if (sku == sku1) {
                hasSku1 = True;
                Assert.areEqual(price1, item.getListPrice());
            }
            if (sku == sku2) {
                hasSku2 = True;
                Assert.areEqual(price2, item.getListPrice());
            }
            if (sku == sku3) {
                hasSku3 = True;
                Assert.areEqual(price3, item.getListPrice());
            }
        }
        Assert.isTrue(hasSku1);
        Assert.isTrue(hasSku2);
        Assert.isTrue(hasSku3);
    }

    /**
     * @description Sample mock executor. Stubs result of default pricing calculator
     */
    public class DefaultPricingMockExecutor extends CartExtension.CartCalculateExecutorMock {

        /**
         * @description This constructor should only be exposed to customers in a test context
         */
        public DefaultPricingMockExecutor() {}

        public override void defaultPrices(CartExtension.CartCalculateCalculatorRequest request) {
            Iterator<CartExtension.CartItem> iterator = request.getCart().getCartItems().iterator();
            while (iterator.hasNext()) {
                CartExtension.CartItem item = iterator.next();
                item.setListPrice(ESTIMATED_PRICE);
            }
        }
    }

    public class SuccessCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            String endpoint = req.getEndpoint();
            // expected endpoint https://example.com/get-sales-prices?skus='
            String urlParams = endpoint.split('\\?')[1];
            String skuString = urlParams.split('skus=')[1];
            List<String> skus = (List<String>) JSON.deserialize(skuString, List<String>.class);
            Map<String, Decimal> prices = new Map<String, Decimal>();
            for (String sku: skus) {
                String decodedSku = EncodingUtil.urlDecode(sku, 'UTF-8');
                if (decodedSku == SKU1_NAME) {
                    prices.put(SKU1_NAME, ACTUAL_PRICE_SKU1);
                }
                if (decodedSku == SKU2_NAME) {
                    prices.put(SKU2_NAME, ACTUAL_PRICE_SKU2);
                }
                if (decodedSku == SKU3_NAME) {
                    prices.put(SKU3_NAME, ACTUAL_PRICE_SKU3);
                }
            }
            String body = JSON.serialize(prices);
            HttpResponse res = new HttpResponse();
            res.setBody(body);
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            return res;
        }
    }

    public class Sku1PriceCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            Map<String, Decimal> prices = new Map<String, Decimal>();
            prices.put(SKU1_NAME, ACTUAL_PRICE_SKU1);
            String body = JSON.serialize(prices);
            HttpResponse res = new HttpResponse();
            res.setBody(body);
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            return res;
        }
    }

    public class FailedCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(500);
            return res;
        }
    }
}
