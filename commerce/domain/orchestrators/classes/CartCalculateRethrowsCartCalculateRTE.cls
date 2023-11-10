/**
 * @description A sample Orchestrator that catches and re-throws a CartExtension.CartCalculateRuntimeException.
 */
public class CartCalculateRethrowsCartCalculateRTE extends CartExtension.CartCalculate {

    public virtual override void calculate(CartExtension.CartCalculateOrchestratorRequest request) {
        CartExtension.CartCalculateCalculatorRequest calculatorRequest =
                new CartExtension.CartCalculateCalculatorRequest(
                        request.getCart(),
                        request.getOptionalBuyerActionDetails());

        try {
            prices(calculatorRequest);
        } catch (CartExtension.CartCalculateRuntimeException e) {
            throw new CartExtension.CartCalculateRuntimeException('Runtime exception from custom Apex Calculator is re-thrown from custom Apex Orchestrator');
        }
    }
}