@isTest
public class InventoryCartCalculatorSampleTest {
    
	private static final String CART_NAME = 'My Cart';
    private static final String ACCOUNT_NAME = 'My Account';
    private static final String WEBSTORE_NAME = 'My WebStore';
    private static final String DELIVERYGROUP_NAME = 'My Delivery Group';
    private static final String CART_ITEM1_NAME = 'My Cart Item 1';
    private static final String CART_ITEM2_NAME = 'My Cart Item 2';
    private static final String CART_ITEM3_NAME = 'My Cart Item 3';
    private static final String SKU1_NAME = 'My SKU 1';
    private static final String SKU2_NAME = 'My SKU 2';
    private static final String SKU_RED_SHIRT = 'SKU_RED_SHIRT';
    private static final String SKU_RED_SHIRT_MESSAGE = 'Apologies for the inconvenience, but there may be a slight delay in the shipping of SKU_RED_SHIRT'; 

    @IsTest
    public static void testWithSkuRedShirtNotInCart() {
      
         // Arrange
         CartExtension.Cart cart = arrangeAndLoadCartWithSpecifiedStatusAndThreeItems(CartExtension.CartStatusEnum.CHECKOUT, false);
         InventoryCartCalculatorSample calculator = new InventoryCartCalculatorSample(new DefaultInventoryCartCalculatoMockExecutor());

        Test.startTest();
        
        // Act
        calculator.calculate(new CartExtension.CartCalculateCalculatorRequest(cart, CartExtension.OptionalBuyerActionDetails.empty()));
        
        Test.stopTest();

        // Assert
        assertNoCartValidationOutputs(cart, 0);

        
    }
    
    @IsTest
    public static void testWithSkuRedShirtInCart() {
      
         // Arrange
         CartExtension.Cart cart = arrangeAndLoadCartWithSpecifiedStatusAndThreeItems(CartExtension.CartStatusEnum.CHECKOUT, true);
         InventoryCartCalculatorSample calculator = new InventoryCartCalculatorSample(new DefaultInventoryCartCalculatoMockExecutor());

        Test.startTest();
        
        // Act
        calculator.calculate(new CartExtension.CartCalculateCalculatorRequest(cart, CartExtension.OptionalBuyerActionDetails.empty()));
        
        Test.stopTest();

        // Assert
        assertNoCartValidationOutputs(cart, 1);

        
    }
  
    
     /**
     * @description Sample mock executor. Stubs result of default pricing calculator
     */
    public class DefaultInventoryCartCalculatoMockExecutor extends CartExtension.CartCalculateExecutorMock {

        /**
         * @description This constructor should only be exposed to customers in a test context
         */
        public DefaultInventoryCartCalculatoMockExecutor() {}

        public override void defaultInventory(CartExtension.CartCalculateCalculatorRequest request) {
            // avoid the call to the implementation
            return;              
        }
        
    }
    
    private static CartExtension.Cart arrangeAndLoadCartWithSpecifiedStatusAndThreeItems(CartExtension.CartStatusEnum cartStatus, boolean ignoreRedShirtSku) {
        Id cartId = arrangeCartWithSpecifiedStatus(cartStatus);
        arrangeThreeCartItems(cartId, ignoreRedShirtSku);
        return CartExtension.CartTestUtil.getCart(cartId);
    }
    
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

    private static List<ID> arrangeThreeCartItems(ID cartId, Boolean ignoreRedShirtSku) {
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
            SKU = SKU_RED_SHIRT,
            Type = CartExtension.SalesItemTypeEnum.PRODUCT.name());

        if (ignoreRedShirtSku) {
            insert cartItem3;
        } 

        if (ignoreRedShirtSku) {
            return new List<ID>{cartItem1.Id, cartItem2.Id};
        } else {
            return new List<ID>{cartItem1.Id, cartItem2.Id, cartItem3.Id};
        }
        
    }

    private static void assertNoCartValidationOutputs(CartExtension.Cart cart, Integer expectedCVOCount) {
        String errorString = '';
        Iterator<CartExtension.CartValidationOutput> cvoIterator = cart.getCartValidationOutputs().iterator();
        while (cvoIterator.hasNext()) {
            errorString += cvoIterator.next().getMessage() ;
        }
        Assert.areEqual(expectedCVOCount, cart.getCartValidationOutputs().size(), 'No CartValidationOutputs expected, but was: ' + errorString);
        
        if (expectedCVOCount == 1) {
			Assert.areEqual(SKU_RED_SHIRT_MESSAGE, errorString, SKU_RED_SHIRT_MESSAGE + ' expected, but was: ' + errorString);
        }
    }
}