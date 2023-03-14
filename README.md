# Commerce Extensibility

This repository contains a reference implementation of the Commerce Extensibility Framework. It includes sample code for extending the Shipping Calculator Service and the Pricing Service. Each set of sample code includes:

- Apex classes
- Tests
- Resource files

**Warning**: Sample code is provided "as is" for demonstration purposes only and must not be used unmodified in a production system.

## Shipping Calculator

The sample code for Shipping Calculator includes an Apex class (in `ShippingCalculatorSample.apxc`) that calls an external service to retrieve shipping rates and then save that rate as an additional charge in the `CartItems` list.

**Warning**: This sample code uses a live Heroku service to showcase how to use a third-party integration to retrieve shipping options. The function `getShippingOptionsAndRatesFromExternalService` responds with hardcoded shipping options. If you need to bypass the live call, use `getShippingOptionsAndRatesFromMockedService` instead.

A test class is also included for reference.

## Pricing Service

The sample code for Pricing Service includes an Apex class (in `PricingServiceSample.apxc`) that calls an external service to retrieve product prices and then saves that price in the `PricingResponseItems` list.

**Warning**: This sample code uses a live Heroku service to showcase how to use a third-party integration to retrieve product prices in the function `getPricesFromExternalService`. If you need to bypass the live call, please use mocked data instead.

A test class is also included for reference.

## Error Handling

There are two types of errors that can surface from the reference implementations: user errors (which the shopper can see and correct) and admin errors (which the shopper can’t fix).

All reference implementations include examples of how to propagate an error to the user.

To propagate an error to the admin, throw an exception from the reference implementation. The user is presented with a generic error message telling them to contact their admin. At the same time, a Platform Status Alert Event platform event is published. A notification is created for the admin to see the error message.

To learn how to create a Platform Status Alert Event trigger for the notification, see [PlatformStatusAlertEvent](https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/sforce_api_objects_platformstatusalertevent.htm) and [Flow Core Action: Send Custom Notification](https://help.salesforce.com/s/articleView?id=sf.flow_ref_elements_actions_sendcustomnotification.htm&type=5).

## Pricing Service

The sample code for Pricing Service includes an Apex class (in `PricingServiceSample.apxc`) that calls an external service to retrieve product prices and then saves that price in the `PricingResponseItems`.

**Warning**: This sample code uses a live Heroku service to showcase how to use a third-party integration to retrieve product prices in the function `getPricesFromExternalService`. If you need to bypass the live call, please use mocked data instead.

A test class is also included for reference.

## Pricing Service

The sample code for Pricing Service includes an Apex class (in `PricingServiceSample.apxc`) that calls an external service to retrieve product prices and then saves that price in the `PricingResponseItems`.

**Warning**: This sample code uses a live Heroku service to showcase how to use a third-party integration to retrieve product prices in the function `getPricesFromExternalService`. If you need to bypass the live call, please use mocked data instead.

A test class is also included for reference.

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
