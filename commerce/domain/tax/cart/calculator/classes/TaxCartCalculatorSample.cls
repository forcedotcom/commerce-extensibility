// This tax calculator extension class makes a call to an external service to retrieve tax
// information for a cart item and its adjustments and saves it to a cart data transfer object
// (DTO). For a tax calculator extension to be processed by the checkout flow, you must implement the
// CartExtension.TaxCartCalculator class.
public class TaxCartCalculatorSample extends CartExtension.TaxCartCalculator {

// You MUST change this to be your service or you must launch your own Third Party Service
// and add the host in Setup | Security | Remote site settings.
  private static String externalTaxHost = 'https://example.com';

  // You MUST change the useExternalService to True if you want to use the Third Party Service.
  private static Boolean useExternalService = false;
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

      // There should be one delivery group per cart.
      CartExtension.CartDeliveryGroupList cartDeliveryGroups = cart.getCartDeliveryGroups();
      CartExtension.CartDeliveryGroup cartDeliveryGroup = cartDeliveryGroups.get(0);

      // Map cart ID to cart item with type Product.
      CartExtension.CartItemList cartItemCollection = cart.getCartItems();

      // The cartItemCollection contains both products and shipping cart items.
      Map<String, CartExtension.CartItem> cartItemById = new Map<String, CartExtension.CartItem>();
      Map<String, CartExtension.CartItem> shippingItemById = new Map<String, CartExtension.CartItem>();

      Iterator<CartExtension.CartItem> cartItemCollectionIterator = cartItemCollection.iterator();

      while (cartItemCollectionIterator.hasNext()) {
      	CartExtension.CartItem cartItem = cartItemCollectionIterator.next();

        if (cartItem.getType() == CartExtension.SalesItemTypeEnum.PRODUCT) {
          cartItemById.put(cartItem.getId(), cartItem);
        } else if (cartItem.getType() == CartExtension.SalesItemTypeEnum.CHARGE) {
          // Shipping cart items are uniquely identified using delivery group id.
          CartExtension.CartDeliveryGroup deliveryGroup = cartItem.getCartDeliveryGroup();
          shippingItemById.put(deliveryGroup.getId(), cartItem);
        }
      }

      // Get the tax rates and tax amounts from an external service for all given products and its
      // adjustments.
      Map<String, TaxDataFromExternalService> dataFromExternalService = null;
      Map<String, TaxDataFromExternalService> dataFromExternalServiceForShippingItems = null;
      if(useExternalService){
         dataFromExternalService = getTaxesFromExternalService(
          cartItemById,
          CartDeliveryGroup.getDeliverToAddress().getState(),
          CartDeliveryGroup.getDeliverToAddress().getCountry(),
          cart.getTaxType()
        );
         dataFromExternalServiceForShippingItems = getTaxesFromExternalService(
          shippingItemById,
          CartDeliveryGroup.getDeliverToAddress().getState(),
          CartDeliveryGroup.getDeliverToAddress().getCountry(),
          cart.getTaxType()
        );
      } else{
         dataFromExternalService = getTaxesFromStaticResponse(
          cartItemById,
          CartDeliveryGroup.getDeliverToAddress().getState(),
          CartDeliveryGroup.getDeliverToAddress().getCountry(),
          cart.getTaxType()
        );
         dataFromExternalServiceForShippingItems = getTaxesFromStaticResponse(
          shippingItemById,
          CartDeliveryGroup.getDeliverToAddress().getState(),
          CartDeliveryGroup.getDeliverToAddress().getCountry(),
          cart.getTaxType()
        );
      }

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
          if (cartItem.getCartTaxes().size() > 0) {
            cartItem.getCartTaxes().remove(cartItem.getCartTaxes().get(0));
          }
          Iterator<CartExtension.CartItemPriceAdjustment> cartItemPriceAdjustmentsIterator = cartItem.getCartItemPriceAdjustments().iterator();
          while(cartItemPriceAdjustmentsIterator.hasNext()) {
            CartExtension.CartTaxList cipaTaxes = cartItemPriceAdjustmentsIterator.next()
              .getCartTaxes();
            if (cipaTaxes.size() > 0) {
              cipaTaxes.remove(cipaTaxes.get(0));
            }
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
          CartExtension.CartTaxList cartTaxCollection = cartItem.getCartTaxes();
          CartExtension.CartTax cartTax = new CartExtension.CartTax(
            CartExtension.TaxTypeEnum.ESTIMATED,
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
                CartExtension.TaxTypeEnum.ESTIMATED,
                cipaTax.getAmount(),
                taxDetailsToCartId.getTaxName()
              );
              promoTax.setTaxRate(String.valueOf(taxDetailsToCartId.getRate()));
              CartExtension.cartItemPriceAdjustment adj = getAdjustmentById(
                cartItem.getCartItemPriceAdjustments(),
                cipaTax.getId()
              );
              if (adj != null) {
                adj.getCartTaxes().add(promoTax);
              }
            }
        }
      }

      // If there are shipping items, add tax for them as well
      for (String cartItemId : dataFromExternalServiceForShippingItems.keySet()) {
        TaxDataFromExternalService taxDetailsToCartId = dataFromExternalServiceForShippingItems.get(cartItemId);
        CartExtension.CartItem cartItem = shippingItemById.get(cartItemId);
        boolean isCartItemModified = false;
        // If there is any modification in unit price, delete existing and create new cart tax entries in cart item.
        if (cartItem.getNetUnitPrice() != null &&
          cartItem.getNetUnitPrice() != taxDetailsToCartId.getNetUnitPrice()) {
            cartItem.getCartTaxes().remove(cartItem.getCartTaxes().get(0));
            isCartItemModified = true;
        }

        if (cartItem.getCartTaxes() == null ||
          cartItem.getCartTaxes().isEmpty() ||
          isCartItemModified == true) {
            cartItem.setNetUnitPrice(taxDetailsToCartId.getNetUnitPrice());
            cartItem.setGrossUnitPrice(taxDetailsToCartId.getGrossUnitPrice());
            CartExtension.CartTaxList cartTaxCollection = cartItem.getCartTaxes();
            CartExtension.CartTax cartTax = new CartExtension.CartTax(
              CartExtension.TaxTypeEnum.ESTIMATED,
              taxDetailsToCartId.getAmount(),
              taxDetailsToCartId.getTaxName()
            );
            cartTax.setTaxRate(String.valueOf(taxDetailsToCartId.getRate()));
            cartTaxCollection.add(cartTax);
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
    Iterator<CartExtension.CartItemPriceAdjustment> cartItemPriceAdjustmentsIterator = cartItemDto.getCartItemPriceAdjustments().iterator();
    while (cartItemPriceAdjustmentsIterator.hasNext()) {
      CartExtension.CartTaxList cartTaxes = cartItemPriceAdjustmentsIterator.next()
        .getCartTaxes();
      Iterator<CartExtension.CartTax> cartTaxesIterator = cartTaxes.iterator();
      while (cartTaxesIterator.hasNext()) {
      CartExtension.CartTax cartTax = cartTaxesIterator.next();
        Boolean changedAdjTax = false;
        for (Integer k = (ajustments.size() - 1); k >= 0; k--) {
          if (cartTax.getAmount() == ajustments.get(k).getAmount())
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
    CartExtension.cartItemPriceAdjustmentList cipaList,
    String id
  ) {
    Iterator<CartExtension.CartItemPriceAdjustment> cipaIterator = cipaList.iterator();
    while (cipaIterator.hasNext()) {
      CartExtension.CartItemPriceAdjustment cipa = cipaIterator.next();
      if (String.valueOf(cipa.getId()) == id)
        return cipa;
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
    CartExtension.TaxLocaleTypeEnum taxType
  ) {
    String requestURL = externalTaxHost+'/get-tax-rates-with-adjustments-post';
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
      return populateTax(resultsFromExternalService);
    } else {
      throw new CalloutException(
        'There was a problem with the request. Error: ' + response.getStatusCode()
      );
    }
  }

  private Map<String, TaxDataFromExternalService> populateTax(Map<String, Object> resultsFromExternalService){
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

  }

  private Map<String, TaxDataFromExternalService> getTaxesFromStaticResponse(Map<String, CartExtension.CartItem> cartItemsMap, String state, String country, CartExtension.TaxLocaleTypeEnum taxType) {

        Double taxRate = 0.15;
        String responseJson = '{';
        for (String key : cartItemsMap.keySet()) {
            CartExtension.CartItem cartItem = cartItemsMap.get(key);
            ID cartItemId = cartItem.getId();

            Double amount = cartItem.getTotalAmount()==null ? 0.00 : cartItem.getTotalAmount();
            Double tierAdjustment = cartItem.getAdjustmentAmount()==null ? 0.00 : cartItem.getAdjustmentAmount();
            Double quantity = cartItem.getQuantity()==null ? 0.00 : cartItem.getQuantity();

            if(country == 'US') {
                taxRate = 0.08;
                String [] noSalesTaxUSStates = new String [] {'AK', 'DE', 'MT', 'NH', 'OR'};
                if (noSalesTaxUSStates.contains(state)) {
                    taxRate = 0.00;
                }
            }

            Double itemizedPromotionTax = 0.00;
            Double [] itemizedPromotionTaxArr = new Double [] {};
            Double netUnitPrice = 0.00;
            Double grossUnitPrice = 0.00;

            Double multiplier = 0.00;

            if(taxType == CartExtension.TaxLocaleTypeEnum.GROSS ) {
                multiplier = taxRate / (1 + taxRate);
            } else {
                multiplier = taxRate;
            }

            Double cartItemTax = amount * multiplier;
            Double tierAdjustmentTax = (tierAdjustment!=null ? tierAdjustment : 0.00) * multiplier;

            CartExtension.CartItemPriceAdjustmentList itemizedPromotions = cartItem.getCartItemPriceAdjustments();
        	Iterator<CartExtension.CartItemPriceAdjustment> itemizedPromotionsIterator = itemizedPromotions.iterator();
            String itemizedPromotionTaxResp = '[';
            while (itemizedPromotionsIterator.hasNext()) {
                CartExtension.CartItemPriceAdjustment itemAdj = itemizedPromotionsIterator.next();
                Double itemTaxAmount = (itemAdj.getTotalAmount()!=null ? itemAdj.getTotalAmount() : 0.00) * multiplier;
                itemizedPromotionTaxResp = itemizedPromotionTaxResp + '{';
                itemizedPromotionTaxResp = itemizedPromotionTaxResp + '"id": "' + itemAdj.getId() + '",';
                itemizedPromotionTaxResp = itemizedPromotionTaxResp + '"taxAmount": ' + itemTaxAmount;
                itemizedPromotionTaxResp = itemizedPromotionTaxResp + '},';
                itemizedPromotionTax = itemizedPromotionTax + itemTaxAmount;
            }
            itemizedPromotionTaxResp = itemizedPromotionTaxResp.removeEnd(',') + ']';

            if(taxType == CartExtension.TaxLocaleTypeEnum.GROSS) {
                grossUnitPrice = amount / quantity;
                netUnitPrice = (amount - cartItemTax) / quantity;
            } else {
                grossUnitPrice = (amount + cartItemTax) / quantity;
                netUnitPrice = amount / quantity;
            }

            responseJson = responseJson + '"'+ key +'":';
            responseJson = responseJson + '{';
            responseJson = responseJson + '"cartItemId": "' + cartItemId + '",';
            responseJson = responseJson + '"amount": ' + cartItemTax + ',';
            responseJson = responseJson + '"adjustmentTaxAmount": ' + tierAdjustmentTax + ',';

            responseJson = responseJson + '"itemizedPromotionTaxAmounts": ';
            responseJson = responseJson + itemizedPromotionTaxResp;
            responseJson = responseJson + ',';

            responseJson = responseJson + '"totalItemizedPromotionTaxAmount": ' + itemizedPromotionTax + ',';
            responseJson = responseJson + '"grossUnitPrice": ' + grossUnitPrice + ',';
            responseJson = responseJson + '"netUnitPrice": ' + netUnitPrice + ',';
            responseJson = responseJson + '"rate": ' + taxRate + ',';
            responseJson = responseJson + '"taxName": "GST"';
            responseJson = responseJson + '},';
        }

        responseJson = responseJson.removeEnd(',') + '}';
        Map<String, Object> resultsFromStaticResponse =  (Map<String, Object>) JSON.deserializeUntyped(responseJson);
        return populateTax(resultsFromStaticResponse);
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
