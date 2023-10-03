/**
 * @description Pricing Calculator that updates cart items with estimated prices using default service for Cart operations
 * and uses external service for actual prices for Checkout operations.
 */
public class EstimatedActualPricingCalculator extends CartExtension.PricingCartCalculator {

    public static final String SKU1_NAME = 'My SKU 1';
    public static final String SKU2_NAME = 'My SKU 2';
    public static final String SKU3_NAME = 'My SKU 3';
    public static final Decimal ACTUAL_PRICE_SKU1 = 100.00;
    public static final Decimal ACTUAL_PRICE_SKU2 = 200.00;
    public static final Decimal ACTUAL_PRICE_SKU3 = 300.00;
    public static final Decimal DEFAULT_PRICE_FOR_MISSING_SKUS = 9.99;

    public static final String GENERAL_ERROR_MESSAGE_EN = 'Sorry, something went wrong when pricing your cart. Please contact your Admin.';
    public static final String GENERAL_ERROR_MESSAGE_FR = 'Désolé, une erreur s\'est produite lors de la tarification de votre panier. Veuillez contacter votre administrateur.';
    public static final String PRICING_FAILED_FOR_CART_ITEM_ERROR_MESSAGE_EN = 'Sorry, we are not able to retrieve price for {0}. Please try again later or remove it from the Cart.';
    public static final String PRICING_FAILED_FOR_CART_ITEM_ERROR_MESSAGE_FR = 'Désolé, nous ne parvenons pas à récupérer le prix du {0}. Veuillez réessayer plus tard ou le supprimer du panier.';

    // Flag to control if Http Callout is actually performed or hardcoded data is used.
    private Boolean useExternalService = False;
    // Flag to control if default price for missing SKUs should be used.
    private Boolean priceMissingSkusByDefault = True;

    /**
     * @description All classes extending CartExtension.AbstractCartCalculator must have a default constructor defined
     */
    public EstimatedActualPricingCalculator() {
        super();
    }

    /**
     * @description Constructor used by unit tests only. See <<PricingCalculatorWithExternalCalloutTest>>.
     * @param apexExecutor Executor which executes various calculators. Can be used to stub calculation results or delegate calculations to actual Calculator. See <<CartCalculateExecutorMock>>.
     */
    public EstimatedActualPricingCalculator(CartExtension.CartCalculateExecutorMock apexExecutor) {
        // Must call super constructor in order for provided Executor to be used for calculations
        super(apexExecutor);
    }

    public EstimatedActualPricingCalculator(Boolean useExternalService, Boolean priceMissingSkusByDefault) {
        super();
        this.useExternalService = useExternalService;
        this.priceMissingSkusByDefault = priceMissingSkusByDefault;
    }

    public virtual override void calculate(CartExtension.CartCalculateCalculatorRequest request) {
        CartExtension.Cart cart = request.getCart();

        if (cart.getStatus() == CartExtension.CartStatusEnum.ACTIVE) {
            super.calculate(request);
            return;
        }

        Iterator<CartExtension.CartItem> cartItemsIterator = clearErrorsAndGetCartItemsIterator(cart, request.getOptionalBuyerActionDetails());

        // Get the SKUs from each cart item that needs price calculations
        Map<String, CartExtension.CartItem> skuToCartItem = new Map<String, CartExtension.CartItem>();
        while (cartItemsIterator.hasNext()) {
            CartExtension.CartItem cartItem = cartItemsIterator.next();
            skuToCartItem.put(cartItem.getSku(), cartItem);
        }

        Map<String, Decimal> pricingDataMap = getPricingDataFromExternalServiceForSkus(skuToCartItem.keySet());
        if (pricingDataMap == Null) {
            // No data returned means there is an issue with underlying 3rd party service. Populate generic error message for the Buyer.
            CartExtension.CartValidationOutput cvo = new CartExtension.CartValidationOutput(
                                                        CartExtension.CartValidationOutputTypeEnum.SHIPPING,
                                                        CartExtension.CartValidationOutputLevelEnum.ERROR);
            String errorMessage = getGenericErrorMessage();
            cvo.setMessage(errorMessage);
            cart.getCartValidationOutputs().add(cvo);
            return;
        }

        cartItemsIterator = skuToCartItem.values().iterator();
        while (cartItemsIterator.hasNext()) {
            CartExtension.CartItem cartItem = cartItemsIterator.next();
            if (!pricingDataMap.containsKey(cartItem.getSku())) {
                // No price available for the SKU in the Cart. Populate error message for the Buyer.
                CartExtension.CartValidationOutput cvo = new CartExtension.CartValidationOutput(
                                        CartExtension.CartValidationOutputTypeEnum.PRICING,
                                        CartExtension.CartValidationOutputLevelEnum.ERROR,
                                        cartItem);
                String errorMessage = getFailedToRepriceItemMessage(cartItem);
                cvo.setMessage(errorMessage);
                cart.getCartValidationOutputs().add(cvo);
                continue;
            }
            Decimal price = pricingDataMap.get(cartItem.getSku());
            // Update cart item fields
            cartItem.setListPrice(price);
            cartItem.setSalesPrice(price);
            cartItem.setTotalListPrice(price * cartItem.getQuantity());
            cartItem.setTotalPrice(price * cartItem.getQuantity());
        }
    }

    /**
     * @description Returns an iterator instance for Cart Items that need price calculations.
     *
     * @param cart In memory representation of the Cart
     * @param optionalBuyerActionDetails The latest set of changes applied to the Cart by the Buyer
     *
     * @return <<Iterator<CartExtension.CartItem>>>
     */
    private Iterator<CartExtension.CartItem> clearErrorsAndGetCartItemsIterator(
            CartExtension.Cart cart,
            CartExtension.OptionalBuyerActionDetails optionalBuyerActionDetails) {

        CartExtension.CartValidationOutputList cartValidationOutputs = cart.getCartValidationOutputs();
        if (!optionalBuyerActionDetails.isPresent() || optionalBuyerActionDetails.get().isCheckoutStarted()) {
            // Remove all CVOs of PRICING type since we are going to reprice all cart items.
            removeAllCVOsOfType(cart, CartExtension.CartValidationOutputTypeEnum.PRICING);
            return cart.getCartItems().iterator();
        }

        // Get the list of changed cart items from BuyerActionDetails
        List<CartExtension.CartItem> cartItemsToCalculatePrice = new List<CartExtension.CartItem>();
        List<CartExtension.CartItemChange> cartItemChanges = optionalBuyerActionDetails.get().getCartItemChanges();

        for (CartExtension.CartItemChange cartItemChange : cartItemChanges) {
            CartExtension.OptionalCartItem optionalCartItem = cartItemChange.getChangedItem();
            if (optionalCartItem.isPresent()) {
                CartExtension.CartItem cartItem = optionalCartItem.get();
                cartItemsToCalculatePrice.add(cartItem);
                // Remove CVOs related to the changed cart item, but leave other PRICING related CVOs.
                removeCVOsOfTypeRelatedTo(cart, CartExtension.CartValidationOutputTypeEnum.PRICING, cartItem);
            }
        }

        return cartItemsToCalculatePrice.iterator();
    }

    private String getGenericErrorMessage() {
        // Use User locale to populate localized message.
        if (UserInfo.getLocale() == 'fr') {
            return GENERAL_ERROR_MESSAGE_FR;
        } else {
            return GENERAL_ERROR_MESSAGE_EN;
        }
        // Alternatively Labels can be used.
        //return Label.GENERIC_PRICING_FAILED_ERROR_MESSAGE;
    }

    private String getFailedToRepriceItemMessage(CartExtension.CartItem cartItem) {
        // Use User locale to populate localized message.
        if (UserInfo.getLocale() == 'fr') {
            return String.format(PRICING_FAILED_FOR_CART_ITEM_ERROR_MESSAGE_FR, new List<String>{cartItem.getSku()});
        } else {
            return String.format(PRICING_FAILED_FOR_CART_ITEM_ERROR_MESSAGE_EN, new List<String>{cartItem.getSku()});
        }
        // Alternatively Labels can be used.
        //return String.format(Label.PRICING_FAILED_FOR_CART_ITEM_ERROR_MESSAGE, new List<String>{cartItem.getSku()});
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

    private void removeCVOsOfTypeRelatedTo(CartExtension.Cart cart, CartExtension.CartValidationOutputTypeEnum type,
                                            CartExtension.CartItem cartItem) {
        if (cartItem.getId() == null) {
            return;
        }
        CartExtension.CartValidationOutputList cartValidationOutputList = cart.getCartValidationOutputs();
        for (Integer i = (cartValidationOutputList.size() - 1); i >= 0; i--) {
            CartExtension.CartValidationOutput cvo = cartValidationOutputList.get(i);
            if (cvo.getRelatedEntityId() == null) {
                continue;
            }
            if (cvo.getType() == type && cvo.getRelatedEntityId() == cartItem.getId()) {
                cartValidationOutputList.remove(cvo);
            }
        }
    }

    /**
     * @description This doesn't actually make an HTTP call, but it mocks the JSON response of an external Pricing
     * Service.
     *
     * @param skus A set of SKUs to get pricing data
     *
     * @return Map containing PricingData for each SKU passed into this method
     */
    private Map<String, Decimal> getPricingDataFromExternalServiceForSkus(Set<String> skus) {
        if (!useExternalService) {
            Map<String, Decimal> prices = new Map<String, Decimal>();
            for (String sku: skus) {
                if (sku == SKU1_NAME) {
                    prices.put(SKU1_NAME, ACTUAL_PRICE_SKU1);
                } else if (sku == SKU2_NAME) {
                    prices.put(SKU2_NAME, ACTUAL_PRICE_SKU2);
                } else if (sku == SKU3_NAME) {
                    prices.put(SKU3_NAME, ACTUAL_PRICE_SKU3);
                } else if (priceMissingSkusByDefault) {
                    prices.put(sku, DEFAULT_PRICE_FOR_MISSING_SKUS);
                }
            }
            return prices;
        }

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        Set<String> encodedSkus = new Set<String>();
        for (String sku : skus) {
            encodedSkus.add(EncodingUtil.urlEncode(sku, 'UTF-8'));
        }

        // To access the service below you may need to add endpoint = https://example.com in Setup | Security | Remote site settings.
        request.setEndpoint('https://example.com/get-sales-prices?skus=' + JSON.serialize(encodedSkus));
        request.setMethod('GET');
        HttpResponse r = http.send(request);

        if (r.getStatusCode() != 200) {
            // return null in case of not successful response from 3rd party service
            return null;
        }

        // example response {"SKU-25-10028":0.00, "SKU-25-10030":0.00, "SKU_FOR_TEST":100.00}
        return (Map<String, Decimal>) JSON.deserialize(r.getBody(), Map<String, Decimal>.class);
    }
}
