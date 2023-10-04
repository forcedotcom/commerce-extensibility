public with sharing class UsZipCleansingSample {

    private static Pattern validZipPattern = Pattern.compile('(^\\d{5}$)|(^\\d{9}$)|(^\\d{5}-\\d{4}$)');

    // Returns whether it needed to be cleansed or not
    public static boolean cleanseUsZip(ConnectApi.CommerceAddressInput address) {

        if (address.getCountry().equals('US')) {
            String zipIn = address.getPostalCode() ;
            if (! isValidZip(zipIn)) {
                // Try to cleanse if it is not valid
                address.setPostalCode(cleanseZip(zipIn));
                return true;
            }
        }
        return false;
    }

    private static String cleanseZip(String zipIn) {
        String cleansedZip = zipIn.replaceAll('\\D','');
        if (isValidZip(cleansedZip)) {
            return cleansedZip ;
        } else {
            throw new CustomEndpointExtensionException(cleansedZip + ' is not a valid US postal code');
        }
    }

    private static Boolean isValidZip(String zip) {
        return validZipPattern.matcher(zip).matches();
    }    

}