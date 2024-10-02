public class InventoryCartCalculatorSample extends CartExtension.InventoryCartCalculator {

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

        if (cart.getStatus() != CartExtension.CartStatusEnum.CHECKOUT) {
            return;
        }

        removeAllCVOsOfType(cart, CartExtension.CartValidationOutputTypeEnum.INVENTORY);
        super.calculate(request);

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