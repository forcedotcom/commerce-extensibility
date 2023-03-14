public class CustomerShippingCalculator extends sfdc_cart_summ.Commerce_Domain_Cart_ShippingCalculator_1 {

    public virtual override void calculate(sfdc_cart_summ.CartCalculationRequest request) {
        //Clean up CVO based on Shipping

        sfdc_cart_summ.Cart cart = request.getCart();
        System.debug('In Shipping Calculator');

        //Clean up CVO based on Shipping
        sfdc_cart_summ.CartValidationOutputCollection cartValidationOutputCollection  = cart.getCartValidationOutputs();
        
        for (Integer i = (cartValidationOutputCollection.size()-1) ; i>= 0 ; i--){
                sfdc_cart_summ.CartValidationOutput cvo =  cartValidationOutputCollection.get(i);
                if(cvo.getType() == sfdc_cart_summ.CartValidationOutputTypeEnum.SHIPPING){
                    cartValidationOutputCollection.remove(cvo);
           }
        } 
        

        // We need to get the ID of the cart delivery group in order to create the Cart delivery group Methods.
        sfdc_cart_summ.CartDeliveryGroupCollection cartDeliveryGroups = cart.getCartDeliveryGroups();
        if(cartDeliveryGroups.size() == 0){
            sfdc_cart_summ.CartValidationOutput cvo = new sfdc_cart_summ.CartValidationOutput(sfdc_cart_summ.CartValidationOutputTypeEnum.SHIPPING,
                    sfdc_cart_summ.CartValidationOutputLevelEnum.INFO );
            cvo.setMessage('No Cart Delivery Groups have been defined');
            cartValidationOutputCollection.add(cvo);
        }

        else {
        
            sfdc_cart_summ.CartItemCollection cartItems = cart.getCartItems();
            Integer numberOfUniqueItems = cartItems.size();
            
            
            sfdc_cart_summ.CartDeliveryGroup cartDeliveryGroup = cartDeliveryGroups.get(0);

            sfdc_cart_summ.CartDeliveryGroupMethodCollection cartDeliveryGroupMethods = cartDeliveryGroup.getCartDeliveryGroupMethods();
            
            System.debug('Before delete'+ cartDeliveryGroupMethods.size());
            
            for (Integer i = (cartDeliveryGroupMethods.size()-1) ; i>= 0 ; i--){
            sfdc_cart_summ.CartDeliveryGroupMethod method = cartDeliveryGroupMethods.get(i);
            cartDeliveryGroupMethods.remove(method);
            } 
            
            System.debug('After delete'+ cartDeliveryGroupMethods.size());
            
            // Get shipping options, including aspects like rates and carriers, from the external service.
            ShippingOptionsAndRatesFromExternalService[] shippingOptionsAndRatesFromExternalService = getShippingOptionsAndRatesFromExternalService(numberOfUniqueItems);
            
            // Create a CartDeliveryGroupMethod record for every shipping option returned from the external service and every Order Delivery Method which matches
            populateCartDeliveryGroupMethodWithShippingOptions(shippingOptionsAndRatesFromExternalService, cartDeliveryGroupMethods, cartValidationOutputCollection);
      
        }
    }
    
    private ShippingOptionsAndRatesFromExternalService[] getShippingOptionsAndRatesFromExternalService (Integer numberOfUniqueItems) {
        final Integer SuccessfulHttpRequest = 200;

        ShippingOptionsAndRatesFromExternalService[] shippingOptions = new List<ShippingOptionsAndRatesFromExternalService>();

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        // To access the service below, you may need to add endpoint = https://b2b-commerce-test.herokuapp.com in Setup | Security | Remote site settings.
        request.setEndpoint('https://b2b-commerce-test.herokuapp.com/calculate-shipping-rates-winter-21');
        request.setMethod('GET');
        HttpResponse response = http.send(request);

        // If the request is successful, parse the JSON response.
        // The response looks like this:
        // [{"status":"calculated","rate":{"name":"Delivery Method 1","serviceName":"Test Carrier 1","serviceCode":"SNC9600","shipmentCost":11.99,"otherCost":5.99}},
        // {"status":"calculated","rate":{"name":"Delivery Method 2","serviceName":"Test Carrier 2","serviceCode":"SNC9600","shipmentCost":15.99,"otherCost":6.99}}]
        if (response.getStatusCode() == SuccessfulHttpRequest) {
            List<Object> results = (List<Object>) JSON.deserializeUntyped(response.getBody());
            for (Object result: results) {
                Map<String, Object> subresult = (Map<String, Object>) result;
                Map<String, Object> providerAndRate = (Map<String, Object>) subresult.get('rate');
                shippingOptions.add( new ShippingOptionsAndRatesFromExternalService(
                        (String) providerAndRate.get('name'),
                        (String) providerAndRate.get('serviceCode'),
                        (Decimal) providerAndRate.get('shipmentCost') * numberOfUniqueItems, // Multiply so shipping costs can change; remove when using a real shipping provider
                        (Decimal) providerAndRate.get('otherCost'),
                        (String) providerAndRate.get('serviceName')
                ));
            }
            return shippingOptions;
        }
        else {
            // Make it as a CVO of the type Shipping or keep it as CartSummaryAdminException?
            throw new CalloutException('There was a problem with the request. Error: ' + response.getStatusCode());
        }
    }

    // Structure to store the shipping options retrieved from external service.
    Class ShippingOptionsAndRatesFromExternalService {
        private String name;
        private String provider;
        private Decimal rate;
        private Decimal otherCost;
        private String serviceName;

        public ShippingOptionsAndRatesFromExternalService(String someName, String someProvider, Decimal someRate, Decimal someOtherCost, String someServiceName) {
            name = someName;
            provider = someProvider;
            rate = someRate;
            otherCost = someOtherCost;
            serviceName = someServiceName;
        }

        public String getProvider() {
            return provider;
        }

        public Decimal getRate() {
            return rate;
        }

        public Decimal getOtherCost() {
            return otherCost;
        }

        public String getServiceName() {
            return serviceName;
        }

        public String getName() {
            return name;
        }
    }
    
    private void populateCartDeliveryGroupMethodWithShippingOptions(List<ShippingOptionsAndRatesFromExternalService> shippingOptions,
            sfdc_cart_summ.CartDeliveryGroupMethodCollection cartDeliveryGroupMethodCollection, sfdc_cart_summ.CartValidationOutputCollection cartValidationOutputCollection) {
        List<OrderDeliveryMethod> odms = [SELECT Id, ProductId, Carrier, ClassOfService, IsActive FROM OrderDeliveryMethod];
        
        if(odms.size()==0){
            sfdc_cart_summ.CartValidationOutput cvo = new sfdc_cart_summ.CartValidationOutput(sfdc_cart_summ.CartValidationOutputTypeEnum.SHIPPING,
                    sfdc_cart_summ.CartValidationOutputLevelEnum.INFO );
            cvo.setMessage('No Order Delivery Methods have been defined');
            cartValidationOutputCollection.add(cvo);
        }
       
        else{
            for(OrderDeliveryMethod odm :odms){
                for (ShippingOptionsAndRatesFromExternalService shippingOption: shippingOptions) {
                    String carrier = shippingOption.serviceName;
                    String classOfService = shippingOption.provider;
                    String odmId = Id.valueOf((String)odm.id);
                    if(odm.carrier == carrier && odm.classOfService == classOfService){
                        // Create a CartDeliveryGroupMethod record for every shipping option returned from the external service
                        sfdc_cart_summ.CartDeliveryGroupMethod cartDeliveryGroupMethod = new sfdc_cart_summ.CartDeliveryGroupMethod(shippingOption.getName(),odmId, shippingOption.getRate());
                        cartDeliveryGroupMethod.setExternalProvider(shippingOption.getProvider());
                        cartDeliveryGroupMethodCollection.add(cartDeliveryGroupMethod);
                    }
                }
            }
        }
    }
}