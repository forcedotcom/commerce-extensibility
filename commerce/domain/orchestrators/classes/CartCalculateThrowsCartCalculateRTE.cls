/**
 * @description A sample Orchestrator that throws CartExtension.CartCalculateRuntimeException.
 */
public class CartCalculateThrowsCartCalculateRTE extends CartExtension.CartCalculate {

    public virtual override void calculate(CartExtension.CartCalculateOrchestratorRequest request) {
        throw new CartExtension.CartCalculateRuntimeException('Runtime exception from custom Apex Orchestrator');
    }
}