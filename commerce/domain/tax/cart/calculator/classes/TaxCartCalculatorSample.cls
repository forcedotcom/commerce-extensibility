// This tax calculator extension class makes a call to an external service to retrieve tax
// information for a cart item and its adjustments and saves it to a cart data transfer object
// (DTO). For a tax calcular extension to be processed by the checkout flow, you must implement the
// CartExtension.AbstractCartCalculator class.
public class TaxCartCalculatorSample extends CartExtension.AbstractCartCalculator {
  public virtual override void calculate(CartExtension.CartCalculateCalculatorRequest request) {
    try {
      CartExtension.Cart cart = request.getCart();
      System.debug('In Tax Calculator');

      // Clean up CVO based on tax. When new tax calculator request comes, we need to clean up
      // previous CVOs as they have been previously handled by the Cart Calculate API.
      CartExtension.CartValidationOutputCollection cartValidationOutputCollection = cart.getCartValidationOutputs();
      for (Integer i = (cartValidationOutputCollection.size() - 1); i >= 0; i--) {
        CartExtension.CartValidationOutput cvo = cartValidationOutputCollection.get(i);
        if (cvo.getType() == CartExtension.CartValidationOutputTypeEnum.TAXES) {
          cartValidationOutputCollection.remove(cvo);
        }
      }

      // There should be one delivery group per cart.
      CartExtension.CartDeliveryGroupCollection cartDeliveryGroups = cart.getCartDeliveryGroups();
      CartExtension.CartDeliveryGroup cartDeliveryGroup = cartDeliveryGroups.get(0);

      // Map cart ID to cart item.
      CartExtension.CartItemCollection cartItemCollection = cart.getCartItems();
      Map<String, CartExtension.CartItem> cartItemById = new Map<String, CartExtension.CartItem>();
      for (Integer i = (cartItemCollection.size() - 1); i >= 0; i--) {
        cartItemById.put(cartItemCollection.get(i).getId(), cartItemCollection.get(i));
      }

      // Get the tax rates and tax amounts from an external service for all given products and its
      // adjustments.
      Map<String, TaxDataFromExternalService> dataFromExternalService = getTaxesFromExternalService(
        cartItemById,
        CartDeliveryGroup.getDeliverToAddress().getState(),
        CartDeliveryGroup.getDeliverToAddress().getCountry(),
        cart.getTaxType()
      );

      // If no tax details are returned for any cart item, add a cart validation output entry. If
      // any invalid scenario found then return.
      boolean isCvoPresent = false;
      for (String cartItemId : cartItemById.keySet()) {
        TaxDataFromExternalService taxDetails = dataFromExternalService.get(cartItemId);
        if (taxDetails == null) {
          // add cvo
          CartExtension.CartValidationOutput cvo = new CartExtension.CartValidationOutput(
            CartExtension.CartValidationOutputTypeEnum.TAXES,
            CartExtension.CartValidationOutputLevelEnum.INFO
          );
          cvo.setMessage('No tax rates configured for this location.');
          cartValidationOutputCollection.add(cvo);
          isCvoPresent = true;
        }
      }
      if (isCvoPresent == true)
        return;

      for (String cartItemId : dataFromExternalService.keySet()) {
        TaxDataFromExternalService taxDetailsToCartId = dataFromExternalService.get(cartItemId);
        CartExtension.CartItem cartItem = cartItemById.get(cartItemId);

        // NOTE: DELETED items get filtered out in the DtoCollection and if there is no tax setup
        // against any cart item, then that's considered an invalid scenario and added to CVO. If
        // cart tax numbers are changed that indicates the cart item was MODIFIED, then:
        // 1. Delete existing and create new cart tax entries in cart item and cart item
        // adjustments.
        // 2. Update cart item tax information. Currently, we do not support taxes on tier
        // adjustment in an extension.
        boolean isCartItemModified = false;
        if (
          (cartItem.getNetUnitPrice() != null &&
          cartItem.getNetUnitPrice() != taxDetailsToCartId.getNetUnitPrice()) ||
          !VerifyAdjustmentUpdate(cartItem, taxDetailsToCartId)
        ) {
          cartItem.getCartTaxes().remove(cartItem.getCartTaxes().get(0));
          for (Integer i = (cartItem.getCartItemPriceAdjustments().size() - 1); i >= 0; i--) {
            CartExtension.CartTaxCollection cipaTaxes = cartItem.getCartItemPriceAdjustments()
              .get(i)
              .getCartTaxes();
            cipaTaxes.remove(cipaTaxes.get(0));
          }
          isCartItemModified = true;
        }

        // If there are no existing cart tax entries in the cart item that indicates cart item was
        // newly CREATED in the cart then:
        // 1. Create new cart tax entries
        // 2. Update cart item tax information
        if (
          cartItem.getCartTaxes() == null ||
          cartItem.getCartTaxes().isEmpty() ||
          isCartItemModified == true
        ) {
          cartItem.setNetUnitPrice(taxDetailsToCartId.getNetUnitPrice());
          cartItem.setGrossUnitPrice(taxDetailsToCartId.getGrossUnitPrice());
          cartItem.setAdjustmentTaxAmount(taxDetailsToCartId.getAdjustmentTaxAmount());
          CartExtension.CartTaxCollection cartTaxCollection = cartItem.getCartTaxes();
          CartExtension.CartTax cartTax = new CartExtension.CartTax(
            CartExtension.TaxTypesEnum.ESTIMATED,
            taxDetailsToCartId.getAmount(),
            taxDetailsToCartId.getTaxName()
          );
          cartTax.setTaxRate(String.valueOf(taxDetailsToCartId.getRate()));
          cartTaxCollection.add(cartTax);

          // Add adjustment taxes to cartItemAdjustments of cartItem and create CartTaxDto entries
          // for all promotion adjustments.
          if (
            taxDetailsToCartId.getItemizedPromotionTaxAmounts() != null &&
            !(taxDetailsToCartId.getItemizedPromotionTaxAmounts().isEmpty())
          )
            for (CartAdjustment cipaTax : taxDetailsToCartId.getItemizedPromotionTaxAmounts()) {
              CartExtension.CartTax promoTax = new CartExtension.CartTax(
                CartExtension.TaxTypesEnum.ESTIMATED,
                cipaTax.getAmount(),
                taxDetailsToCartId.getTaxName()
              );
              promoTax.setTaxRate(String.valueOf(taxDetailsToCartId.getRate()));
              CartExtension.cartItemPriceAdjustment adj = getAdjustmentById(
                cartItem.getCartItemPriceAdjustments(),
                cipaTax.getId()
              );
              adj.getCartTaxes().add(promoTax);
            }
        }
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

  // Verify if taxes from adjustments returned by external service and existing cart has changed. If
  // returned true then that indicates that there was an adjustment change.
  private Boolean VerifyAdjustmentUpdate(
    CartExtension.CartItem cartItemDto,
    TaxDataFromExternalService taxesFromExternalService
  ) {
    List<CartAdjustment> ajustments = taxesFromExternalService.getItemizedPromotionTaxAmounts() ==
      null
      ? new List<CartAdjustment>()
      : taxesFromExternalService.getItemizedPromotionTaxAmounts();

    for (Integer i = (cartItemDto.getCartItemPriceAdjustments().size() - 1); i >= 0; i--) {
      CartExtension.CartTaxCollection cartTaxes = cartItemDto.getCartItemPriceAdjustments()
        .get(i)
        .getCartTaxes();
      for (Integer j = (cartTaxes.size() - 1); j >= 0; j--) {
        Boolean changedAdjTax = false;
        for (Integer k = (ajustments.size() - 1); k >= 0; k--) {
          if (cartTaxes.get(j).getAmount() == ajustments.get(k).getAmount())
            changedAdjTax = true;
        }
        if (changedAdjTax == false)
          return false;
      }
    }
    return true;
  }

  // Get cartItemAdjustment based on its ID.
  private CartExtension.cartItemPriceAdjustment getAdjustmentById(
    CartExtension.cartItemPriceAdjustmentCollection cipaList,
    String id
  ) {
    for (Integer i = (cipaList.size() - 1); i >= 0; i--) {
      if (cipaList.get(i).getId() == id)
        return cipaList.get(i);
    }
    return null;
  }

  // This similartes a call to an external tax service. Change this function based on your external
  // service. Transform tax data returned from service into cart ID to TaxDataFromExternalService
  // map.
  private Map<String, TaxDataFromExternalService> getTaxesFromExternalService(
    Map<String, CartExtension.CartItem> cartItemById,
    String state,
    String country,
    CartExtension.TaxLocaleType taxType
  ) {
    String requestURL = 'https://b2b-commerce-test.herokuapp.com/get-tax-rates-with-adjustments-post';
    String requestBody =
      '{"state":"' +
      state +
      '", "country":"' +
      country +
      '", "taxType":"' +
      taxType +
      '", ' +
      '"amountsBySKU":' +
      JSON.serialize(cartItemById) +
      '}';
    Http http = new Http();
    HttpRequest request = new HttpRequest();
    request.setEndpoint(requestURL);
    request.setMethod('POST');
    request.setHeader('Content-Type', 'application/json');
    request.setBody(requestBody);
    HttpResponse response = http.send(request);

    // If the request is successful, parse the JSON response.
    if (response.getStatusCode() == 200) {
      Map<String, Object> resultsFromExternalService = (Map<String, Object>) JSON.deserializeUntyped(
        response.getBody()
      );
      Map<String, TaxDataFromExternalService> taxDetailsFromExternalService = new Map<String, TaxDataFromExternalService>();
      for (String cartItemId : resultsFromExternalService.keySet()) {
        Map<String, Object> rateAndAmountFromExternalService = (Map<String, Object>) resultsFromExternalService.get(
          cartItemId
        );
        List<Object> cipaList = (List<Object>) rateAndAmountFromExternalService.get(
          'itemizedPromotionTaxAmounts'
        );
        List<CartAdjustment> cipaObj = new List<CartAdjustment>();

        for (Object cipa : cipaList) {
          cipaObj.add(
            new CartAdjustment(
              (String) ((Map<String, Object>) cipa).get('id'),
              (Decimal) ((Map<String, Object>) cipa).get('taxAmount')
            )
          );
        }
        taxDetailsFromExternalService.put(
          cartItemId,
          new TaxDataFromExternalService(
            (Decimal) rateAndAmountFromExternalService.get('rate'),
            (Decimal) rateAndAmountFromExternalService.get('amount'),
            (String) rateAndAmountFromExternalService.get('taxName'),
            (Decimal) rateAndAmountFromExternalService.get('adjustmentTaxAmount'),
            (Decimal) rateAndAmountFromExternalService.get('totalItemizedPromotionTaxAmount'),
            cipaObj,
            (Decimal) rateAndAmountFromExternalService.get('grossUnitPrice'),
            (Decimal) rateAndAmountFromExternalService.get('netUnitPrice')
          )
        );
      }
      return taxDetailsFromExternalService;
    } else {
      throw new CalloutException(
        'There was a problem with the request. Error: ' + response.getStatusCode()
      );
    }
  }

  // Structure to store the tax data retrieved from external service. This class simplifies our
  // ability to access the data when storing it in Salesforce's CartTaxDto.
  class TaxDataFromExternalService {
    private Decimal rate;
    private Decimal amount;
    private String taxName;
    private Decimal adjustmentTaxAmount;
    private Decimal totalItemizedPromotionTaxAmount;
    private List<CartAdjustment> itemizedPromotionTaxAmounts;
    private Decimal grossUnitPrice;
    private Decimal netUnitPrice;

    public TaxDataFromExternalService() {
      rate = 0.0;
      amount = 0.0;
      taxName = '';
      adjustmentTaxAmount = 0.0;
      totalItemizedPromotionTaxAmount = 0.0;
      itemizedPromotionTaxAmounts = null;
      grossUnitPrice = 0.0;
      netUnitPrice = 0.0;
    }

    public TaxDataFromExternalService(
      Decimal rateObj,
      Decimal amountObj,
      String taxNameObj,
      Decimal adjustmentTaxAmountObj,
      Decimal totalItemizedPromotionTaxAmountObj,
      List<CartAdjustment> itemizedPromotionTaxAmountsObj,
      Decimal grossUnitPriceObj,
      Decimal netUnitPriceObj
    ) {
      rate = rateObj;
      amount = amountObj;
      taxName = taxNameObj;
      adjustmentTaxAmount = adjustmentTaxAmountObj;
      totalItemizedPromotionTaxAmount = totalItemizedPromotionTaxAmountObj;
      itemizedPromotionTaxAmounts = itemizedPromotionTaxAmountsObj;
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

    public Decimal getAdjustmentTaxAmount() {
      return adjustmentTaxAmount;
    }

    public Decimal getTotalItemizedPromotionTaxAmount() {
      return totalItemizedPromotionTaxAmount;
    }

    public List<CartAdjustment> getItemizedPromotionTaxAmounts() {
      return itemizedPromotionTaxAmounts;
    }

    public Decimal getGrossUnitPrice() {
      return grossUnitPrice;
    }

    public Decimal getNetUnitPrice() {
      return netUnitPrice;
    }
  }

  class CartAdjustment {
    private String id;
    private Decimal amount;

    public CartAdjustment() {
      id = '';
      amount = 0.0;
    }

    public CartAdjustment(String idObj, Decimal taxAmountObj) {
      id = idObj;
      amount = taxAmountObj;
    }

    public String getId() {
      return id;
    }

    public Decimal getAmount() {
      return amount;
    }
  }
}
