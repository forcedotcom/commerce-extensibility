// This class facilitates tax calculation either by invoking an external service or by implementing the tax calculation logic internally.
// The resulting tax values and adjustments are then stored in a Cart Data Transfer Object (DTO), references to both code implementations provided.
// This apex class will only consider first delivery group for calculating taxes though multiple delivery groups associated with cart
// For a tax calculator extension to be processed by the checkout flow, you must implement the CartExtension.TaxCartCalculator class.

public class TaxCartCalculatorSample extends CartExtension.TaxCartCalculator {

    // You MUST change this to be your service or you must launch your own Third Party Service and add the host in Setup | Security | Remote site settings.
    private static String externalTaxHost = 'https://example.com';

    // You MUST change the useExternalService to True if you want to use the Third Party Service.
    private static Boolean useExternalService = false;

    public virtual override void calculate(CartExtension.CartCalculateCalculatorRequest request) {
        CartExtension.Cart cart = request.getCart();
        CartExtension.CartValidationOutputList cartValidationOutputCollection = cart.getCartValidationOutputs();
        try{
            // Clean up CVO based on tax. When new tax calculator request comes, we need to clean up
            // previous CVOs as they have been previously handled by the Cart Calculate API.
            for (Integer i = (cartValidationOutputCollection.size() - 1); i >= 0; i--) {
                CartExtension.CartValidationOutput cvo = cartValidationOutputCollection.get(i);
                if (cvo.getType() == CartExtension.CartValidationOutputTypeEnum.TAXES) {
                    cartValidationOutputCollection.remove(cvo);
                }
            }
            Integer cartItemIdSeq = 0;
            if (!isValidCart(cart)){
            	return;
            }

            CartExtension.CartDeliveryGroupList cartDeliveryGroups = cart.getCartDeliveryGroups();
            CartExtension.CartDeliveryGroup cartDeliveryGroup = cartDeliveryGroups.get(0);

            // Map cart ID to cart item with type Product.
            CartExtension.CartItemList cartItemCollection = cart.getCartItems();

            // The cartItemCollection contains both products and shipping cart items.
            Map<String, CartExtension.CartItem> cartItemByIdMap = new Map<String, CartExtension.CartItem>();
            Map<String, CartExtension.CartItem> chargeItemByDeliveryGroupIdMap = new Map<String, CartExtension.CartItem>();

            Iterator<CartExtension.CartItem> cartItemCollectionIterator = cartItemCollection.iterator();

            while (cartItemCollectionIterator.hasNext()) {
                CartExtension.CartItem cartItem = cartItemCollectionIterator.next();

                if (cartItem.getType() == CartExtension.SalesItemTypeEnum.PRODUCT) {
                	String cartItemId = (cartItem.getId() == null) ? String.valueOf(++cartItemIdSeq) : cartItem.getId();
                	cartItemByIdMap.put(cartItemId, cartItem);
                } else if (cartItem.getType() == CartExtension.SalesItemTypeEnum.CHARGE) {
                	// Shipping cart items are uniquely identified using delivery group id.
                	CartExtension.CartDeliveryGroup deliveryGroup = cartItem.getCartDeliveryGroup();
                	chargeItemByDeliveryGroupIdMap.put(deliveryGroup.getId(), cartItem);
                }
            }

            Map<String, TaxData> taxData = null;
            Map<String, TaxData> taxDataShippingItems = null;
            if(useExternalService){
				// Get the tax rates and tax amounts from an external service for all given products and its adjustments.
                taxData = getTaxesFromExternalService(
                cartItemByIdMap, cartDeliveryGroup.getDeliverToAddress().getState(),
                cartDeliveryGroup.getDeliverToAddress().getCountry(), cart.getTaxType());

                taxDataShippingItems = getTaxesFromExternalService(
                chargeItemByDeliveryGroupIdMap, cartDeliveryGroup.getDeliverToAddress().getState(),
                cartDeliveryGroup.getDeliverToAddress().getCountry(), cart.getTaxType());

            } else{
                taxData = getTaxesFromStaticResponse(
                cartItemByIdMap, cartDeliveryGroup.getDeliverToAddress().getState(),
                cartDeliveryGroup.getDeliverToAddress().getCountry(), cart.getTaxType());

                taxDataShippingItems = getTaxesFromStaticResponse(
                chargeItemByDeliveryGroupIdMap, cartDeliveryGroup.getDeliverToAddress().getState(),
                cartDeliveryGroup.getDeliverToAddress().getCountry(), cart.getTaxType());
            }

            // TODO need to add cvo in case of tax data is null
            if (taxData == null) {
                CartExtension.CartValidationOutput cvo = new CartExtension.CartValidationOutput(
                CartExtension.CartValidationOutputTypeEnum.TAXES,
                CartExtension.CartValidationOutputLevelEnum.ERROR);
                cvo.setMessage('No tax rates configured.');
                cartValidationOutputCollection.add(cvo);
                return;
            }

            // If no tax details are returned for any cart item, add a cart validation output entry. If
            // any invalid scenario found then return.
            boolean isCvoPresent = false;
            for (String cartItemId : cartItemByIdMap.keySet()) {
            	TaxData taxDetails = taxData.get(cartItemId);
            	if (taxDetails == null) {
            		CartExtension.CartValidationOutput cvo = new CartExtension.CartValidationOutput(
            		CartExtension.CartValidationOutputTypeEnum.TAXES,
            		CartExtension.CartValidationOutputLevelEnum.INFO);
            		cvo.setMessage('No tax rates configured for this location.');
            		cartValidationOutputCollection.add(cvo);
            		isCvoPresent = true;  // need to take an call on this we can exit for first time only
            	}
            }
			if (isCvoPresent == true)
				return;

            for (String cartItemId : taxData.keySet()) {
                TaxData taxDetailsToCartId = taxData.get(cartItemId);
                CartExtension.CartItem cartItem = cartItemByIdMap.get(cartItemId);

                // NOTE: DELETED items get filtered out in the DtoCollection and if there is no tax setup
                // against any cart item, then that's considered an invalid scenario and added to CVO. If
                // cart tax numbers are changed that indicates the cart item was MODIFIED, then:
                // 1. Delete existing and create new cart tax entries in cart item and cart item
                // adjustments.
                // 2. Update cart item tax information. Currently, we do not support taxes on tier
                // adjustment in an extension.
                boolean isCartItemModified = false;
                if ((cartItem.getNetUnitPrice() != null &&
                	cartItem.getNetUnitPrice() != taxDetailsToCartId.getNetUnitPrice()) ||
                	!VerifyAdjustmentUpdate(cartItem, taxDetailsToCartId)) {
                    if (cartItem.getCartTaxes().size() > 0) {
                    	cartItem.getCartTaxes().remove(cartItem.getCartTaxes().get(0));
                    }
                    Iterator<CartExtension.CartItemPriceAdjustment> cartItemPriceAdjustmentsIterator = cartItem.getCartItemPriceAdjustments().iterator();
                    while(cartItemPriceAdjustmentsIterator.hasNext()) {
                    	CartExtension.CartTaxList cipaTaxes = cartItemPriceAdjustmentsIterator.next().getCartTaxes();
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
                if (cartItem.getCartTaxes() == null || cartItem.getCartTaxes().isEmpty() || isCartItemModified == true) {

                    cartItem.setNetUnitPrice(taxDetailsToCartId.getNetUnitPrice());
                    cartItem.setGrossUnitPrice(taxDetailsToCartId.getGrossUnitPrice());
                    cartItem.setAdjustmentTaxAmount(taxDetailsToCartId.getAdjustmentTaxAmount());
                    CartExtension.CartTaxList cartTaxCollection = cartItem.getCartTaxes();
                    CartExtension.CartTax cartTax = new CartExtension.CartTax(CartExtension.TaxTypeEnum.ESTIMATED,
                    								taxDetailsToCartId.getAmount(), taxDetailsToCartId.getTaxName());

                    cartTax.setTaxRate(String.valueOf(taxDetailsToCartId.getRate()));
                    cartTaxCollection.add(cartTax);

                    // Add adjustment taxes to cartItemAdjustments of cartItem and create CartTaxDto entries
                    // for all promotion adjustments.
                    if (taxDetailsToCartId.getItemizedPromotionTaxAmounts() != null &&
                    	!(taxDetailsToCartId.getItemizedPromotionTaxAmounts().isEmpty())){
                    	for (CartAdjustment cipaTax : taxDetailsToCartId.getItemizedPromotionTaxAmounts()) {
                    		CartExtension.CartTax promoTax = new CartExtension.CartTax(
                    		CartExtension.TaxTypeEnum.ESTIMATED, cipaTax.getAmount(), taxDetailsToCartId.getTaxName());
                    		promoTax.setTaxRate(String.valueOf(taxDetailsToCartId.getRate()));
                    		CartExtension.cartItemPriceAdjustment adj = getAdjustmentById(
                    											cartItem.getCartItemPriceAdjustments(), cipaTax.getId());
                    	    if (adj != null) {
                    	    	adj.getCartTaxes().add(promoTax);
                    	    }
                    	}
                   }
                }
            }

            // If there are shipping items, add tax for them as well
            for (String cartItemId : taxDataShippingItems.keySet()) {
                TaxData taxDetailsToCartId = taxDataShippingItems.get(cartItemId);
                CartExtension.CartItem cartItem = chargeItemByDeliveryGroupIdMap.get(cartItemId);
                boolean isCartItemModified = false;
                // If there is any modification in unit price, delete existing and create new cart tax entries in cart item.
                if (cartItem.getNetUnitPrice() != null &&
                    cartItem.getNetUnitPrice() != taxDetailsToCartId.getNetUnitPrice()) {
                    cartItem.getCartTaxes().remove(cartItem.getCartTaxes().get(0));
                    isCartItemModified = true;
                }

                if (cartItem.getCartTaxes() == null || cartItem.getCartTaxes().isEmpty() || isCartItemModified == true) {
                    cartItem.setNetUnitPrice(taxDetailsToCartId.getNetUnitPrice());
                    cartItem.setGrossUnitPrice(taxDetailsToCartId.getGrossUnitPrice());
                    CartExtension.CartTaxList cartTaxCollection = cartItem.getCartTaxes();
                    CartExtension.CartTax cartTax = new CartExtension.CartTax(
                    CartExtension.TaxTypeEnum.ESTIMATED,
                    taxDetailsToCartId.getAmount(),
                    taxDetailsToCartId.getTaxName());
                    cartTax.setTaxRate(String.valueOf(taxDetailsToCartId.getRate()));
                    cartTaxCollection.add(cartTax);
                }
            }
        } catch(Exception e){
        	CartExtension.CartValidationOutput cvo = new CartExtension.CartValidationOutput(
        	CartExtension.CartValidationOutputTypeEnum.TAXES,
        	CartExtension.CartValidationOutputLevelEnum.ERROR);
        	cvo.setMessage('There was a problem. ' + e.getMessage());
        	cartValidationOutputCollection.add(cvo);
        	return;
        }
    }

    // This simulates a call to an external tax service. Change this function based on your external service.
    // Transform tax data returned from service into cart ID to TaxData map.
    // Admin need to modify this function according to external service api contract.
    private Map<String, TaxData> getTaxesFromExternalService(Map<String, CartExtension.CartItem> cartItemByIdMap,
    	String state, String country, CartExtension.TaxLocaleTypeEnum taxType) {
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
          JSON.serialize(cartItemByIdMap) +
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
            Map<String, Object> resultsFromExternalService = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            return populateTax(resultsFromExternalService);
        }
        return null;
    }

    private Map<String, TaxData> getTaxesFromStaticResponse(Map<String, CartExtension.CartItem> cartItemsMap, String state, String country, CartExtension.TaxLocaleTypeEnum taxType) {
        Double taxRate = 0.15;
        String responseJson = '{';
        for (String key : cartItemsMap.keySet()) {
            CartExtension.CartItem cartItem = cartItemsMap.get(key);
            String cartItemId = (cartItem.getId()==null) ? key : cartItem.getId();

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


	private boolean isValidCart(CartExtension.Cart cart){
		CartExtension.CartDeliveryGroupList cartDeliveryGroups = cart.getCartDeliveryGroups();
		if(cartDeliveryGroups == null || cartDeliveryGroups.size() == 0){
			return false;
		}

		CartExtension.CartDeliveryGroup cartDeliveryGroup = cartDeliveryGroups.get(0);
		if(cartDeliveryGroup.getDeliverToAddress() == null){
			return false;
		}

		return true;
	}

    // Verify if taxes from adjustments returned by external service and existing cart has changed. If
    // returned true then that indicates that there was an adjustment change.
    private Boolean VerifyAdjustmentUpdate(CartExtension.CartItem cartItemDto,
    	TaxData taxesFromExternalService) {
        List<CartAdjustment> adjustments = taxesFromExternalService.getItemizedPromotionTaxAmounts() == null
        					? new List<CartAdjustment>() : taxesFromExternalService.getItemizedPromotionTaxAmounts();

        Iterator<CartExtension.CartItemPriceAdjustment> cartItemPriceAdjustmentsIterator = cartItemDto.getCartItemPriceAdjustments().iterator();
        while (cartItemPriceAdjustmentsIterator.hasNext()) {
        	CartExtension.CartTaxList cartTaxes = cartItemPriceAdjustmentsIterator.next().getCartTaxes();
        	Iterator<CartExtension.CartTax> cartTaxesIterator = cartTaxes.iterator();
        	while (cartTaxesIterator.hasNext()) {
        		CartExtension.CartTax cartTax = cartTaxesIterator.next();
        		Boolean changedAdjTax = false;
        		for (Integer k = (adjustments.size() - 1); k >= 0; k--) {
        			if (cartTax.getAmount() == adjustments.get(k).getAmount())
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
    	CartExtension.cartItemPriceAdjustmentList cipaList, String id) {
        Iterator<CartExtension.CartItemPriceAdjustment> cipaIterator = cipaList.iterator();
        while (cipaIterator.hasNext()) {
        	CartExtension.CartItemPriceAdjustment cipa = cipaIterator.next();
        	if (cipa.getId() != null && String.valueOf(cipa.getId()) == id)
        		return cipa;
        	}
        return null;
    }

    private Map<String, TaxData> populateTax(Map<String, Object> resultsFromExternalService){
        Map<String, TaxData> taxDetailsFromExternalService = new Map<String, TaxData>();
        for (String cartItemId : resultsFromExternalService.keySet()) {
            Map<String, Object> rateAndAmountFromExternalService = (Map<String, Object>) resultsFromExternalService.get(cartItemId);
            List<Object> cipaList = (List<Object>) rateAndAmountFromExternalService.get('itemizedPromotionTaxAmounts');
            List<CartAdjustment> cipaObj = new List<CartAdjustment>();

            for (Object cipa : cipaList) {
                cipaObj.add(new CartAdjustment((String) ((Map<String, Object>) cipa).get('id'),
                    (Decimal) ((Map<String, Object>) cipa).get('taxAmount')));
            }
            taxDetailsFromExternalService.put(cartItemId,
                new TaxData(
                  (Decimal) rateAndAmountFromExternalService.get('rate'),
                  (Decimal) rateAndAmountFromExternalService.get('amount'),
                  (String) rateAndAmountFromExternalService.get('taxName'),
                  (Decimal) rateAndAmountFromExternalService.get('adjustmentTaxAmount'),
                  (Decimal) rateAndAmountFromExternalService.get('totalItemizedPromotionTaxAmount'),
                  cipaObj,
                  (Decimal) rateAndAmountFromExternalService.get('grossUnitPrice'),
                  (Decimal) rateAndAmountFromExternalService.get('netUnitPrice')
                ));
        }
        return taxDetailsFromExternalService;

    }

    // Structure to store the tax data retrieved from external service. This class simplifies our
    // ability to access the data when storing it in Salesforce's CartTaxDto.
    class TaxData {
        private Decimal rate;
        private Decimal amount;
        private String taxName;
        private Decimal adjustmentTaxAmount;
        private Decimal totalItemizedPromotionTaxAmount;
        private List<CartAdjustment> itemizedPromotionTaxAmounts;
        private Decimal grossUnitPrice;
        private Decimal netUnitPrice;

        public TaxData() {
          rate = 0.0;
          amount = 0.0;
          taxName = '';
          adjustmentTaxAmount = 0.0;
          totalItemizedPromotionTaxAmount = 0.0;
          itemizedPromotionTaxAmounts = null;
          grossUnitPrice = 0.0;
          netUnitPrice = 0.0;
        }

        public TaxData(
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
