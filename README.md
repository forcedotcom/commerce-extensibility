# Commerce Extensibility

This repository contains a reference implementation of the Commerce Extensibility Framework. It includes sample code for extending the following services:

- [Domain Extensions for Cart Calculate API](#domain-extensions-for-cart-calculate-api):
	- Pricing
    - Promotion
	- Shipping Calculator
	- Tax Calculator
	- Tax Service
- [Domain Extensions for Checkout](#domain-extensions-for-checkout)
	- CreateOrder Service
	- SplitShipment Service
- [Domain Extensions for Buyer Group](#domain-extensions-for-buyer-group)
	- Buyer Group Extensibility Service

Each set of sample code includes: an Apex class, a test class, and any necessary resource files.

Live Heroku services are used to simulate a connection to a third-party system. You can bypass the Heroku service and use mocked data instead.

**Warning**: The sample code and Heroku services are provided "as is" for demonstration purposes only. Do not use the source code in a production system without modifying and testing it first. And do not use the Heroku services in a production system under any circumstances.

## Domain Extensions for Cart Calculate API

### Pricing Service

The sample code for Pricing Service includes an Apex class (in `PricingServiceSample.apxc`) that calls an external service to retrieve product prices and then saves that price in the `PricingResponseItems` list.

### Pricing Calculator

The sample code for Pricing Calculator includes an Apex class (in `PricingCalculatorSample.apxc`) that calls an external service to retrieve pricing information and then save those taxes in `CartItem`.

### Promotion Calculator

The sample code for Promotion Calculator includes an Apex class (in `PromotionCalculatorSample.apxc`) that updates price adjustments for each `CartItem` based on promotion applied.

### Shipping Calculator

The sample code for Shipping Calculator includes an Apex class (in `ShippingCalculatorSample.apxc`) that calls an external service to retrieve shipping rates and then save that rate as an additional charge in the `CartItems` list.

### Tax Calculator

The sample code for Tax Calculator includes an Apex class (in `TaxCalculatorSample.apxc`) that calls an external service to retrieve tax information and then save those taxes in `CartTaxes` in `CartItems`.

### Tax Service

The sample code for Tax Service includes the following Apex classes :
- an Apex class (in `TaxServiceSample.apxc`) that calls an external service to retrieve tax calculation data and then saves that in the `CalculateTaxesResponseLineItem` list.
- an Apex class (in `TaxServiceExtensionResolverSample.apxc`) which selects different resolution states (EXECUTE_DEFAULT, EXECUTE_REGISTERED and OFF) for different locales to execute respective implementations (Extension Providers or the Default Salesforce Internal Tax Api).

### Error Handling

In order to propagate an error message to the shopper use [CartValidationOutput](https://developer.salesforce.com/docs/commerce/salesforce-commerce/guide/CartValidationOutput.html).
Throwing an Exception from any Orchestrator or Calculator would result into CartValidationOutput created on the Cart with generic error message based on Calculator type.
Special case [CartCalculateRuntimeException](https://developer.salesforce.com/docs/commerce/salesforce-commerce/guide/CartCalculateRuntimeException.html) can be used to rollback all calculation applied to the Cart withing given request processing boundaries.
All error cases are propagated to the admin as CommerceDiagnosticEvents (see [CommerceDiagnosticEvent](https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/sforce_api_objects_commercediagnosticevent.htm))

All reference implementations include examples of how to propagate an error to the user.

## Domain Extensions for Checkout

### CreateOrder Service

The sample code for the [CreateOrder Service](https://developer.salesforce.com/docs/commerce/salesforce-commerce/references/comm-apex-reference/CheckoutCreateOrder.html) extension point includes an Apex class (see [CreateOrderSample.cls](commerce/domain/checkout/order/createOrder/classes/CreateOrderSample.cls)) that provides an example of how to work with the [OrderGraph](https://developer.salesforce.com/docs/commerce/salesforce-commerce/guide/OrderGraph.html).

A unit test (see [CreateOrderSampleUnitTest.cls](commerce/domain/checkout/order/createOrder/classes/CreateOrderSampleUnitTest.cls)) that follows this approach for [Mocking the Base Apex Class in Tests](https://developer.salesforce.com/docs/commerce/salesforce-commerce/guide/mock-the-base-apex-class.html).

Also, there is an "integration" test (see [CreateOrderSampleIntegrationTest.cls](commerce/domain/checkout/order/createOrder/classes/CreateOrderSampleIntegrationTest.cls)) that verifies implementation of the CreateOrder extension that calls real default extension point behavior. This testing approach can be used in addition to unit test, it has wider test coverage, but it is less isolated than unit test presented in the example below.

### SplitShipment Service

The sample code for the [SplitShipment Service](https://developer.salesforce.com/docs/commerce/salesforce-commerce/references/comm-apex-reference/SplitShipmentService.html) extension point includes an Apex class (see [SplitShipmentSample.cls](commerce/domain/shipping/splitshipment/SplitShipmentSample.cls)) that creates cart delivery groups by conveyable and non-conveyable products. 

Another example (see [SplitShipmentCallsSuper.cls](commerce/domain/shipping/splitshipment/SplitShipmentCallsSuper.cls)) calls the default implementation.

Also, there is a unit test (see [SplitShipmentUnitTest.cls](commerce/domain/shipping/splitshipment/SplitShipmentUnitTest.cls)) that follows this approach for [Mocking the Base Apex Class in Tests](https://developer.salesforce.com/docs/commerce/salesforce-commerce/guide/mock-the-base-apex-class.html).

## Domain Extensions for Buyer Group

### Buyer Group Extensibility Service

The sample code for Buyer Group Extensibility Service includes the following :
- An Apex class (in `BuyerGroupEvaluationServiceSample.apxc`) that uses active postal codes to retrieve buyer groups for logged in and guest users.
- An Org Platform Cache (in `BuyerGroup.cachePartition`) to support low latency in buyer group retrieval.
- Supported Custom objects for storing and associating buyer groups to users via postal codes.(in `PostalCode__c`, `Active_PostalCode__c` and `Postal_Code_Buyer_Group__c`)

## Deployment

To deploy this reference implementation, use Workbench:

1. Clone this repository.
2. From this folder, create a .zip file:
   ```bash
   zip -r -X <your-zip-file>.zip *
   ```
3. Open Workbench and go to **Migration** > **Deploy**.
4. Select the file you created (`<your-zip-file>.zip`).
5. Check the **Single Package** checkbox.
6. Click **Next**.
7. Click **Deploy**.

## Contributions

We are not currently accepting external contributions to this repository.

## Issues

We are not currently tracking issues through GitHub. If you’re experiencing an issue with the sample code, reach out to your Salesforce representative.

## Code of Conduct

We expect all users of this repository to follow the [Salesforce Open Source Community Code of Conduct](CODE_OF_CONDUCT.md).

## Security

Please report any security issue to security@salesforce.com as soon as it is discovered.

## License

The sample code is licensed under a BSD 3-Clause license. See the [license](LICENSE.txt) for details.

## Forward-Looking Statements

This repository may contain forward-looking statements that involve risks, uncertainties, and assumptions. For more information, see [STATEMENTS](STATEMENTS.md).
