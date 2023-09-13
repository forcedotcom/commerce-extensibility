// This sample is for the situation when different tax behaviors need to be implemented for different locales.
// These tax behaviors can be -
// 1. ResolutionState - EXECUTE_DEFAULT (the default Salesforce Internal Tax Api),
// 2. ResolutionState - EXECUTE_REGISTERED (extended or overridden apis via the extension point from the default Salesforce Internal Tax Api)
// 3. ResolutionState - OFF (In this case, the default Salesforce Internal Tax Api will return an empty response).
// For Salesforce Internal Tax calculation, please see the corresponding documentation.

// Your custom apex extension providers and the resolver must be linked to the tax extension point and then the resolver must be linked to the web store via appropriate setup.
// You can have as many Extension Providers registered as per your use case and use them in your resolver for different locales.
// Please follow the corresponding salesforce documentation on how to use locales.
// For more information related to that, please see the corresponding documentation.

// This must implement the commercestoretax.TaxService class in order to be processed by the tax service flow.
// and it must implement the CommerceExtension.ResolutionStrategy in order to get the different locales and resolutions.
public class TaxServiceExtensionResolverSample extends commercestoretax.TaxService implements CommerceExtension.ResolutionStrategy {
    public CommerceExtension.Resolution resolve() {
        // Executing the Sample Extension Provider registered as 'tax_extension_provider_for_us' for en_US locale
        if(CommerceExtension.ExtensionInfo.getLocaleString() == 'en_US') {
            return new CommerceExtension.Resolution('tax_extension_provider_for_us');
        }
        // Executing the Sample Extension Provider registered as 'tax_extension_provider_for_canada' for en_CA locale
        if(CommerceExtension.ExtensionInfo.getLocaleString() == 'en_CA') {
            return new CommerceExtension.Resolution('tax_extension_provider_for_canada');
        }
        // Executing the OFF case for German locale (i.e. No taxation)
        if(CommerceExtension.ExtensionInfo.getLocaleString() == 'de') {
            return new CommerceExtension.Resolution(CommerceExtension.ResolutionStates.OFF);
        }
        // Executing the default Salesforce Internal Tax Api for other locales than US, Canada and Germany
        return new CommerceExtension.Resolution();
    }
}