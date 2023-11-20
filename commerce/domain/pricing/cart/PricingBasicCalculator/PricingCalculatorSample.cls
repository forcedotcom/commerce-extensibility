/**
* This Pricing calculator extension class makes a call to an external service or static to retrieve pricing
* information for a cart item and saves it to a cart data transfer object (DTO).
* For a pricing calculator extension to be processed by the checkout flow, you must implement the
* CartExtension.PricingCartCalculator class.
* This is just a sample for Pricing calculator, you are expected to refer this and write your own implementation.
*/
public class PricingCalculatorSample extends CartExtension.PricingCartCalculator {

    private Boolean useExternalService = false;

    /**
    * @description All classes extending CartExtension.AbstractCartCalculator must have a default constructor defined
    */
    public PricingCalculatorSample() {
        super();
    }

    public PricingCalculatorSample(Boolean useExternalService) {
        super();
        this.useExternalService = useExternalService;
    }

    public virtual override void calculate(CartExtension.CartCalculateCalculatorRequest request) {
        try {
            CartExtension.Cart cart = request.getCart();
            Iterator<CartExtension.CartItem> cartItemsIterator = clearErrorsAndGetCartItemsIterator(cart, request.getOptionalBuyerActionDetails());

            // Get the SKUs from each cart item that needs price calculations
            Map<String, CartExtension.CartItem> skuToCartItem = new Map<String, CartExtension.CartItem>();
            while (cartItemsIterator.hasNext()) {
                CartExtension.CartItem cartItem = cartItemsIterator.next();
                // Pricing service is expected to calculate prices for only product (not charges)
                if(cartItem.getType() == CartExtension.SalesItemTypeEnum.PRODUCT) {
                    skuToCartItem.put(cartItem.getSku(), cartItem);
                }
            }

            Map<String, PricingDataFromExternalService> pricingDataMap = retrievePriceData(skuToCartItem.keySet());

            if(pricingDataMap == Null) {
                // No data returned means there is an issue with underlying 3rd party service. Populate generic error message for the Buyer.
                CartExtension.CartValidationOutput cvo = new CartExtension.CartValidationOutput(
                CartExtension.CartValidationOutputTypeEnum.PRICING,
                CartExtension.CartValidationOutputLevelEnum.ERROR);
                cvo.setMessage('We are not able to process your cart. Please contact support.');
                cart.getCartValidationOutputs().add(cvo);
                return;
            }
            applyPricesToCartItems(cart, skuToCartItem.values().iterator(), pricingDataMap);
        }
        catch (Exception e) {
            throw new CartExtension.CartCalculateRuntimeException('An integration error occurred in COMPUTE_PRICES. Contact your admin.');
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

    private Map<String, PricingDataFromExternalService> retrievePriceData(Set<String> skus) {

        Map<String, PricingDataFromExternalService> dataFromExternalService = null;
        if(useExternalService){
            dataFromExternalService = getPricingFromExternalService(skus);
        } else{
            dataFromExternalService = getPricingFromStaticResponse(skus);
        }
        return dataFromExternalService;
    }

    /**
    * Handles pricing data response by external or static response and sets it to cart items.
    */
    private void applyPricesToCartItems(CartExtension.Cart cart, Iterator<CartExtension.CartItem> cartItemsIterator,
        Map<String, PricingDataFromExternalService> lineItemIdToPricingDetailsMap) {

        while (cartItemsIterator.hasNext()) {
            CartExtension.CartItem cartItem = cartItemsIterator.next();
            // Pricing service is expected to calculate prices for only product (not charges)
            if (cartItem.getType() == CartExtension.SalesItemTypeEnum.PRODUCT) {
                if(lineItemIdToPricingDetailsMap.get(cartItem.getSku()) == null) {
                    // No price available for the SKU in the Cart. Populate error message for the Buyer.
                    CartExtension.CartValidationOutput cvo = new CartExtension.CartValidationOutput(
                        CartExtension.CartValidationOutputTypeEnum.PRICING,
                        CartExtension.CartValidationOutputLevelEnum.ERROR,
                        cartItem);
                    cvo.setMessage('No price available for the SKU in the Cart.');
                    cart.getCartValidationOutputs().add(cvo);
                    continue;
                }
                setPricingFieldsOnCart(cartItem, lineItemIdToPricingDetailsMap.get(cartItem.getSku()));
            }
        }
    }

    /**
    * Sets pricing data returned by external service to Salesforce's CartItem
    */
    private void setPricingFieldsOnCart(CartExtension.CartItem item, PricingDataFromExternalService pricingLineItem){

        if (pricingLineItem != null) {
            item.setSalesPrice(pricingLineItem.getUnitPrice());
            item.setListPrice(pricingLineItem.getListPrice());
            item.setAdjustmentAmount(pricingLineItem.getTotalAdjustmentAmount());
            item.setTotalListPrice(pricingLineItem.getTotalListPrice());
            item.setTotalPrice(pricingLineItem.getTotalPrice());
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
    private Map<String, PricingDataFromExternalService> getPricingFromExternalService(Set<String> skus) {

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

        return (Map<String, PricingDataFromExternalService>) JSON.deserialize(r.getBody(), Map<String, PricingDataFromExternalService>.class);
    }

    /**
    * Returns a static pricing data map for all products.
    */
    private Map<String, PricingDataFromExternalService> getPricingFromStaticResponse(Set<String> skus) {

        Map<String, PricingDataFromExternalService> dataFromExternalService = new Map<String, PricingDataFromExternalService>();
        for(String sku: skus) {
            PricingDataFromExternalService pricingData = new PricingDataFromExternalService(10,10,9,20,20);
            dataFromExternalService.put(sku, pricingData);
        }
        return dataFromExternalService;
    }

    /**
    * Structure to store pricing data retrieved from external service. This class simplifies our
    * ability to access the data when storing it in Salesforce's CartItem.
    */
    class PricingDataFromExternalService {

        private Decimal unitPrice;
        private Decimal listPrice;
        private Decimal totalAdjustmentAmount;
        private Decimal totalListPrice;
        private Decimal totalPrice;

        public PricingDataFromExternalService() {
            unitPrice = 0.0;
            listPrice = 0.0;
            totalAdjustmentAmount = 0.0;
            totalListPrice = 0.0;
            totalPrice = 0.0;
        }

        public PricingDataFromExternalService(
        Decimal unitPriceObj,
        Decimal listPriceObj,
        Decimal totalAdjustmentAmountObj,
        Decimal totalListPriceObj,
        Decimal totalPriceObj ) {

            unitPrice = unitPriceObj;
            listPrice = listPriceObj;
            totalAdjustmentAmount = totalAdjustmentAmountObj;
            totalListPrice = TotalListPriceObj;
            totalPrice = totalPriceObj;
        }

        public Decimal getUnitPrice() {
            return unitPrice;
        }

        public Decimal getListPrice() {
            return listPrice;
        }

        public Decimal getTotalAdjustmentAmount() {
            return totalAdjustmentAmount;
        }

        public Decimal getTotalListPrice() {
            return totalListPrice;
        }

        public Decimal getTotalPrice() {
            return totalPrice;
        }

    }
}