// If your tax calculation needs to deal with cart's custom fields or any other complex logic that requires direct access to cart, please extend
// the CartExtension.TaxCartCalculator instead.

// If you plan to support tax calculations for subscription products, you must implement the commercestoretax.TaxService.

// Your custom apex class must be linked to the tax extension point and then the integration must be linked to the web store via appropriate setup.
// For more information related to that, please see the corresponding documentation.

// Disclaimer: the code listed here is a sample that hasn't been tested for production use. Always test your code before releasing to production.
public class TaxServiceExtensionSample extends commercestoretax.TaxService {
    
    Map<String, Double> taxCodeToRate = new Map<String, Double>{'Beverages' => 0.25, 'Shipping' => 0.1};

    // The method is used for displaying tax-related information on PDP
    // If you are using an external Tax Service, you most likely don't need to override the method
    // Disclaimer: the code listed here is a sample that hasn't been tested for production use. Always test your code before releasing to production.
    public override commercestoretax.GetStoreTaxesInfoResponse processGetStoreTaxesInfo(commercestoretax.GetStoreTaxesInfoRequest request) {
        try {
            // Call the default internal tax implementation with either original request or modified request.
            commercestoretax.GetStoreTaxesInfoResponse response = super.processGetStoreTaxesInfo(request);

            // Override tax rate percentage by increasing them by a fixed amount. Also, let us override treatment name and
            // description by appending a prefix to them in case customers use a different naming convention.
            Double fixedAmountIncrease = 2;
            commercestoretax.ProductIdCollection productIds = request.getProductIds();
            Map<String, commercestoretax.StoreTaxesInfoContainer> storeTaxesInfoContainerMap = response.getTaxesInfo();
            for(Integer i = 0; i < productIds.size(); i++){
                String productId = productIds.get(i);
                commercestoretax.StoreTaxesInfoContainer storeTaxesInfoContainer = storeTaxesInfoContainerMap.get(productId);
                commercestoretax.StoreTaxesInfoCollection storeTaxesInfoCollection = storeTaxesInfoContainer.getStoreTaxesInfoList();
                for (Integer j = 0; j < storeTaxesInfoCollection.size(); j++) {
                    commercestoretax.StoreTaxesInfo storeTaxesInfo = storeTaxesInfoCollection.get(j);
                    storeTaxesInfo.setTaxRatePercentage(storeTaxesInfo.getTaxRatePercentage() + fixedAmountIncrease);
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

    // This is the method that performs tax calculations.
    //
    // You should avoid making any calls for cart/cart item retrival from here since at this stage the cart isn't committed.
    //
    // Disclaimer: the code listed here is a sample that hasn't been tested for production use. Always test your code before releasing to production.
    public override commercestoretax.CalculateTaxesResponse processCalculateTaxes(commercestoretax.CalculateTaxesRequest request2) {
        commercestoretax.CalculateTaxesRequestItemGroupCollection calculateTaxesRequestItemGroupCollection = request2.getLineItemGroups();
        commercestoretax.CalculateTaxesResponse response = new commercestoretax.CalculateTaxesResponse(commercestoretax.TaxLocaleType.Net);

        try {
            // the request might have multiple delivery groups (for example, in case of split shipments)
            for (Integer i = 0; i < calculateTaxesRequestItemGroupCollection.size(); i++) {
                commercestoretax.CalculateTaxesRequestItemGroup itemGroup = calculateTaxesRequestItemGroupCollection.get(i);
                commercestoretax.Address shippingAddress = itemgroup.getShipToAddress();

                // You might want to do address validation here

               // Customers may choose to exempt tax for some products. Filter out all taxable products.
               commercestoretax.CalculateTaxesRequestLineItemCollection lineItemCollection = itemGroup.getLineItems();
               
               List<commercestoretax.CalculateTaxesRequestLineItem> taxableItems = new List<commercestoretax.CalculateTaxesRequestLineItem>();
               for (Integer j=0; j < lineItemCollection.size(); j++) {
                   taxableItems.add(lineItemCollection.get(j));
               }
               // shipping charge comes from a separate field and is not a part of LineItems.
               if (itemGroup.getShippingLineItem() != null) {
                   commercestoretax.CalculateTaxesRequestLineItem shippingLine = itemGroup.getShippingLineItem();
                   
                   // Tax Code value on shipping charge isn't passed to the APEX code in the latest implementation. 
                   shippingLine.setTaxCode('Shipping');
                   taxableItems.add(shippingLine);
               }

               // Fetch the Tax Calculation data from external service. Customer can make any external service call to
               // fetch the information. In this example, we use static data.
               Map<String, TaxCalculationDataFromExternalService> dataFromService = getTaxCalculationFromStaticResponse(taxableItems, shippingAddress.getCountry(), shippingAddress.getState());

               // Populate response from tax calculation data received from external service
               Decimal totalTaxAmount = 0.00;
               for (Integer j=0; j < taxableItems.size(); j++) {
                   commercestoretax.CalculateTaxesRequestLineItem requestLineItem = taxableItems.get(j);

                   // Populate Line item response from the external tax data.
                   TaxCalculationDataFromExternalService taxCalculationData = dataFromService.get(requestLineItem.getLineId());
                   commercestoretax.CalculateTaxesResponseLineItem lineItemResponse = getLineItemResponseRepresentation(requestLineItem, taxCalculationData, shippingAddress);
                   
                   response.addCalculateTaxesResponseLineItem(lineItemResponse);
                   totalTaxAmount = totalTaxAmount + lineItemResponse.getTotalPriceTaxAmount();
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
    
    private commercestoretax.CalculateTaxesResponseLineItem getLineItemResponseRepresentation(commercestoretax.CalculateTaxesRequestLineItem requestLineItem, TaxCalculationDataFromExternalService taxCalculationData, commercestoretax.Address shippingAddress) {
        commercestoretax.CalculateTaxesResponseLineItem lineItemResponse = new commercestoretax.CalculateTaxesResponseLineItem();
       lineItemResponse.setLineId(requestLineItem.getLineId());
       lineItemResponse.setProductId(requestLineItem.getProductId());
       lineItemResponse.setNetUnitPrice(taxCalculationData.getNetUnitPrice());
       lineItemResponse.setTotalLineTaxAmount(taxCalculationData.getTotalLineTaxAmount());
       lineItemResponse.setTotalPriceTaxAmount(taxCalculationData.getTotalPriceTaxAmount());
       
       // In this example, we assume that the product is only configured for country level taxes.
       // There can be more than one taxInfo when both country and state level taxes are configured for the product.
       commercestoretax.TaxInfo taxInfo = new commercestoretax.TaxInfo(shippingAddress.getCountry(), shippingAddress.getState(), 1,
                                                                       taxCalculationData.getTaxRate(),
                                                                       taxCalculationData.getTaxName(),
                                                                       taxCalculationData.getTaxTreatmentDesc(),
                                                                       taxCalculationData.getTotalLineTaxAmount());
      lineItemResponse.addTaxInfo(taxInfo);
       
       return lineItemResponse;
    }

    // This is similar a call to an external tax service. For testing purpose, this function uses in-place logic
    // to populate the tax data.
    private Map<String, TaxCalculationDataFromExternalService> getTaxCalculationFromStaticResponse(List<commercestoretax.CalculateTaxesRequestLineItem> lineItems,
                                                            String country, String state) {
          
        // this ideally should be coming from the request, but it doesn't at this stage                                                  
        String taxType = 'Net';

        Map<String, TaxCalculationDataFromExternalService> taxCalculationData = new Map<String, TaxCalculationDataFromExternalService>();
        for (Integer i=0; i < lineItems.size(); i++) {
            commercestoretax.CalculateTaxesRequestLineItem lineItem = lineItems.get(i);

            Decimal totalPrice = lineItem.getTotalPrice();
            Decimal netUnitPrice = 0.00;
            Decimal quantity = lineItem.getQuantity();
            Double multiplier = 0.00;

            String lineTaxCode = lineItem.getTaxCode();
            Double taxRate = taxCodeToRate.get(lineTaxCode);
            if(taxType == 'Gross') {
                multiplier = taxRate / (1 + taxRate);
            } else {
                multiplier = taxRate;
            }

            Decimal lineItemTax = totalPrice * multiplier;

            
            if (taxType == 'Gross') {
                netUnitPrice = (totalPrice - lineItemTax) / quantity;
            } else {
                netUnitPrice = totalPrice / quantity;
            }
            taxCalculationData.put(lineItem.getLineId(), new TaxCalculationDataFromExternalService(taxRate, 'VAT', roundAmount(netUnitPrice),
                                               roundAmount(lineItemTax), roundAmount(lineItemTax)));
        }
        return taxCalculationData;
    }

    // Appends a String prefix to the field specified.
    private String appendField(String prefix, String field){
        // Customers can easily change the string IDs returned by Salesforce Internal Tax API
        return prefix + field;
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
        private Decimal totalPriceTaxAmount;
        private String taxTreatmentDesc;

        public TaxCalculationDataFromExternalService() {
            this.taxRate = 0.0;
            this.taxName = '';
            this.netUnitPrice = 0.0;
            this.totalLineTaxAmount = 0.0;
            this.totalPriceTaxAmount = 0.0;
            this.taxTreatmentDesc = '';
        }

        public TaxCalculationDataFromExternalService(Double taxRate, String taxName, Decimal netUnitPrice, Decimal totalLineTaxAmount,
                                                     Decimal totalPriceTaxAmount) {
            this.taxRate = taxRate;
            this.taxName = taxName;
            this.netUnitPrice = netUnitPrice;
            this.totalLineTaxAmount = totalLineTaxAmount;
            this.totalPriceTaxAmount = totalPriceTaxAmount;
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

        public Decimal getTotalPriceTaxAmount() {
            return totalPriceTaxAmount;
        }

        public String getTaxTreatmentDesc() {
            return taxTreatmentDesc;
        }
    }
}