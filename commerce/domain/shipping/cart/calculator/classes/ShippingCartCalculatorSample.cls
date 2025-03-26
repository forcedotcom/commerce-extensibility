// This sample is for the situations where Shipping Calculation needs to be extended or overridden
// via the extension point for the Shipping Calculator. The Custom Apex Class must be linked to the
// Shipping Calculator extension point and then the integration must be linked to the webstore via
// appropriate Setup

// This class must extend the CartExtension.ShippingCartCalculator class to be processed.
public class ShippingCartCalculatorSample extends CartExtension.ShippingCartCalculator {
  // You MUST change this to be your service or you must launch your own Third Party Service
  // and add the host in Setup | Security | Remote site settings.
  private static String externalShippingServiceHost = 'https://example.com';

  // You MUST change this to be your service or your URL
  private static String externalShippingURL = externalShippingServiceHost + '/calculate-shipping-rates';

  // You MUST change the useExternalService to True if you want to use the Third Party Service.
  private static Boolean useExternalService = false;

  public virtual override void calculate(CartExtension.CartCalculateCalculatorRequest request) {
    CartExtension.Cart cart = request.getCart();
    // Clean up CVO based on Shipping
    CartExtension.CartValidationOutputList cartValidationOutputList = cart.getCartValidationOutputs();

    for (Integer i = (cartValidationOutputList.size() - 1); i >= 0; i--) {
      CartExtension.CartValidationOutput cvo = cartValidationOutputList.get(i);
      if (cvo.getType() == CartExtension.CartValidationOutputTypeEnum.SHIPPING) {
        cartValidationOutputList.remove(cvo);
      }
    }

    // To create the Cart delivery group methods, we need to get the ID of the cart delivery group.
    CartExtension.CartDeliveryGroupList cartDeliveryGroups = cart.getCartDeliveryGroups();
    if (cartDeliveryGroups.size() == 0) {
      CartExtension.CartValidationOutput cvo = new CartExtension.CartValidationOutput(
        CartExtension.CartValidationOutputTypeEnum.SHIPPING,
        CartExtension.CartValidationOutputLevelEnum.ERROR
      );
      cvo.setMessage('No Cart Delivery Groups have been defined');
      cartValidationOutputList.add(cvo);
    } else {
      CartExtension.CartItemList cartItems = cart.getCartItems();
      Integer numberOfUniqueItems = cartItems.size();

      for (Integer i = (cartDeliveryGroups.size() - 1); i >= 0; i--) {
        CartExtension.CartDeliveryGroup cartDeliveryGroup = cartDeliveryGroups.get(i);
        CartExtension.CartDeliveryGroupMethodList cartDeliveryGroupMethods = cartDeliveryGroup.getCartDeliveryGroupMethods();
        CartExtension.CartDeliveryGroupMethod selectedDeliveryMethod =  cartDeliveryGroup.getSelectedCartDeliveryGroupMethod();

        // Clean up the CartDeliveryGroupMethods except already selected Delivery method
        for (Integer j = (cartDeliveryGroupMethods.size() - 1); j >= 0; j--) {
          CartExtension.CartDeliveryGroupMethod method = cartDeliveryGroupMethods.get(j);
          // remove cart delivery group methods if selectedDeliveryMethod is null or delivery method id not matching with selectedDeliveryMethodId
          if(selectedDeliveryMethod==null || (selectedDeliveryMethod!=null && !method.getId().equals(selectedDeliveryMethod.getId()))) {
            cartDeliveryGroupMethods.remove(method);
          }
        }

        // Get the Shipping Product
        List<Product2> shippingProducts = [SELECT Id FROM Product2 WHERE ProductClass != 'VariationParent' LIMIT 1];
        if(shippingProducts.size() == 0) {
          CartExtension.CartValidationOutput cvo = new CartExtension.CartValidationOutput(CartExtension.CartValidationOutputTypeEnum.SHIPPING,
                  CartExtension.CartValidationOutputLevelEnum.ERROR );
          cvo.setMessage('No Shipping Products have been defined');
          cartValidationOutputList.add(cvo);
        } else {
          String shippingProduct = Id.valueOf(shippingProducts[0].Id);
          // Create a CartDeliveryGroupMethod record for every shipping option returned from the external service
          if(useExternalService) {
              // Get shipping options, including aspects like rates and carriers, from the external service.
              ShippingOptionsAndRatesFromExternalService[] shippingOptionsAndRatesFromExternalService = getShippingOptionsAndRatesFromExternalService(
                numberOfUniqueItems, cartValidationOutputList
                );

                // Create a CartDeliveryGroupMethod record for every shipping option returned from the external
                // service and every Order Delivery Method that matches
                if(shippingOptionsAndRatesFromExternalService != null){
                populateCartDeliveryGroupMethodWithShippingOptions(
                  shippingOptionsAndRatesFromExternalService,
                  cartDeliveryGroupMethods,shippingProduct,
                  cartValidationOutputList, selectedDeliveryMethod
                );
              }
          } else {
        // this block is for static response for sample class
          if(selectedDeliveryMethod==null ||
          (selectedDeliveryMethod!=null &&
            !('Ground Shipping'.equals(selectedDeliveryMethod.getName()) &&
           selectedDeliveryMethod.getShippingFee().equals(10.99) &&
           selectedDeliveryMethod.getCarrier().equals('USPS') &&
           selectedDeliveryMethod.getClassOfService().equals('Ground Shipping') &&
           selectedDeliveryMethod.getTransitTimeMin().equals(1) &&
           selectedDeliveryMethod.getTransitTimeMax().equals(3) &&
           selectedDeliveryMethod.getTransitTimeUnit().equals(CartExtension.TimeUnitEnum.DAYS) &&
           selectedDeliveryMethod.getProcessTime().equals(1) &&
           selectedDeliveryMethod.getProcessTimeUnit().equals(CartExtension.TimeUnitEnum.WEEKS)))) {
           CartExtension.CartDeliveryGroupMethod cartDeliveryGroupMethod01 = new CartExtension.CartDeliveryGroupMethod('Ground Shipping', 10.99, shippingProduct);
            cartDeliveryGroupMethod01.setCarrier('USPS');
            cartDeliveryGroupMethod01.setClassOfService('Ground Shipping');
            cartDeliveryGroupMethod01.setTransitTimeMin(1);
            cartDeliveryGroupMethod01.setTransitTimeMax(3);
            cartDeliveryGroupMethod01.setTransitTimeUnit(CartExtension.TimeUnitEnum.DAYS);
            cartDeliveryGroupMethod01.setProcessTime(1);
            cartDeliveryGroupMethod01.setProcessTimeUnit(CartExtension.TimeUnitEnum.WEEKS);
            cartDeliveryGroupMethods.add(cartDeliveryGroupMethod01);
            }

            if(selectedDeliveryMethod==null ||
                         (selectedDeliveryMethod!=null &&
            !('Next Day Air'.equals(selectedDeliveryMethod.getName()) &&
                       selectedDeliveryMethod.getShippingFee().equals(15.99) &&
                       selectedDeliveryMethod.getCarrier().equals('UPS') &&
                       selectedDeliveryMethod.getClassOfService().equals('Next Day Air') &&
                       selectedDeliveryMethod.getTransitTimeMin().equals(1) &&
                       selectedDeliveryMethod.getTransitTimeMax().equals(4) &&
                       selectedDeliveryMethod.getTransitTimeUnit().equals(CartExtension.TimeUnitEnum.DAYS) &&
                       selectedDeliveryMethod.getProcessTime().equals(1) &&
                       selectedDeliveryMethod.getProcessTimeUnit().equals(CartExtension.TimeUnitEnum.DAYS)))) {
            CartExtension.CartDeliveryGroupMethod cartDeliveryGroupMethod02 = new CartExtension.CartDeliveryGroupMethod('Next Day Air', 15.99, shippingProduct);
            cartDeliveryGroupMethod02.setCarrier('UPS');
            cartDeliveryGroupMethod02.setClassOfService('Next Day Air');
            cartDeliveryGroupMethod02.setTransitTimeMin(1);
            cartDeliveryGroupMethod02.setTransitTimeMax(4);
            cartDeliveryGroupMethod02.setTransitTimeUnit(CartExtension.TimeUnitEnum.DAYS);
            cartDeliveryGroupMethod02.setProcessTime(1);
            cartDeliveryGroupMethod02.setProcessTimeUnit(CartExtension.TimeUnitEnum.DAYS);
            cartDeliveryGroupMethods.add(cartDeliveryGroupMethod02);
            }
          }
        }
      }
    }
  }

   private static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
        Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
        randStr += chars.substring(idx, idx+1);
        }
        return randStr;
    }

  // Note: This sample method currently only takes in numberOfUniqueItems as an input parameter. For
  // real-world scenarios, expand the parameter list.
  private ShippingOptionsAndRatesFromExternalService[] getShippingOptionsAndRatesFromExternalService(
    Integer numberOfUniqueItems, CartExtension.CartValidationOutputList cartValidationOutputCollection) {
    final Integer SuccessfulHttpRequest = 200;
    ShippingOptionsAndRatesFromExternalService[] shippingOptions = new List<ShippingOptionsAndRatesFromExternalService>();
    Http http = new Http();
    HttpRequest request = new HttpRequest();
    request.setEndpoint(externalShippingURL);
    request.setMethod('GET');
    HttpResponse response = http.send(request);

    // If the request is successful, parse the JSON response. The response looks like this:
    // [{"status":"calculated","rate":{"name":"Delivery Method 1","serviceName":"Test Carrier 1","serviceCode":"SNC9600","shipmentCost":11.99,"otherCost":5.99}}, undefined undefined
    // {"status":"calculated","rate":{"name":"Delivery Method 2","serviceName":"Test Carrier
    // 2","serviceCode":"SNC9600","shipmentCost":15.99,"otherCost":6.99}}]
    if (response.getStatusCode() == SuccessfulHttpRequest) {
      List<Object> results = (List<Object>) JSON.deserializeUntyped(response.getBody());
      for (Object result : results) {
        Map<String, Object> subresult = (Map<String, Object>) result;
        Map<String, Object> providerAndRate = (Map<String, Object>) subresult.get('rate');
        shippingOptions.add( new ShippingOptionsAndRatesFromExternalService(
                   (String) providerAndRate.get('name'),
                   (String) providerAndRate.get('serviceCode'),
                   (Decimal) providerAndRate.get('shipmentCost'),
                   (Decimal) providerAndRate.get('otherCost'),
                   (String) providerAndRate.get('serviceName'),
                   (String) providerAndRate.get('serviceName'),
                   (String) providerAndRate.get('serviceCode'),
                   generateRandomString(10),
                   true,
                   (Integer) providerAndRate.get('transitTimeMin'),
                   (Integer) providerAndRate.get('transitTimeMax'),
                   (CartExtension.TimeUnitEnum) providerAndRate.get('transitTimeUnit'),
                   (Integer) providerAndRate.get('processTime'),
                   (CartExtension.TimeUnitEnum) providerAndRate.get('processTimeUnit')
               ));
      }
      return shippingOptions;
    } else {
       String errorMessage = 'We failed to calculate shipping options for your cart.';
       if(response.getStatusCode() == 404) {
              errorMessage = '404. You must create a sample application or add your own service which returns a valid response';
        }

        // Create a CVO with the Error
        CartExtension.CartValidationOutput cvo = new CartExtension.CartValidationOutput(
          CartExtension.CartValidationOutputTypeEnum.SHIPPING,
          CartExtension.CartValidationOutputLevelEnum.ERROR
        );
        cvo.setMessage(errorMessage);
        cartValidationOutputCollection.add(cvo);
        return null;
    }
  }

  // Structure to store the shipping options retrieved from external service.
  Class ShippingOptionsAndRatesFromExternalService {
       private String name;
       private String provider;
       private Decimal rate;
       private Decimal otherCost;
       private String serviceName;
       private String carrier;
       private String classOfService;
       private String referenceNumber;
       private Boolean isActive;
       private Integer transitTimeMin;
       private Integer transitTimeMax;
       private CartExtension.TimeUnitEnum transitTimeUnit;
       private Integer processTime;
       private CartExtension.TimeUnitEnum processTimeUnit;

       public ShippingOptionsAndRatesFromExternalService() {
           name = '';
           provider = '';
           rate = 0.0;
           serviceName = '';
           otherCost = 0.0;
           carrier = '';
           classOfService = '';
           referenceNumber = '';
           isActive = true;
           transitTimeMin = 0;
           transitTimeMax = 0;
           transitTimeUnit = null;
           processTime = 0;
           processTimeUnit = null;
       }

       public ShippingOptionsAndRatesFromExternalService(String someName, String someProvider, Decimal someRate, Decimal someOtherCost, String someServiceName,
               String someCarrier, String someClassOfService, String someReferenceNumber, Boolean someIsActive,
               Integer someTransitTimeMin, Integer someTransitTimeMax,CartExtension.TimeUnitEnum someTransitTimeUnit, Integer someProcessTime,
               CartExtension.TimeUnitEnum someProcessTimeUnit) {
           name = someName;
           provider = someProvider;
           rate = someRate;
           otherCost = someOtherCost;
           serviceName = someServiceName;
           carrier = someCarrier;
           classOfService = someClassOfService;
           referenceNumber = someReferenceNumber;
           isActive = someIsActive;
           transitTimeMin = someTransitTimeMin;
           transitTimeMax = someTransitTimeMax;
           transitTimeUnit = someTransitTimeUnit;
           processTime = someProcessTime;
           processTimeUnit = someProcessTimeUnit;
       }

       public String getProvider() { return provider; }
       public Decimal getRate() { return rate; }
       public Decimal getOtherCost() { return otherCost; }
       public String getServiceName() { return serviceName; }
       public String getName() { return name; }
       public String getCarrier() { return carrier; }
       public String getClassOfService() { return classOfService; }
       public String getReferenceNumber() { return referenceNumber; }
       public Boolean isActive() { return isActive; }
       public Integer getTransitTimeMin() { return transitTimeMin; }
       public Integer getTransitTimeMax() { return transitTimeMax; }
       public CartExtension.TimeUnitEnum getTransitTimeUnit() { return transitTimeUnit; }
       public Integer getProcessTime() { return processTime; }
       public CartExtension.TimeUnitEnum getProcessTimeUnit() { return processTimeUnit; }
   }


  private void populateCartDeliveryGroupMethodWithShippingOptions(
   List<ShippingCartCalculatorSample.ShippingOptionsAndRatesFromExternalService> shippingOptions,
   CartExtension.CartDeliveryGroupMethodList cartDeliveryGroupMethodCollection,
   String shippingProduct,
   CartExtension.CartValidationOutputList cartValidationOutputCollection,
   CartExtension.CartDeliveryGroupMethod selectedDeliveryMethod
 ) {
     for (ShippingOptionsAndRatesFromExternalService shippingOption : shippingOptions) {
       //if selected CDGM is matching with shipping option then we don't need to create shipping option and existing can be reused
        if(!isShippingOptionMatchingWithSelectedDM(shippingOption,selectedDeliveryMethod)){
            String carrier = shippingOption.serviceName;
            String classOfService = shippingOption.provider;
            // Create a CartDeliveryGroupMethod for every shipping option returned from the external
            // service
            CartExtension.CartDeliveryGroupMethod cartDeliveryGroupMethod = new CartExtension.CartDeliveryGroupMethod(
                shippingOption.getName(),
                shippingOption.getRate(),
                shippingProduct
            );
            cartDeliveryGroupMethod.setExternalProvider(shippingOption.getProvider());
            cartDeliveryGroupMethod.setCarrier(shippingOption.getCarrier());
            cartDeliveryGroupMethod.setClassOfService(shippingOption.getClassOfService());
            cartDeliveryGroupMethod.setIsActive(shippingOption.isActive());
            cartDeliveryGroupMethod.setReferenceNumber(shippingOption.getReferenceNumber());
            cartDeliveryGroupMethodCollection.add(cartDeliveryGroupMethod);
            cartDeliveryGroupMethod.setTransitTimeMin(shippingOption.getTransitTimeMin());
            cartDeliveryGroupMethod.setTransitTimeMax(shippingOption.getTransitTimeMax());
            cartDeliveryGroupMethod.setTransitTimeUnit(shippingOption.getTransitTimeUnit());
            cartDeliveryGroupMethod.setProcessTime(shippingOption.getProcessTime());
            cartDeliveryGroupMethod.setProcessTimeUnit(shippingOption.getProcessTimeUnit());
           }
       }
    }

    /**
         This method compares previous Selected Delivery method with current shipping options and if both matches returns ture
     */
    private boolean isShippingOptionMatchingWithSelectedDM(ShippingOptionsAndRatesFromExternalService shippingOption, CartExtension.CartDeliveryGroupMethod previousSelectDeliveryMethod) {
        if(previousSelectDeliveryMethod != null) {
            // get delivery group method for seletctedDMId
            //CartDeliveryGroupMethod previousSelectDeliveryMethod = [SELECT Name, ShippingFee, WebCartId, Carrier, ClassOfService, ExternalProvider, ProductId, ReferenceNumber, IsActive, TransitTimeMin, TransitTimeMax, TransitTimeUnit, ProcessTime, ProcessTimeUnit FROM CartDeliveryGroupMethod WHERE Id= :previousSelectDeliveryMethodId];

            // return if all fields of shipping option matches with selectedDM else return false
            return (previousSelectDeliveryMethod.getName().equals(shippingOption.getName()) && // compare name
            previousSelectDeliveryMethod.getIsActive().equals(shippingOption.isActive()) && // compare isActive flag

            previousSelectDeliveryMethod.getShippingFee().equals(shippingOption.getRate()) &&  // compare shipping fee

            isNullOrEquals(previousSelectDeliveryMethod.getProcessTime(), shippingOption.getProcessTime()) && // compare time
            isNullOrEquals(previousSelectDeliveryMethod.getProcessTimeUnit(), shippingOption.getProcessTimeUnit()) && // compare time unit

            // ideally reference number should match but in this sample we are generating random string so won't match
            //previousSelectDeliveryMethod.getReferenceNumber().equals(shippingOption.getReferenceNumber()) &&
            previousSelectDeliveryMethod.getCarrier().equals(shippingOption.getCarrier()) &&
            previousSelectDeliveryMethod.getClassOfService().equals(shippingOption.getClassOfService()) &&
            previousSelectDeliveryMethod.getExternalProvider().equals(shippingOption.getProvider()) &&

            isNullOrEquals(previousSelectDeliveryMethod.getTransitTimeMax(), shippingOption.getTransitTimeMax()) && // compare transit time
            isNullOrEquals(previousSelectDeliveryMethod.getTransitTimeMin(), shippingOption.getTransitTimeMin()) &&
            isNullOrEquals(previousSelectDeliveryMethod.getTransitTimeUnit(), shippingOption.getTransitTimeUnit())); // compare transit time unit
        }
        // we will return false so DM can be created if no previous selected DM is null
        return false;
    }

    /**
        This method compares two objects, if both are null or equals returns true
    */
    private boolean isNullOrEquals(Object o1, Object o2) {
        return (o1 == null && o2 == null) || (o1 != null && o1.equals(o2));
    }
}
