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
    private static final String SKU3_NAME = 'My SKU 3';

    @IsTest
    public static void testNoCVOCartStatus() {
      
         // Arrange
         CartExtension.Cart cart = arrangeAndLoadCartWithSpecifiedStatusAndThreeItems(CartExtension.CartStatusEnum.ACTIVE);
         InventoryCartCalculatorSample calculator = new InventoryCartCalculatorSample(new DefaultInventoryCartCalculatoMockExecutor());

        Test.startTest();
        calculator.calculate(new CartExtension.CartCalculateCalculatorRequest(cart, CartExtension.OptionalBuyerActionDetails.empty()));
        Test.stopTest();

        // Assert
        assertNoCartValidationOutputs(cart, 0);

        
    }
    
    @IsTest
    public static void testCleanCVOCartStatus() {
      
         // Arrange
         CartExtension.Cart cart = arrangeAndLoadCartWithSpecifiedStatusAndThreeItems(CartExtension.CartStatusEnum.ACTIVE);
        
         InventoryCartCalculatorSample calculator = new InventoryCartCalculatorSample(new DefaultInventoryCartCalculatoMockExecutor());

        Test.startTest();
        calculator.calculate(new CartExtension.CartCalculateCalculatorRequest(cart, CartExtension.OptionalBuyerActionDetails.empty()));
        Test.stopTest();

        // Assert
        assertNoCartValidationOutputs(cart, 0);

        
    }

     @IsTest
    public static void testWithCVOCartStatus() {
      
         // Arrange
         CartExtension.Cart cart = arrangeAndLoadCartWithSpecifiedStatusAndThreeItems(CartExtension.CartStatusEnum.CHECKOUT);
         addCvoToCart(cart);
         InventoryCartCalculatorSample calculator = new InventoryCartCalculatorSample(new DefaultInventoryCartCalculatoMockExecutor());

        Test.startTest();
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
            
                        CartExtension.Cart cart = request.getCart();

           removeAllCVOsOfType(cart, CartExtension.CartValidationOutputTypeEnum.INVENTORY);

            Integer i = 0;
    
            CartExtension.CartItemList cartItemCollection = cart.getCartItems();
            Iterator<CartExtension.CartItem> cartItemCollectionIterator = cartItemCollection.iterator();
    
            while (cartItemCollectionIterator.hasNext()) {
                CartExtension.CartItem cartItem = cartItemCollectionIterator.next();
    
                if (cartItem.getType() == CartExtension.SalesItemTypeEnum.PRODUCT && i == 0) {
    
                    CartExtension.CartValidationOutput cvo = new CartExtension.CartValidationOutput(
                        CartExtension.CartValidationOutputTypeEnum.INVENTORY,
                        CartExtension.CartValidationOutputLevelEnum.ERROR);
                        cart.getCartValidationOutputs().add(cvo);
                }
                i = i + 1;
            }
        }
        
        private void removeAllCVOsOfType(CartExtension.Cart cart, CartExtension.CartValidationOutputTypeEnum type) {
        CartExtension.CartValidationOutputList cartValidationOutputList = cart.getCartValidationOutputs();
            for (Integer i = (cartValidationOutputList.size() - 1); i >= 0; i--) {
                CartExtension.CartValidationOutput cvo = cartValidationOutputList.get(i);
                if (cvo.getType() == type) {
                    cartValidationOutputList.remove(cvo);
                }
            }
        }
    }
    
    private static CartExtension.Cart arrangeAndLoadCartWithSpecifiedStatusAndThreeItems(CartExtension.CartStatusEnum cartStatus) {
        Id cartId = arrangeCartWithSpecifiedStatus(cartStatus);
        arrangeThreeCartItems(cartId);
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

    private static void assertNoCartValidationOutputs(CartExtension.Cart cart, Integer expectedCVOCount) {
        String errorString = '';
        Iterator<CartExtension.CartValidationOutput> cvoIterator = cart.getCartValidationOutputs().iterator();
        while (cvoIterator.hasNext()) {
            errorString += cvoIterator.next().getMessage() + '; ';
        }
        Assert.areEqual(expectedCVOCount, cart.getCartValidationOutputs().size(), 'No CartValidationOutputs expected, but was: ' + errorString);
    }
    
    private static void addCvoToCart( CartExtension.Cart cart) {
         CartExtension.CartItemList cartItemCollection = cart.getCartItems();
            Iterator<CartExtension.CartItem> cartItemCollectionIterator = cartItemCollection.iterator();
    
        	Integer i = 0;
            while (cartItemCollectionIterator.hasNext()) {
                CartExtension.CartItem cartItem = cartItemCollectionIterator.next();
    
                if (cartItem.getType() == CartExtension.SalesItemTypeEnum.PRODUCT && i == 0) {
    
                    CartExtension.CartValidationOutput cvo = new CartExtension.CartValidationOutput(
                        CartExtension.CartValidationOutputTypeEnum.INVENTORY,
                        CartExtension.CartValidationOutputLevelEnum.ERROR);
                        cart.getCartValidationOutputs().add(cvo);
                }
                i = i + 1;
            }
    }
    

}