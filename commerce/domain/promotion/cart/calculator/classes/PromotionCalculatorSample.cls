 /**
  * @description This sample is for the situations where Promotion Calculation needs to be extended or overridden via the
  * extension point for the Promotion Calculator. You are expected to refer this and write your own implementation.
  * This class must extend the CartExtension.PromotionsCartCalculator class to be processed.
  */
public with sharing class PromotionCalculatorSample extends CartExtension.PromotionsCartCalculator {

    // You MUST change this to be a valid promotion id.
    public static final String DUMMY_PROMOTION_ID = '0c8xx000000003FAAQ';

    public virtual override void calculate(CartExtension.CartCalculateCalculatorRequest request) {
        cartextension.Cart cart = request.getCart();
        resetAllAdjustments(cart);
        applyAdjustments(cart);
    }

    /**
     * @description Remove cart & cart-item level adjustments, cart validation outputs.
     * @param cart Holds details about cart
     */
    public static void resetAllAdjustments(cartextension.Cart cart) {

        // Remove all cart-level adjustments
        Iterator<CartExtension.CartAdjustmentGroup> cagIter = cart.getCartAdjustmentGroups().iterator();
        List<CartExtension.CartAdjustmentGroup> cagToRemove= new List<cartextension.CartAdjustmentGroup>();
        while(cagIter.hasNext()) {
            cagToRemove.add(cagIter.next());
        }
        // Remove CartItemAdjustments
        for(CartExtension.CartAdjustmentGroup cag : cagToRemove) {
            cart.getCartAdjustmentGroups().remove(cag);
        }

        // Remove all cart-item level adjustments
        Iterator<CartExtension.CartItem> ciIter = cart.getCartItems().iterator();
        while(ciIter.hasNext()) {

            // For every cart item, cursor through adjustments
            CartExtension.CartItem ci = ciIter.next();
            Iterator<CartExtension.CartItemPriceAdjustment> ciaIter = ci.getCartItemPriceAdjustments().iterator();
            List<CartExtension.CartItemPriceAdjustment> ciaToRemove= new List<CartExtension.CartItemPriceAdjustment>();

            // For every adjustment, look for a matching external adjustment
            while(ciaIter.hasNext()) {
                ciaToRemove.add(ciaIter.next());
            }
            for(CartExtension.CartItemPriceAdjustment cia : ciaToRemove) {
                ci.getCartItemPriceAdjustments().remove(cia);
            }
        }

        // Remove promotion cart validation output
        Iterator<CartExtension.CartValidationOutput> cvoIter = cart.getCartValidationOutputs().iterator();
        List<CartExtension.CartValidationOutput> cvoToRemove = new List<CartExtension.CartValidationOutput>();
        while(cvoIter.hasNext()) {
            cvoToRemove.add(cvoIter.next());
        }
        for(CartExtension.CartValidationOutput cvo : cvoToRemove) {
            if (CartExtension.CartValidationOutputTypeEnum.PROMOTIONS == cvo.getType()) {
                cart.getCartValidationOutputs().remove(cvo);
            }
        }
    }


    /**
     * @description Apply flat 5 percent discount across all cart items
     * @param cart Holds details about cart
     */
    public static void applyAdjustments(CartExtension.Cart cart) {

        Decimal pctDiscount = -5;
        Iterator<CartExtension.CartItem> ciIter = cart.getCartItems().iterator();
        while(ciIter.hasNext()) {

            CartExtension.CartItem ci = ciIter.next();
            Decimal promotionAdjustment = (ci.getSalesPrice() * (pctDiscount/100) * ci.getQuantity());
            promotionAdjustment = promotionAdjustment.setScale(2,System.RoundingMode.HALF_DOWN); // Currency precision rounding
            CartExtension.CartItemPriceAdjustment cia = new
                                CartExtension.CartItemPriceAdjustment(cartextension.CartAdjustmentTargetTypeEnum.ITEM, // AdjustmentTargetType
                                                                      promotionAdjustment, // TotalAmount
                                                                      cartextension.PriceAdjustmentSourceEnum.PROMOTION, // AdjustmentSource
                                                                      cartextension.AdjustmentTypeEnum.ADJUSTMENT_PERCENTAGE, // AdjustmentType
                                                                      pctDiscount, // AdjustmentValue
                                                                      DUMMY_PROMOTION_ID); // PriceAdjustmentCauseId
            cia.setPriority(1);
            cia.setAdjustmentAmountScope(cartextension.AdjustmentAmountScopeEnum.TOTAL);
            cia.setDescription('PromotionCalculator');
            ci.getCartItemPriceAdjustments().add(cia);
            
            // Populate TotalPromoAdjustmentAmount for cart-item & update totals based on promotion adjustment
            ci.setTotalPromoAdjustmentAmount(promotionAdjustment);
            ci.setTotalAdjustmentAmount(promotionAdjustment);
            ci.setTotalPriceAfterAllAdjustments(ci.getSalesPrice() - promotionAdjustment);

        }
    }
}