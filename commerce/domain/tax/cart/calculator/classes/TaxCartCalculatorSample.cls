// This tax calculator extension class makes a call to an external service to retrieve tax
// information for a cart item and its adjustments and saves it to a cart data transfer object
// (DTO). For a tax calculator extension to be processed by the checkout flow, you must implement the
// CartExtension.TaxCartCalculator class.
//
// You need to have a good reason to use this extention point. For example, if you need to use cart custom fields in your calculation.
// Always check that commercestoretax.TaxService extention point isn't enough for you before extending the TaxCartCalculator.
// Extending commercestoretax.TaxService is required if you deal with subscription products and the TaxCartCalculator must call the commercestoretax.TaxService 
// if overriden.
//
// Disclaimer: the code listed here is a sample that hasn't been tested for production use. Always test your code before releasing to production.
public class TaxCartCalculatorSample extends CartExtension.TaxCartCalculator {

    // Disclaimer: the code listed here is a sample that hasn't been tested for production use. Always test your code before releasing to production.
    public virtual override void calculate(CartExtension.CartCalculateCalculatorRequest request) {
        try {
            CartExtension.Cart cart = request.getCart();

            // Clean up CVO based on tax. When new tax calculator request comes, we need to clean up
            // previous CVOs as they have been previously handled by the Cart Calculate API.
            CartExtension.CartValidationOutputList cartValidationOutputCollection = cart.getCartValidationOutputs();
            Iterator<CartExtension.CartValidationOutput> cartValidationOutputCollectionIterator = cartValidationOutputCollection.iterator();
            while (cartValidationOutputCollectionIterator.hasNext()) {
                CartExtension.CartValidationOutput cvo = cartValidationOutputCollectionIterator.next();
                if (cvo.getType() == CartExtension.CartValidationOutputTypeEnum.TAXES) {
                    cartValidationOutputCollection.remove(cvo);
                }
            }

            CartExtension.CartDeliveryGroupList cartDeliveryGroups = cart.getCartDeliveryGroups();
            
            Integer cartItemIdSeq = 0;

            // Cart might have multiple delivery groups, you should handle that
            CartExtension.CartDeliveryGroup cartDeliveryGroup = cartDeliveryGroups.get(0);

            // Map cart ID to cart item with type Product.
            CartExtension.CartItemList cartItemCollection = cart.getCartItems();

            // The cartItemCollection contains both products and shipping cart items.
            Map<String, CartExtension.CartItem> cartItemById = new Map<String, CartExtension.CartItem>();

            Iterator<CartExtension.CartItem> cartItemCollectionIterator = cartItemCollection.iterator();

            while (cartItemCollectionIterator.hasNext()) {
                CartExtension.CartItem cartItem = cartItemCollectionIterator.next();

                String cartItemId = (cartItem.getId() == null) ? String.valueOf(++cartItemIdSeq) : cartItem.getId();
                cartItemById.put(cartItemId, cartItem);
               
            }

            // Get the tax rates and tax amounts from an external service for all given products
            Map<String, TaxData> dataFromExternalService = getTaxesFromStaticResponse(
                cartItemById,
                CartDeliveryGroup.getDeliverToAddress().getState(),
                CartDeliveryGroup.getDeliverToAddress().getCountry(),
                cart.getTaxType());

            for (String cartItemId : dataFromExternalService.keySet()) {
                TaxData taxDetailsToCartId = dataFromExternalService.get(cartItemId);
                CartExtension.CartItem cartItem = cartItemById.get(cartItemId);
                
                addTaxesToCartItem(cartItem, taxDetailsToCartId);
            }

        } catch (Exception e) {
            // For testing purposes, this example treats exceptions as user errors, which means they are
            // displayed to the buyer user. In production, you probably want exceptions to be admin-type
            // errors. In that case, throw the exception here and make sure that a notification system is
            // in place to let the admin know that the error occurred. See the README section about error
            // handling for details about how to create that notification.
            throw new CalloutException('There was a problem with the request.');
        }
        return;
    }

    private void addTaxesToCartItem(CartExtension.CartItem cartItem, TaxData taxData) {
        if (cartItem.getCartTaxes().size() > 0) {
            // this sample always has at most one, your integration might have several
            cartItem.getCartTaxes().remove(cartItem.getCartTaxes().get(0));
        }

        if (cartItem.getCartTaxes() == null || cartItem.getCartTaxes().isEmpty()) {
            cartItem.setNetUnitPrice(taxData.getNetUnitPrice());
            cartItem.setGrossUnitPrice(taxData.getGrossUnitPrice());
            CartExtension.CartTaxList cartTaxCollection = cartItem.getCartTaxes();
            CartExtension.CartTax cartTax = new CartExtension.CartTax(
                CartExtension.TaxTypeEnum.ESTIMATED,
                taxData.getAmount(),
                taxData.getTaxName());
            cartTax.setTaxRate(String.valueOf(taxData.getRate()));
            cartTaxCollection.add(cartTax);
        }
    }

    private Map<String, TaxData> getTaxesFromStaticResponse(Map<String, CartExtension.CartItem> cartItemsMap, String state, String country, CartExtension.TaxLocaleTypeEnum taxType) {
        Double taxRate = 0.15;
        Map<String, TaxData> taxDetailsFromExternalService = new Map<String, TaxData>();
        for (String cartItemIdOrDeliveryGroupId : cartItemsMap.keySet()) {
            CartExtension.CartItem cartItem = cartItemsMap.get(cartItemIdOrDeliveryGroupId);
            String cartItemId = (cartItem.getId()==null) ? cartItemIdOrDeliveryGroupId : cartItem.getId();

            Double amount = cartItem.getTotalPriceAfterAllAdjustments()==null ? cartItem.getTotalListPrice() : cartItem.getTotalPriceAfterAllAdjustments();
            Double quantity = cartItem.getQuantity()==null ? 0.00 : cartItem.getQuantity();

            Double netUnitPrice = 0.00;
            Double grossUnitPrice = 0.00;

            // always remember to round correctly for the currency
            Double cartItemTax = amount * taxRate;

            if(taxType == CartExtension.TaxLocaleTypeEnum.GROSS) {
                grossUnitPrice = amount / quantity;
                netUnitPrice = (amount - cartItemTax) / quantity;
            } else {
                grossUnitPrice = (amount + cartItemTax) / quantity;
                netUnitPrice = amount / quantity;
            }

            taxDetailsFromExternalService.put(cartItemId, new TaxData(
                  (Decimal) taxRate,
                  (Decimal) cartItemTax,
                  'GST',
                  (Decimal) grossUnitPrice,
                  (Decimal) netUnitPrice));
        }

        return taxDetailsFromExternalService;
    }

    // Structure to store the tax data retrieved from external service. This class simplifies our
    // ability to access the data when storing it in Salesforce's CartTaxDto.
    class TaxData {
        private Decimal rate;
        private Decimal amount;
        private String taxName;
        private Decimal grossUnitPrice;
        private Decimal netUnitPrice;

        public TaxData(
          Decimal rateObj,
          Decimal amountObj,
          String taxNameObj,
          Decimal grossUnitPriceObj,
          Decimal netUnitPriceObj
      ) {
          rate = rateObj;
          amount = amountObj;
          taxName = taxNameObj;
          grossUnitPrice = grossUnitPriceObj;
          netUnitPrice = netUnitPriceObj;
      }

      public Decimal getRate() {
          return rate;
      }

      public Decimal getAmount() {
          return amount;
      }

      public String getTaxName() {
          return taxName;
      }

      public Decimal getGrossUnitPrice() {
          return grossUnitPrice;
      }

      public Decimal getNetUnitPrice() {
          return netUnitPrice;
      }
    }
}