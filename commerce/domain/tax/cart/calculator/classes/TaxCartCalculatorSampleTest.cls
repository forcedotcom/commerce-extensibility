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
    static void testCalculate_NoExternalService() {
        CartExtension.Cart cart = arrangeAndLoadCartWithSpecifiedStatusAndThreeItems(CartExtension.CartStatusEnum.ACTIVE);

        CartExtension.CartCalculateCalculatorRequest request = new CartExtension.CartCalculateCalculatorRequest(cart, CartExtension.OptionalBuyerActionDetails.empty());

        // Call the calculate method
        TaxCartCalculatorSample calculator = new TaxCartCalculatorSample();
        Test.startTest();
        calculator.calculate(request);
        Test.stopTest();
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
}
