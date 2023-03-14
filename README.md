# commerce-extensibility
Reference Implementations
Reference Implementation samples for the Calculators. Include Apex classes, tests and resource files for all Calculators.

Use Metadata API to deploy this using Workbench:
From this folder as your current location, create a .zip file: zip -r -X <your-zip-file>.zip *
Open Workbench and go to migration -> deploy.
Select the file you created ( <your-zip-file>.zip ).
Check the "Single Package" checkbox on that page.
Click "Next".
Click "Deploy".
This repository includes examples for:
WARNING!! These classes are only provided as samples and MUST NOT be used "as they are" in production systems.

1. Shipping Calculator
The example for Shipping Calculator includes an Apex class (CustomerShippingCalculator.apxc) that makes a call to an external service to retrieve shipping rates and then saves that rate as an additional charge in the CartItems.

WARNING!! This example uses live (sample) heroku service to showcase how to use a 3rd party integration to retrieve Shipping Options. The function getShippingOptionsAndRatesFromExternalService responds with sample hardcoded shipping options. If you need to bypass the live call, use getShippingOptionsAndRatesFromMockedService instead.

These implementations are just a sample with hardcoded Shipping Options and MUST NOT be used in production systems.

A test class is also included for reference. (To Be done once we are unblocked)


Error Handling
There are two types of errors that surface from the reference implementations: user errors (which the buyer user sees and can correct) and admin errors (which the buyer user can’t fix).

To propagate an error to the user, add a new CartValidationOutput record. All reference implementations include examples of how to do this.

To propagate the error to the admin, throw the exception from the reference implementation. The user is presented with a generic error message telling them to contact their admin. At the same time, a Platform Status Alert Event platform event is published. In order for the admin to see the error message, a notification is created.

To learn how to create Platform Status Alert Event trigger for the notification, see PlatformStatusAlertEvent and Create a Custom Notification Flow.
