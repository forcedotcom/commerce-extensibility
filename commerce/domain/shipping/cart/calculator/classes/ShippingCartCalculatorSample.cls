// This sample is for the situations where Shipping Calculation needs to be extended or overridden via the extension point for the Shipping Calculator.
//The Custom Apex Class must be linked to the Shipping Calculator extension point and then the integration must be linked to the webstore via appropriate Setup

//This must extend the CartExtension.ShippingCartCalculator class in order to be processed.
public class ShippingCartCalculatorSample extends CartExtension.ShippingCartCalculator {

    public virtual override void calculate(CartExtension.CartCalculationRequest request) {

        CartExtension.Cart cart = request.getCart();

        //Clean up CVO based on Shipping
        CartExtension.CartValidationOutputCollection cartValidationOutputCollection  = cart.getCartValidationOutputs();

        for (Integer i = (cartValidationOutputCollection.size()-1) ; i>= 0 ; i--){
                CartExtension.CartValidationOutput cvo =  cartValidationOutputCollection.get(i);
                if(cvo.getType() == sCartExtension.CartValidationOutputTypeEnum.SHIPPING){
                    cartValidationOutputCollection.remove(cvo);
           }
        }


        // We need to get the ID of the cart delivery group in order to create the Cart delivery group Methods.
        CartExtension.CartDeliveryGroupCollection cartDeliveryGroups = cart.getCartDeliveryGroups();
        if(cartDeliveryGroups.size() == 0){
            CartExtension.CartValidationOutput cvo = new CartExtension.CartValidationOutput(CartExtension.CartValidationOutputTypeEnum.SHIPPING,
                    CartExtension.CartValidationOutputLevelEnum.ERROR );
            cvo.setMessage('No Cart Delivery Groups have been defined');
            cartValidationOutputCollection.add(cvo);
        }

        else {

            CartExtension.CartItemCollection cartItems = cart.getCartItems();
            Integer numberOfUniqueItems = cartItems.size();


            CartExtension.CartDeliveryGroup cartDeliveryGroup = cartDeliveryGroups.get(0);

            CartExtension.CartDeliveryGroupMethodCollection cartDeliveryGroupMethods = cartDeliveryGroup.getCartDeliveryGroupMethods();

            //clean up the CartDeliveryGroupMethods
            for (Integer i = (cartDeliveryGroupMethods.size()-1) ; i>= 0 ; i--){
            CartExtension.CartDeliveryGroupMethod method = cartDeliveryGroupMethods.get(i);
            cartDeliveryGroupMethods.remove(method);
            }

            // Get shipping options, including aspects like rates and carriers, from the external service.
            ShippingOptionsAndRatesFromExternalService[] shippingOptionsAndRatesFromExternalService = getShippingOptionsAndRatesFromExternalService(numberOfUniqueItems);

            // Create a CartDeliveryGroupMethod record for every shipping option returned from the external service and every Order Delivery Method which matches
            populateCartDeliveryGroupMethodWithShippingOptions(shippingOptionsAndRatesFromExternalService, cartDeliveryGroupMethods, cartValidationOutputCollection);

        }
    }

    //Note: This method in the sample currently only takes in numberOfUniqueItems as an input, but the parameter list may be expanded in real-world scenarios
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
            CartExtension.CartDeliveryGroupMethodCollection cartDeliveryGroupMethodCollection, CartExtension.CartValidationOutputCollection cartValidationOutputCollection) {
        List<OrderDeliveryMethod> odms = [SELECT Id, ProductId, Carrier, ClassOfService, IsActive FROM OrderDeliveryMethod];

        if(odms.size()==0){
            CartExtension.CartValidationOutput cvo = new CartExtension.CartValidationOutput(CartExtension.CartValidationOutputTypeEnum.SHIPPING,
                    CartExtension.CartValidationOutputLevelEnum.ERROR );
            cvo.setMessage('No Order Delivery Methods have been defined');
            cartValidationOutputCollection.add(cvo);
        }

        else{
              for (ShippingOptionsAndRatesFromExternalService shippingOption: shippingOptions) {
                 for(OrderDeliveryMethod odm :odms){
                    String carrier = shippingOption.serviceName;
                    String classOfService = shippingOption.provider;
                    String odmId = Id.valueOf((String)odm.id);
                    if(odm.carrier == carrier && odm.classOfService == classOfService){
                        // Create a CartDeliveryGroupMethod record for every shipping option returned from the external service
                        CartExtension.CartDeliveryGroupMethod cartDeliveryGroupMethod = new CartExtension.CartDeliveryGroupMethod(shippingOption.getName(),odmId, shippingOption.getRate());
                        cartDeliveryGroupMethod.setExternalProvider(shippingOption.getProvider());
                        cartDeliveryGroupMethodCollection.add(cartDeliveryGroupMethod);
                    }
                }
            }
        }
    }
}
