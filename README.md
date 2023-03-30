# Commerce Extensibility

This repository contains a reference implementation of the Commerce Extensibility Framework. It includes sample code for extending the Calculator Service, including:

- Apex classes
- Tests
- Resource files

**Warning**: Sample code is provided "as is" for demonstration purposes only and must not be used unmodified in a production system.

## Shipping Calculator

The sample code for Shipping Calculator includes an Apex class (in `ShippingCalculatorSample.apxc`) that calls an external service to retrieve shipping rates and then save that rate as an additional charge in the `CartItems`.

**Warning**: This sample code uses a live Heroku service to showcase how to use a third-party integration to retrieve shipping options. The function `getShippingOptionsAndRatesFromExternalService` responds with hardcoded shipping options. If you need to bypass the live call, use `getShippingOptionsAndRatesFromMockedService` instead.

A test class is also included for reference.

## Error Handling

There are two types of errors that can surface from the reference implementations: user errors (which the shopper can see and correct) and admin errors (which the shopper can’t fix).

To propagate an error to the user, add a `CartValidationOutput` record. All reference implementations include examples of how to propagate an error to the user.

To propagate an error to the admin, throw the exception from the reference implementation. The user is presented with a generic error message telling them to contact their admin. At the same time, a Platform Status Alert Event platform event is published. A notification is created for the admin to see the error message.

To learn how to create a Platform Status Alert Event trigger for the notification, see `PlatformStatusAlertEvent` and Create a Custom Notification Flow.

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
