/**
 * @description Pricing Calculator that throws CartExtension.CartCalculateRuntimeException.
 */
public class PricingCalculatorThrowsCartCalculateRTE extends CartExtension.PricingCartCalculator {

    public virtual override void calculate(CartExtension.CartCalculateCalculatorRequest request) {
        throw new CartExtension.CartCalculateRuntimeException('Runtime exception from custom Apex Calculator');
    }
}