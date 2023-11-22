/**
* @description A Sample unit test for PricingCalculatorSample.
*/
@IsTest
public class PricingCalculatorSampleTest {

    private static final String CART_NAME = 'My Cart';
    private static final String ACCOUNT_NAME = 'My Account';
    private static final String WEBSTORE_NAME = 'My WebStore';
    private static final String DELIVERYGROUP_NAME = 'My Delivery Group';
    private static final String CART_ITEM1_NAME = 'My Cart Item 1';
    private static final String CART_ITEM2_NAME = 'My Cart Item 2';
    private static String SKU1_NAME = 'My SKU 1';
    private static String SKU2_NAME = 'My SKU 2';
    private static final Decimal ACTUAL_PRICE_SKU1 = 100.00;
    private static final Decimal ACTUAL_PRICE_SKU2 = 200.00;

    @IsTest
    public static void testStaticMethodReturnValidReponse() {
        // Arrange
        CartExtension.Cart cart = arrangeAndLoadCartWithTwoItems(CartExtension.CartStatusEnum.CHECKOUT);

        // Act
        Test.startTest();
        PricingCalculatorSample calculator =  new PricingCalculatorSample();
        calculator.calculate(new CartExtension.CartCalculateCalculatorRequest(cart, CartExtension.OptionalBuyerActionDetails.empty()));
        Test.stopTest();

        // Assert
        assertNoCartValidationOutputs(cart);
        assertCartItemPrices(cart, 10, 20, 10, 20);
    }

    @IsTest
    public static void testPriceOneItemWhenBuyerActionDetailsProvided() {
        // Arrange
        CartExtension.Cart cart = arrangeAndLoadCartWithTwoItems(CartExtension.CartStatusEnum.CHECKOUT);
        PricingCalculatorSample calculator =  new PricingCalculatorSample();
        // Arrange buyer updated cart item with SKU2_NAME
        List<CartExtension.CartItemChange> changedCartItems = new List<CartExtension.CartItemChange>();
        Iterator<CartExtension.CartItem> cartItemsIterator = cart.getCartItems().iterator();
        while (cartItemsIterator.hasNext()) {
            CartExtension.CartItem cartItem = cartItemsIterator.next();
            if (cartItem.getSku() == SKU2_NAME) {
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
        assertCartItemPrices(cart, null, null, 10, 20);
    }

    @IsTest
    public static void testClearExistingErrorWhenSuccessfulRepricing() {
        // Arrange
        Id cartId = arrangeCart(CartExtension.CartStatusEnum.CHECKOUT);
        List<ID> cartItemIds = arrangeTwoCartItems(cartId);
        insert new CartValidationOutput(CartId = cartId, Level = 'Error',
            Message = 'Something went wrong with pricing calculator',
                Name = 'My Error CVO', RelatedEntityId = cartId, Type = 'Pricing');

        CartExtension.Cart cart = CartExtension.CartTestUtil.getCart(cartId);
        PricingCalculatorSample calculator =  new PricingCalculatorSample();

        // Act
        Test.startTest();
        calculator.calculate(new CartExtension.CartCalculateCalculatorRequest(cart, CartExtension.OptionalBuyerActionDetails.empty()));
        Test.stopTest();

        // Assert
        assertNoCartValidationOutputs(cart);
        assertCartItemPrices(cart, 10, 20, 10, 20);
    }

    @IsTest
    public static void testNotClearExistingErrorOfOtherTypesWhenRepricing() {
        // Arrange
        Id cartId = arrangeCart(CartExtension.CartStatusEnum.CHECKOUT);
        List<ID> cartItemIds = arrangeTwoCartItems(cartId);
        insert new CartValidationOutput(CartId = cartId, Level = 'Error',
            Message = 'Something went wrong with shipping calculator',
                Name = 'My Error CVO', RelatedEntityId = cartId, Type = 'Shipping');
        CartExtension.Cart cart = CartExtension.CartTestUtil.getCart(cartId);
        PricingCalculatorSample calculator =  new PricingCalculatorSample();

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
        assertCartItemPrices(cart, 10, 20, 10, 20);
    }

    @IsTest
    public static void shouldPriceItemsUsingExternalService() {
        // Arrange
        CartExtension.Cart cart = arrangeAndLoadCartWithTwoItems(CartExtension.CartStatusEnum.CHECKOUT);
        // mock http callout to 3rd party service
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        // Act
        Test.startTest();
        PricingCalculatorSample calculator =  new PricingCalculatorSample(true);
        calculator.calculate(new CartExtension.CartCalculateCalculatorRequest(cart, CartExtension.OptionalBuyerActionDetails.empty()));
        Test.stopTest();

        // Assert
        assertNoCartValidationOutputs(cart);
        assertCartItemPrices(cart, 10, 20, 10, 20);
    }

    @IsTest
    public static void shouldCreateErrorMessageWhenExternalServiceIsDown() {

        // Arrange
        CartExtension.Cart cart = arrangeAndLoadCartWithTwoItems(CartExtension.CartStatusEnum.CHECKOUT);
        // mock failed http callout
        Test.setMock(HttpCalloutMock.class, new FailedCalloutMock());

        // Act
        Test.startTest();
        PricingCalculatorSample calculator =  new PricingCalculatorSample(true);
        calculator.calculate(new CartExtension.CartCalculateCalculatorRequest(cart, CartExtension.OptionalBuyerActionDetails.empty()));
        Test.stopTest();

        // Assert
        Assert.areEqual(1, cart.getCartValidationOutputs().size());
        Assert.areEqual('We are not able to process your cart. Please contact support.',
        cart.getCartValidationOutputs().iterator().next().getMessage());
        assertCartItemPrices(cart, null, null, null, null);
    }

    @IsTest
    public static void testDuplicateSkusReturnValidReponse() {
        // Arrange
        // Keep same sku for both products
        SKU2_NAME = 'My SKU 1';
        CartExtension.Cart cart = arrangeAndLoadCartWithTwoItems(CartExtension.CartStatusEnum.CHECKOUT);

        // Act
        Test.startTest();
        PricingCalculatorSample calculator =  new PricingCalculatorSample();
        calculator.calculate(new CartExtension.CartCalculateCalculatorRequest(cart, CartExtension.OptionalBuyerActionDetails.empty()));
        Test.stopTest();

        // Assert
        assertNoCartValidationOutputs(cart);
        assertCartItemPrices(cart, 10, 20, 10, 20);
        SKU2_NAME = 'My SKU 2';
    }

    /**
    * @description Create and return a WebCart with the specified status and 2 items.
    *
    * @param cartStatus The status of the cart.
    *
    * @return <<CartExtension.Cart>>
    */
    private static ID arrangeCart(CartExtension.CartStatusEnum cartStatus) {
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

    private static List<ID> arrangeTwoCartItems(ID cartId) {
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

    private static CartExtension.Cart arrangeAndLoadCartWithTwoItems(CartExtension.CartStatusEnum cartStatus) {
        Id cartId = arrangeCart(cartStatus);
        arrangeTwoCartItems(cartId);
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

    private static void assertCartItemPrices(CartExtension.Cart cart, Decimal listPrice1, Decimal totalPrice1, Decimal listPrice2, Decimal totalPrice2) {
        Iterator<CartExtension.CartItem> iterator = cart.getCartItems().iterator();
        Boolean hasSku1 = False;
        Boolean hasSku2 = False;
        Boolean hasSku3 = False;
        while (iterator.hasNext()) {
            CartExtension.CartItem item = iterator.next();
            String sku = item.getSku();
            if (sku == SKU1_NAME) {
                hasSku1 = True;
                Assert.areEqual(listPrice1, item.getListPrice());
                Assert.areEqual(totalPrice1, item.getTotalPrice());
            }
            if (sku == SKU2_NAME) {
                hasSku2 = True;
                Assert.areEqual(listPrice2, item.getListPrice());
                Assert.areEqual(totalPrice2, item.getTotalPrice());
            }
        }
        Assert.isTrue(hasSku1);
        Assert.isTrue(hasSku2);
    }

    public class SuccessCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            String endpoint = req.getEndpoint();
            // expected endpoint https://example.com/get-sales-prices?skus='
            String urlParams = endpoint.split('\\?')[1];
            String skuString = urlParams.split('skus=')[1];
            List<String> skus = (List<String>) JSON.deserialize(skuString, List<String>.class);
            Map<String, PricingDataFromExternalService> prices = new Map<String, PricingDataFromExternalService>();
            for (String sku: skus) {
                String decodedSku = EncodingUtil.urlDecode(sku, 'UTF-8');
                if (decodedSku == SKU1_NAME) {
                    prices.put(SKU1_NAME, new PricingDataFromExternalService(10,10,9,20,20));
                }
                if (decodedSku == SKU2_NAME) {
                    prices.put(SKU2_NAME, new PricingDataFromExternalService(10,10,9,20,20));
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

    public class FailedCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(500);
            return res;
        }
    }

    /**
    * Structure to store pricing data retrieved from external service. This class simplifies our
    * ability to access the data when storing it in Salesforce's CartItem.
    */
    class PricingDataFromExternalService {

        private Decimal unitPrice;
        private Decimal listPrice;
        private Decimal totalAdjustmentAmount;
        private Decimal totalListPrice;
        private Decimal totalPrice;

        public PricingDataFromExternalService() {
            unitPrice = 0.0;
            listPrice = 0.0;
            totalAdjustmentAmount = 0.0;
            totalListPrice = 0.0;
            totalPrice = 0.0;
        }

        public PricingDataFromExternalService(
        Decimal unitPriceObj,
        Decimal listPriceObj,
        Decimal totalAdjustmentAmountObj,
        Decimal totalListPriceObj,
        Decimal totalPriceObj ) {

            unitPrice = unitPriceObj;
            listPrice = listPriceObj;
            totalAdjustmentAmount = totalAdjustmentAmountObj;
            totalListPrice = TotalListPriceObj;
            totalPrice = totalPriceObj;
        }

        public Decimal getUnitPrice() {
            return unitPrice;
        }

        public Decimal getListPrice() {
            return listPrice;
        }

        public Decimal getTotalAdjustmentAmount() {
            return totalAdjustmentAmount;
        }

        public Decimal getTotalListPrice() {
            return totalListPrice;
        }

        public Decimal getTotalPrice() {
            return totalPrice;
        }
    }
}