/**
  * @description 
  * 
  * USE CASE
  * 
  * The customer was notified by the warehouse that during the inventory process, SKU_RED_SHIRT was accidentally made available. 
  * Due to a system issue, the warehouse is currently unable to mark it as unavailable again. 
  * Customer does NOT want to sell the SKU_RED_SHIRT in the store front
  * 
  * SI Solution
  * Extended inventory calculator to show a message during checkout that SKU_RED_SHIRT that shipping migth be delay 
  * 
  */
  public class InventoryCartCalculatorSample extends CartExtension.InventoryCartCalculator {


    private static final String SKU_RED_SHIRT = 'SKU_RED_SHIRT'; 
    private static final String SKU_RED_SHIRT_MESSAGE = 'Apologies for the inconvenience, but there is an issue with SKU_RED_SHIRT, and it is currently unavailable.'; 

    public InventoryCartCalculatorSample() {
        super();
    }

     /**
     * @description Constructor used by unit tests only. 
     * @param apexExecutor Executor which executes various calculators. Can be used to stub calculation results or delegate calculations to actual Calculator. See <<CartCalculateExecutorMock>>.
     */
    public InventoryCartCalculatorSample(CartExtension.CartCalculateExecutorMock apexExecutor) {
        // Must call super constructor in order for provided Executor to be used for calculations
        super(apexExecutor);
    }

    public virtual override void calculate(CartExtension.CartCalculateCalculatorRequest request) { 

        CartExtension.Cart cart = request.getCart();    

        super.calculate(request);

        CartExtension.CartItemList cartItemCollection = cart.getCartItems();
        Iterator<CartExtension.CartItem> cartItemCollectionIterator = cartItemCollection.iterator();
    
        while (cartItemCollectionIterator.hasNext()) {
            CartExtension.CartItem cartItem = cartItemCollectionIterator.next();

            system.debug('CART ITEM SKU: ' + cartItem.getSku());
            if (cartItem.getSku().equals(SKU_RED_SHIRT)) {
                CartExtension.CartValidationOutput cvo = new CartExtension.CartValidationOutput(
                    CartExtension.CartValidationOutputTypeEnum.INVENTORY,
                    CartExtension.CartValidationOutputLevelEnum.ERROR, cartItem);
                    cvo.setMessage(SKU_RED_SHIRT_MESSAGE);
                    cart.getCartValidationOutputs().add(cvo);
                system.debug('CART CVO: ' + cvo);
            }
        }
    }
}