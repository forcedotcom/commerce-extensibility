// This sample is for the situation when the tax behavior needs to be extended or overridden via the extension point for Salesforce Internal Tax Api.
// For Salesforce Internal Tax calculation, please see the corresponding documentation.

// Your custom apex class must be linked to the tax extension point and then the integration must be linked to the web store via appropriate setup.
// For more information related to that, please see the corresponding documentation.

// This must implement the commercestoretax.TaxService class in order to be processed by the tax service flow.
public class TaxServiceExtensionSample extends commercestoretax.TaxService {
    // You MUST change this to be your service.
    // and add the host in Setup | Security | Remote site settings.
    private static String httpHost = 'https://example.com';

    // If you are making valid external service call, make this flag as true.
    private static Boolean useHTTPService = false;

    // We will default the tax type to Gross in this example. This can be changed to Net if required.
    private static String taxType = 'Gross';

    // Override processGetStoreTaxesInfo method in order to change behavior of the tax treatments applied for a product.
    //
    // Fields that can be overridden are:
    // Header level - tax locale type: GROSS or NET, error.
    // Item level - tax rate percentage, tax treatment name, tax treatment description, priority, country iso code, state iso code, error.
    public override commercestoretax.GetStoreTaxesInfoResponse processGetStoreTaxesInfo(commercestoretax.GetStoreTaxesInfoRequest request) {
        try {
            // Call the default internal tax implementation with either original request or modified request.
            commercestoretax.GetStoreTaxesInfoResponse response = super.processGetStoreTaxesInfo(request);

            // Override tax rate percentage by increasing them by a fixed amount. Also, let us override treatment name and
            // description by appending a prefix to them in case customers use a different naming convention.
            Double fixedAmountIncrease = 2;
            String prefix = 'Customer_';
            commercestoretax.ProductIdCollection productIds = request.getProductIds();
            Map<String, commercestoretax.StoreTaxesInfoContainer> storeTaxesInfoContainerMap = response.getTaxesInfo();
            for(Integer i = 0; i < productIds.size(); i++){
                String productId = productIds.get(i);
                commercestoretax.StoreTaxesInfoContainer storeTaxesInfoContainer = storeTaxesInfoContainerMap.get(productId);
                commercestoretax.StoreTaxesInfoCollection storeTaxesInfoCollection = storeTaxesInfoContainer.getStoreTaxesInfoList();
                for (Integer j = 0; j < storeTaxesInfoCollection.size(); j++) {
                    commercestoretax.StoreTaxesInfo storeTaxesInfo = storeTaxesInfoCollection.get(j);
                    storeTaxesInfo.setTaxRatePercentage(storeTaxesInfo.getTaxRatePercentage() + fixedAmountIncrease);
                    storeTaxesInfo.setTaxTreatmentName(appendField(prefix, storeTaxesInfo.getTaxTreatmentName()));
                    storeTaxesInfo.setTaxTreatmentDescription(appendField(prefix, storeTaxesInfo.getTaxTreatmentDescription()));
                }
            }

            // You can modify tax locale type at header level, let us set it to NET for now.
            response.setTaxLocaleType(commercestoretax.TaxLocaleType.NET);

            // You can mark the response as Error as well.
            // For now, let us set first product as error.
            commercestoretax.StoreTaxesInfoContainer infoContainer = storeTaxesInfoContainerMap.get(productIds.get(0));
            infoContainer.setError('No tax settings available for this product.', 'Aucun paramètre de taxe disponible pour ce produit.');

            return response;
        } catch (Exception e) {
            // For testing purposes, this example treats exceptions as unexpected errors. This exception can be possibly from
            // super method call or possibly the logic after that. In production, you want these errors to be specific exceptions and
            // make sure that a notification system is in place to let the Salesforce admin know that the error has occurred.
            throw new UnexpectedException('There was a problem with the request.');
        }
    }

    // Override processCalculateTaxes method in order to change behavior of the tax calculations for line items in Salesforce native tax API.
    //
    // Fields that can be overridden are:
    // Header level - tax locale type, total tax amount, class taxes, error.
    // Item level - line id, product id, net unit price, total line tax amount, total adjustment tax amount,
    //              total tiered adjustment tax amount, tax adjustments, total price tax amount, error, tax info.
    public override commercestoretax.CalculateTaxesResponse processCalculateTaxes(commercestoretax.CalculateTaxesRequest request2) {
        String prefix = 'Customer_';
        commercestoretax.CalculateTaxesRequestItemGroupCollection calculateTaxesRequestItemGroupCollection = request2.getLineItemGroups();
        commercestoretax.CalculateTaxesResponse response = new commercestoretax.CalculateTaxesResponse(commercestoretax.TaxLocaleType.GROSS);

        // Customer can choose to exempt the taxes for some of the products.
        // Exempted products list here are the products the Customer choose to exempt tax calculation.
        List<String> taxExemptedProducts = getTaxExemptedProducts();
        try {
            for (Integer i = 0; i < calculateTaxesRequestItemGroupCollection.size(); i++) {
                commercestoretax.CalculateTaxesRequestItemGroup itemGroup = calculateTaxesRequestItemGroupCollection.get(i);
                List<commercestoretax.CalculateTaxesRequestLineItem> taxableLineItems = new List<commercestoretax.CalculateTaxesRequestLineItem>();
                commercestoretax.Address shippingAddress = itemgroup.getShipToAddress();

                // Customer may be eligible to collect taxes in specific countries and states.
               if (!allowTaxCollection(shippingAddress.getCountry(), shippingAddress.getState())) {
                  // Not eligible to collect taxes for the country and state specified in the request, throw exception
                  throw new InvalidParameterValueException('commercestoretax.CalculateTaxesRequest.CalculateTaxesRequestItemGroup.shippingAddress.Country',
                                                           'Unsupported country and state specified.');
               }

               // Customers may choose to exempt tax for some products. Filter out all taxable products.
               commercestoretax.CalculateTaxesRequestLineItemCollection lineItemCollection = itemGroup.getLineItems();
               for (Integer j=0; j < lineItemCollection.size(); j++) {
                   commercestoretax.CalculateTaxesRequestLineItem lineItem = lineItemCollection.get(j);
                   if (!taxExemptedProducts.contains(lineItem.getProductId())) {
                       // Taxable product
                       taxableLineItems.add(lineItem);
                   } else {
                       // Non-Taxable product, so ignore tax calculation for this.
                       response.addCalculateTaxesResponseLineItem(getLineItemResponseWithEmptyTaxValues(lineItem));
                   }
               }

               // Fetch the Tax Calculation data from external service. Customer can make any external service call to
               // fetch the information. In this example, we use static data.
               Map<String, TaxCalculationDataFromExternalService> dataFromService = null;
               if (useHTTPService) {
                   dataFromService = getTaxCalculationFromExternalService(taxableLineItems, shippingAddress.getCountry(), shippingAddress.getState());
               } else {
                   dataFromService = getTaxCalculationFromStaticResponse(taxableLineItems, shippingAddress.getCountry(), shippingAddress.getState());
               }

               // Populate response from tax calculation data received from external service
               Decimal totalTaxAmount = 0.00;
               for (Integer j=0; j < taxableLineItems.size(); j++) {
                   commercestoretax.CalculateTaxesRequestLineItem requestLineItem = taxableLineItems.get(j);

                   // External service may not return the tax calculation data for some products, set error response for this.
                   if (dataFromService == null || dataFromService.get(requestLineItem.getProductId()) == null) {
                       commercestoretax.CalculateTaxesResponseLineItem lineItemResponse = new commercestoretax.CalculateTaxesResponseLineItem();
                       lineItemResponse.setError('Error in calculating taxes for this product.', 'Erreur dans le calcul des taxes pour ce produit.');
                       response.addCalculateTaxesResponseLineItem(lineItemResponse);
                       continue;
                   }

                   // Populate Line item response from the external tax data.
                   TaxCalculationDataFromExternalService taxCalculationData = dataFromService.get(requestLineItem.getProductId());
                   commercestoretax.CalculateTaxesResponseLineItem lineItemResponse = new commercestoretax.CalculateTaxesResponseLineItem();
                   lineItemResponse.setLineId(requestLineItem.getLineId());
                   lineItemResponse.setProductId(requestLineItem.getProductId());
                   lineItemResponse.setNetUnitPrice(taxCalculationData.getNetUnitPrice());
                   lineItemResponse.setTotalLineTaxAmount(taxCalculationData.getTotalLineTaxAmount());
                   lineItemResponse.setTotalPriceTaxAmount(taxCalculationData.getTotalPriceTaxAmount());
                   totalTaxAmount = totalTaxAmount + lineItemResponse.getTotalPriceTaxAmount();
                   lineItemResponse.setTotalTieredAdjustmentTaxAmount(taxCalculationData.getTotalTieredAdjTaxAmount());
                   lineItemResponse.setTotalAdjustmentTaxAmount(taxCalculationData.getTotalAdjTaxAmount());

                   // In this example, we assume that the product is only configured for country level taxes.
                   // There can be more than one taxInfo when both country and state level taxes are configured for the product.
                   commercestoretax.TaxInfo taxInfo = new commercestoretax.TaxInfo(shippingAddress.getCountry(), shippingAddress.getState(), 1,
                                                                                   taxCalculationData.getTaxRate(),
                                                                                   taxCalculationData.getTaxName(),
                                                                                   taxCalculationData.getTaxTreatmentDesc(),
                                                                                   taxCalculationData.getTotalLineTaxAmount());
                   lineItemResponse.addTaxInfo(taxInfo);

                   // Populate Tax Adjustments
                   Map<String, TaxAdjustmentData> taxCalculationAdjustmentData = taxCalculationData.getTaxAdjustments();
                   if (requestLineItem.getAdjustments() != null) {
                        for (Integer k=0; k > requestLineItem.getAdjustments().size(); k++) {
                            commercestoretax.LineAdjustment requestLineAdjustment = requestLineItem.getAdjustments().get(k);
                            TaxAdjustmentData taxAdjustmentData = taxCalculationAdjustmentData.get(requestLineAdjustment.getId());
                            commercestoretax.TaxAdjustment taxAdjustmentResponse = new commercestoretax.TaxAdjustment(commercestoretax.TaxAdjustmentType.PROMOTIONAL);
                            taxAdjustmentResponse.setId(requestLineAdjustment.getId());
                            taxAdjustmentResponse.setAdjustmentTaxAmount(taxAdjustmentData.getAmount());
                            lineItemResponse.addTaxAdjustment(taxAdjustmentResponse);
                        }
                   }
                   response.addCalculateTaxesResponseLineItem(lineItemResponse);

                   // Customer can choose to modify tax treatment name and description coming from external service.
                   taxInfo.setTaxTreatmentName(appendField(prefix, taxCalculationData.getTaxName()));
                   taxInfo.setTaxTreatmentDescription(appendField(prefix, taxCalculationData.getTaxTreatmentDesc()));
               }
               response.setTotalTaxAmount(totalTaxAmount);
            }
            return response;
        } catch (Exception e) {
            // For testing purposes, this example treats exceptions as user errors, which means they are
            // displayed to the buyer user. In production, you probably want exceptions to be admin-type
            // errors. In that case, throw the exception here and make sure that a notification system is
            // in place to let the admin know that the error occurred.
            throw new CalloutException('There was a problem with the request.');
        }
    }

    // This is similar a call to an external tax service. For testing purpose, this function uses in-place logic
    // to populate the tax data.
    private Map<String, TaxCalculationDataFromExternalService> getTaxCalculationFromStaticResponse(List<commercestoretax.CalculateTaxesRequestLineItem> lineItems,
                                                            String country, String state) {

        Map<String, TaxCalculationDataFromExternalService> taxCalculationData = new Map<String, TaxCalculationDataFromExternalService>();
        for (Integer i=0; i < lineItems.size(); i++) {
            commercestoretax.CalculateTaxesRequestLineItem lineItem = lineItems.get(i);
            Double taxRate = 0.15;
            Decimal amount = lineItem.getTotalPrice() == null ? 0.00 : lineItem.getTotalPrice();
            if (country == 'US') {
                taxRate = 0.08;
                String [] noSalesTaxUSStates = new String [] {'AK', 'DE', 'MT', 'NH', 'OR'};
                if (noSalesTaxUSStates.contains(state)) {
                    taxRate = 0.00;
                }
            }

            Decimal itemizedPromotionTax = 0.00;
            Decimal itemizedTierTax = 0.00;
            Decimal netUnitPrice = 0.00;
            Decimal quantity = lineItem.getQuantity();
            Double multiplier = 0.00;

            if(taxType == 'Gross') {
                multiplier = taxRate / (1 + taxRate);
            } else {
                multiplier = taxRate;
            }

            Decimal lineItemTax = amount * multiplier;

            Map<String, TaxAdjustmentData> adjustmentDataMap = null;
            commercestoretax.LineAdjustmentCollection lineAdjCollection = lineItem.getAdjustments();
            if (lineAdjCollection != null && lineAdjCollection.size() > 0) {
                adjustmentDataMap = new Map<String, TaxAdjustmentData>();
                for (Integer j=0; j < lineAdjCollection.size(); j++) {
                    commercestoretax.LineAdjustment lineAdjustment = lineAdjCollection.get(j);
                    Decimal itemTaxAmount = roundAmount((lineAdjustment.getAmount()!=null ? lineAdjustment.getAmount() : 0.00) * multiplier);
                    TaxAdjustmentData adjData = new TaxAdjustmentData(lineAdjustment.getId(), itemTaxAmount);
                    if (lineAdjustment.getType().equals(commercestoretax.TaxAdjustmentType.PROMOTIONAL.name())) {
                        itemizedPromotionTax = itemizedPromotionTax + itemTaxAmount;
                    } else {
                        itemizedTierTax = itemizedTierTax + itemTaxAmount;
                    }
                    adjustmentDataMap.put(lineAdjustment.getId(), adjData);
                }
            }

            if (taxType == 'Gross') {
                netUnitPrice = (amount - lineItemTax) / quantity;
            } else {
                netUnitPrice = amount / quantity;
            }
            taxCalculationData.put(lineItem.getProductId(), new TaxCalculationDataFromExternalService(taxRate, 'VAT', roundAmount(netUnitPrice),
                                               roundAmount(lineItemTax), roundAmount(itemizedPromotionTax), roundAmount(itemizedTierTax),
                                               roundAmount(lineItemTax + itemizedPromotionTax + itemizedTierTax),
                                               'VAT description', adjustmentDataMap));
        }
        return taxCalculationData;
    }

    // This function makes an external service call to get the response and populate the map.
    // You should replace the httpHost with correct endpoint for this to work.
    private Map<String, TaxCalculationDataFromExternalService> getTaxCalculationFromExternalService(List<commercestoretax.CalculateTaxesRequestLineItem> lineItems,
                                                            String country, String state) {

        // Ensure that your service(httpHost) has this API end point. If not, change it to appropriate API end point on your service.
        String requestURL = httpHost + '/get-tax-rates';

        String requestBody = '{"state":"' + state + '", "country":"' + country + '", "taxType":"' + taxType + '", ' + '"lineItems":' + JSON.serialize(lineItems)+'}';
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(requestURL);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(requestBody);
        HttpResponse response = http.send(request);

        // If the request is successful, parse the JSON response. We assume that external service is returning
        // tax data for all the line items. If not, you can adjust the logic below to handle the corner cases.
        if (response.getStatusCode() == 200) {
            Map<String, Object> resultsFromExternalService = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            Map<String, TaxCalculationDataFromExternalService> taxCalculationData = new Map<String, TaxCalculationDataFromExternalService>();
            for (Integer i=0; i < lineItems.size(); i++){
                commercestoretax.CalculateTaxesRequestLineItem lineItem = lineItems.get(i);
                Map<String, Object> lineItemTaxData = (Map<String, Object>) resultsFromExternalService.get(lineItem.getProductId());
                taxCalculationData.put(lineItem.getProductId(), new TaxCalculationDataFromExternalService((Double) lineItemTaxData.get('taxRate'),
                                                                           (String) lineItemTaxData.get('taxName'),
                                                                           (Decimal) lineItemTaxData.get('netUnitPrice'),
                                                                           (Decimal) lineItemTaxData.get('totalLineTaxAmount'),
                                                                           (Decimal) lineItemTaxData.get('totalAdjTaxAmount'),
                                                                           (Decimal) lineItemTaxData.get('totalTieredAdjTaxAmount'),
                                                                           (Decimal) lineItemTaxData.get('totalPriceTaxAmount'),
                                                                           (String) lineItemTaxData.get('taxTreatmentDesc'),
                                                                           null));
            }
            return taxCalculationData;
        } else if(response.getStatusCode() == 404) {
            throw new CalloutException ('404. You must create a sample application or add your own service which returns a valid response');
        } else {
            throw new CalloutException ('There was a problem with the request. Error: ' + response.getStatusCode());
        }
    }

    private Boolean allowTaxCollection(String country, String state) {
        // Let us assume customer is allowed to collect taxes in Unites States only.
        if (country == 'US') {
            return true;
        }
        return false;
    }

    // Gets list of tax exempted products.
    private List<String> getTaxExemptedProducts() {
        List<String> taxExemptedProducts = new List<String>();
        taxExemptedProducts.add('productId1');
        taxExemptedProducts.add('productId2');
        // Customers can add the other exempted product Ids here.
        return taxExemptedProducts;
    }

    // Appends a String prefix to the field specified.
    private String appendField(String prefix, String field){
        // Customers can easily change the string IDs returned by Salesforce Internal Tax API
        return prefix + field;
    }

    // Gets CalculateTaxesResponseLineItem response object with tax values as zero.
    private commercestoretax.CalculateTaxesResponseLineItem getLineItemResponseWithEmptyTaxValues(commercestoretax.CalculateTaxesRequestLineItem lineItem) {
        commercestoretax.CalculateTaxesResponseLineItem lineItemResponse = new commercestoretax.CalculateTaxesResponseLineItem();
        lineItemResponse.setLineId(lineItem.getLineId());
        lineItemResponse.setProductId(lineItem.getProductId());
        lineItemResponse.setNetUnitPrice(lineItem.getUnitPrice());
        lineItemResponse.setTotalLineTaxAmount(0.00);
        lineItemResponse.setTotalPriceTaxAmount(0.00);
        lineItemResponse.setTotalTieredAdjustmentTaxAmount(0.00);
        lineItemResponse.setTotalAdjustmentTaxAmount(0.00);
        return lineItemResponse;
    }

    // This function uses scale of 2 and rounding mode as System.RoundingMode.HALF_DOWN.
    // This should be overridden by the customer based on their requirements.
    private Decimal roundAmount(Decimal amount) {
        return amount.setScale(2, System.RoundingMode.HALF_DOWN);
    }

    // Structure to store the Tax Calculation data retrieved from external service
    Class TaxCalculationDataFromExternalService {
        private Double taxRate;
        private String taxName;
        private Decimal netUnitPrice;
        private Decimal totalLineTaxAmount;
        private Decimal totalAdjTaxAmount;
        private Decimal totalTieredAdjTaxAmount;
        private Decimal totalPriceTaxAmount;
        private String taxTreatmentDesc;
        private Map<String, TaxAdjustmentData> taxAdjustments;

        public TaxCalculationDataFromExternalService() {
            this.taxRate = 0.0;
            this.taxName = '';
            this.netUnitPrice = 0.0;
            this.totalLineTaxAmount = 0.0;
            this.totalAdjTaxAmount = 0.0;
            this.totalTieredAdjTaxAmount = 0.0;
            this.totalPriceTaxAmount = 0.0;
            this.taxTreatmentDesc = '';
        }

        public TaxCalculationDataFromExternalService(Double taxRate, String taxName, Decimal netUnitPrice, Decimal totalLineTaxAmount,
                                                     Decimal totalAdjTaxAmount, Decimal totalTieredAdjTaxAmount, Decimal totalPriceTaxAmount,
                                                     String taxTreatmentDesc, Map<String, TaxAdjustmentData> taxAdjustments) {
            this.taxRate = taxRate;
            this.taxName = taxName;
            this.netUnitPrice = netUnitPrice;
            this.totalLineTaxAmount = totalLineTaxAmount;
            this.totalAdjTaxAmount = totalAdjTaxAmount;
            this.totalTieredAdjTaxAmount = totalTieredAdjTaxAmount;
            this.totalPriceTaxAmount = totalPriceTaxAmount;
            this.taxTreatmentDesc = taxTreatmentDesc;
            this.taxAdjustments = taxAdjustments;
        }

        public Double getTaxRate() {
            return taxRate;
        }

        public String getTaxName() {
            return taxName;
        }

        public Decimal getNetUnitPrice() {
            return netUnitPrice;
        }

        public Decimal getTotalLineTaxAmount() {
            return totalLineTaxAmount;
        }

        public Decimal getTotalAdjTaxAmount() {
            return totalAdjTaxAmount;
        }

        public Decimal getTotalTieredAdjTaxAmount() {
            return totalTieredAdjTaxAmount;
        }

        public Decimal getTotalPriceTaxAmount() {
            return totalPriceTaxAmount;
        }

        public String getTaxTreatmentDesc() {
            return taxTreatmentDesc;
        }

        public Map<String, TaxAdjustmentData> getTaxAdjustments() {
            return taxAdjustments;
        }
    }

    // Structure to store the Tax Adjustment Calculation data retrieved from external service
    class TaxAdjustmentData {
        private String id;
        private Decimal amount;

        public TaxAdjustmentData() {
            id = '';
            amount = 0.0;
        }

        public TaxAdjustmentData(String idObj, Decimal taxAmountObj) {
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
