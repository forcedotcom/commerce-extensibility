// The example for Tax Calculator includes an Apex class (CustomerTaxCalculator.apex) that makes a call to an external service
// to retrieve tax information and saves it to cart tax of cart dtos(salesforce structure).
// This must implement the sfdc_cart_summ.Commerce_Domain_Cart_TaxCalculator_1 interface in order to be processed by
// the checkout flow and used for your Taxes integration.
// This implementation is just a sample with hardcoded Heroku api call to fetch Tax information and MUST NOT be used in production systems.
// The function getTaxRatesAndAmountsFromExternalService gives you the facility to call any external service
// to get tax data. Right now its configured with a sample heroku api.
public class CustomerTaxCalculator extends sfdc_cart_summ.Commerce_Domain_Cart_TaxCalculator_1 {
    public virtual override void calculate(sfdc_cart_summ.CartCalculationRequest request) {
        try
            {
            sfdc_cart_summ.Cart cart = request.getCart();
            System.debug('In Tax Calculator');

            // Clean up CVO based on Tax. When new tax calculator request comes, we need to clean up previous
            // CVOs as they have been previously handled by cart summary apis.
            sfdc_cart_summ.CartValidationOutputCollection cartValidationOutputCollection  = cart.getCartValidationOutputs();
            for (Integer i = (cartValidationOutputCollection.size()-1) ; i>= 0 ; i--) {
                sfdc_cart_summ.CartValidationOutput cvo =  cartValidationOutputCollection.get(i);
                if(cvo.getType() == sfdc_cart_summ.CartValidationOutputTypeEnum.TAXES) {
                    cartValidationOutputCollection.remove(cvo);
                }
            }

            // there should be one delivery group per cart
            // In the future, when multiple delivery groups can be created,
            // this sample should be updated to loop through all delivery groups.
            sfdc_cart_summ.CartDeliveryGroupCollection cartDeliveryGroups = cart.getCartDeliveryGroups();
            sfdc_cart_summ.CartDeliveryGroup cartDeliveryGroup = cartDeliveryGroups.get(0);

            // create map of product SKU to cart item id
            // create map of product SKU to total price
            Map<String, String> cartItemIdsBySKU = new Map<String, String>();
            Map<String, Decimal> cartItemTotalPriceBySKU = new Map<String, Decimal>();
            sfdc_cart_summ.CartItemCollection cartItemCollection = cart.getCartItems();
            for (Integer i = (cartItemCollection.size()-1) ; i>= 0 ; i--) {
                String cartItemSKU = '';
                if (cartItemCollection.get(i).getType() == sfdc_cart_summ.SalesItemTypeEnum.Product) {
                    if (!String.isBlank(cartItemCollection.get(i).getSku())) {
                        cartItemSKU = cartItemCollection.get(i).getSku();
                    }
                }
                else if (cartItemCollection.get(i).getType() == sfdc_cart_summ.SalesItemTypeEnum.Charge) {
                    // This is an example for a Cart Item of type shipping charge.
                    // For simplicity and testing purposes, we just assign some SKU to this charge so that the taxation external service returns some value.
                    cartItemSKU = 'ChargeSKU';
                }
                cartItemIdsBySKU.put(cartItemSKU, cartItemCollection.get(i).getId());
                cartItemTotalPriceBySKU.put(cartItemSKU, cartItemCollection.get(i).getTotalPrice());
            }

            Get the tax rates and tax amounts from an external service
            Map<String, TaxDataFromExternalService> rateAndAmountFromExternalServicePerSku = getTaxRatesAndAmountsFromExternalService(
            cartItemTotalPriceBySKU, CartDeliveryGroup.getDeliverToAddress().getCountryCode(), CartDeliveryGroup.getDeliverToAddress().getStateCode());

            // This is a case product invalidation. Add product to cvo if no tax details are returned for that sku.
            boolean isCvoPresent = false;
            for (String sku : cartItemIdsBySKU.keySet()) {
                TaxDataFromExternalService rateAndAmountFromExternalService = rateAndAmountFromExternalServicePerSku.get(sku);
                if (rateAndAmountFromExternalService == null){
                    // add cvo output
                    sfdc_cart_summ.CartValidationOutput cvo = new sfdc_cart_summ.CartValidationOutput(sfdc_cart_summ.CartValidationOutputTypeEnum.TAXES,
                    sfdc_cart_summ.CartValidationOutputLevelEnum.INFO);
                    cvo.setMessage('No Taxes available for this item.');
                    cartValidationOutputCollection.add(cvo);
                    isCvoPresent = true;
                }
            }
            if(isCvoPresent == true)
            return ;

            // If the sku was found in the external system, add a new CartTax line for that sku
            // The following fields from CartTax can be filled in:
            // Amount (required): Calculated tax amount.
            // Name (required): Name of the tax. (TODO - not present in salesforce cart tax dto structure)
            // TaxRate (optional): The percentage value of the tax. Null if the tax is a flat amount.
            // TaxType (required): The type of tax, e.g. Actual or Estimated.
            for (Integer i = (cartItemCollection.size()-1) ; i>= 0 ; i--) {
                TaxDataFromExternalService rateAndAmountFromExternalService = rateAndAmountFromExternalServicePerSku.get(cartItemCollection.get(i).getSku());
                sfdc_cart_summ.CartTaxCollection cartTaxCollection  = cartItemCollection.get(i).getCartTaxes();
                // In case of CREATE (new cart item): if there is no existing cart tax then create new.
                // In case of MODIFY (modified cart item): clear existing cartTaxDto and create new.
                if(cartTaxCollection.size() != 0 && rateAndAmountFromExternalService.getAmount() != cartTaxCollection.get(0).getAmount()) {
                    cartTaxCollection.remove(cartTaxCollection.get(0));
                }
                if(cartTaxCollection.size() == 0) {
                    sfdc_cart_summ.CartTax cartTax = new sfdc_cart_summ.CartTax(sfdc_cart_summ.TaxTypesEnum.ACTUAL, rateAndAmountFromExternalService.getAmount());
                    cartTax.setTaxRate(String.valueOf(rateAndAmountFromExternalService.getRate()));
                    cartTaxCollection.add(cartTax);
                }
            }
        } catch(Exception e) {
            // For testing purposes, this example treats exceptions as user errors, which means they are displayed to the buyer user.
            // In production you probably want this to be an admin-type error. In that case, throw the exception here
            // and make sure that a notification system is in place to let the admin know that the error occurred.
            // See the readme section about error handling for details about how to create that notification.
            throw new CalloutException ('There was a problem with the request.');
        }
        return ;
    }

    private Map<String, TaxDataFromExternalService> getTaxRatesAndAmountsFromExternalService (
    Map<String, Decimal> cartItemTotalAmountBySKU, String state, String country) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        Integer SuccessfulHttpRequest = 200;
        String encodedState = (state == null) ? '' : EncodingUtil.urlEncode(state, 'UTF-8').replace('+', '%20');
        String encodedCountry = (country == null) ? '' : EncodingUtil.urlEncode(country, 'UTF-8').replace('+', '%20');

        Map<String, Decimal> encodedCartItemTotalAmountBySKU = new Map<String, Decimal>();
        for(String sku: cartItemTotalAmountBySKU.keySet()) {
            encodedCartItemTotalAmountBySKU.put(EncodingUtil.urlEncode(sku, 'UTF-8'), cartItemTotalAmountBySKU.get(sku));
        }

        // To access the service below, you may need to add endpoint = https://b2b-commerce-test.herokuapp.com in Setup | Security | Remote site settings.
        String requestURL = 'https://b2b-commerce-test.herokuapp.com/get-tax-rates?state=' + encodedState
        + '&country=' + encodedCountry
        + '&amountsBySKU=' + JSON.serialize(encodedCartItemTotalAmountBySKU);
        request.setEndpoint(requestURL);
        request.setMethod('GET');
        HttpResponse response = http.send(request);

        // If the request is successful, parse the JSON response;
        // The response includes the tax amount, rate, and name for each SKU. It looks something like this:
        // response = {"SKU_1_september10-1568355297":{"taxAmount":2.8229012971048855,"taxRate":0.08,"taxName":"GST"}};
        if (response.getStatusCode() == SuccessfulHttpRequest) {
            Map<String, Object> resultsFromExternalServiceBySKU = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            Map<String, TaxDataFromExternalService> taxDataFromExternalServiceBySKU = new Map<String, TaxDataFromExternalService>();
            for (String sku : resultsFromExternalServiceBySKU.keySet()) {
                Map<String, Object> rateAndAmountFromExternalService = (Map<String, Object>) resultsFromExternalServiceBySKU.get(sku);
                taxDataFromExternalServiceBySKU.put(sku, new TaxDataFromExternalService(
                (Decimal)rateAndAmountFromExternalService.get('taxRate'),
                (Decimal)rateAndAmountFromExternalService.get('taxAmount'),
                (String)rateAndAmountFromExternalService.get('taxName')
                ));
            }
            return taxDataFromExternalServiceBySKU;
        }
        else {
            throw new CalloutException ('There was a problem with the request. Error: ' + response.getStatusCode());
        }
    }

    // Structure to store the tax data retrieved from external service
    // This simplifies our ability to access it when storing it in Salesforce's CartTaxDto
    Class TaxDataFromExternalService {
        private Decimal rate;
        private Decimal amount;
        private String taxName;

        public TaxDataFromExternalService () {
            rate = 0.0;
            amount = 0.0;
            taxName = '';
        }

        public TaxDataFromExternalService (Decimal someRate, Decimal someAmount, String someTaxName) {
            rate = someRate;
            amount = someAmount;
            taxName = someTaxName;
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
    }
}
