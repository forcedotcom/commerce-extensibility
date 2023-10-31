/*
 * Class that strips out all of the non-digit characters and throws an exception if the
 * resulting value is not a 5 or 9 digit zip.
 */
public class UsZipCleansingSample {

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

    // Strips non-digit values and throws exception if not a valid zip.
    private static String cleanseZip(String zipIn) {
        String cleansedZip = zipIn.replaceAll('\\D','');
        if (isValidZip(cleansedZip)) {
            return cleansedZip ;
        } else {
            // If this exception is not handled, it will result in an HTTP status code of 400 being returned to the client with the message supplied to the exception.
            throw new InvalidAddressSampleException(cleansedZip + ' is not a valid US postal code');
        }
    }

    private static Boolean isValidZip(String zip) {
        return validZipPattern.matcher(zip).matches();
    }    

}