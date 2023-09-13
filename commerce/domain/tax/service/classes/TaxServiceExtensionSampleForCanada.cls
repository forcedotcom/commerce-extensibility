// This is a sample placeholder for taxation Extension Provider for en_CA locale
// Please refer the TaxServiceExtensionSample sample class for a detailed custom implementation of an Extension Provider.
public class TaxServiceExtensionSampleForCanada extends commercestoretax.TaxService {
    public override commercestoretax.GetStoreTaxesInfoResponse processGetStoreTaxesInfo(commercestoretax.GetStoreTaxesInfoRequest request) {
        commercestoretax.GetStoreTaxesInfoResponse response = super.processGetStoreTaxesInfo(request);
        response.getTaxesInfo().values().get(0).getStoreTaxesInfoList().get(0).setTaxRatePercentage(double.valueOf('15.0'));
        return response;
    }
    public override commercestoretax.CalculateTaxesResponse processCalculateTaxes(commercestoretax.CalculateTaxesRequest request) {
        commercestoretax.CalculateTaxesResponse response = super.processCalculateTaxes(request);
        return response;
    }
}
