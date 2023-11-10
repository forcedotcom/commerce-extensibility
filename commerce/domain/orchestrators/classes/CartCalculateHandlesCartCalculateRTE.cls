/**
 * @description A sample Orchestrator that handles CartExtension.CartCalculateRuntimeException thrown by a Pricing Calculator.
 */
public class CartCalculateHandlesCartCalculateRTE extends CartExtension.CartCalculate {

    public virtual override void calculate(CartExtension.CartCalculateOrchestratorRequest request) {
        CartExtension.CartCalculateCalculatorRequest calculatorRequest =
                new CartExtension.CartCalculateCalculatorRequest(
                        request.getCart(),
                        request.getOptionalBuyerActionDetails());

        try {
            prices(calculatorRequest);
        } catch (CartExtension.CartCalculateRuntimeException e) {
            // Handle the exception
        }
    }
}