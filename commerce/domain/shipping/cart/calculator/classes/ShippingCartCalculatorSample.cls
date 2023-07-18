// This sample is for the situations where Shipping Calculation needs to be extended or overridden
// via the extension point for the Shipping Calculator. The Custom Apex Class must be linked to the
// Shipping Calculator extension point and then the integration must be linked to the webstore via
// appropriate Setup

// This class must extend the CartExtension.ShippingCartCalculator class to be processed.
public class ShippingCartCalculatorSample extends CartExtension.ShippingCartCalculator {
  public virtual override void calculate(CartExtension.CartCalculateCalculatorRequest request) {
    CartExtension.Cart cart = request.getCart();
    // Clean up CVO based on Shipping
    CartExtension.CartValidationOutputList cartValidationOutputList = cart.getCartValidationOutputs();

    for (Integer i = (cartValidationOutputList.size() - 1); i >= 0; i--) {
      CartExtension.CartValidationOutput cvo = cartValidationOutputList.get(i);
      if (cvo.getType() == CartExtension.CartValidationOutputTypeEnum.SHIPPING) {
        cartValidationOutputList.remove(cvo);
      }
    }

    // To create the Cart delivery group methods, we need to get the ID of the cart delivery group.
    CartExtension.CartDeliveryGroupList cartDeliveryGroups = cart.getCartDeliveryGroups();
    if (cartDeliveryGroups.size() == 0) {
      CartExtension.CartValidationOutput cvo = new CartExtension.CartValidationOutput(
        CartExtension.CartValidationOutputTypeEnum.SHIPPING,
        CartExtension.CartValidationOutputLevelEnum.ERROR
      );
      cvo.setMessage('No Cart Delivery Groups have been defined');
      cartValidationOutputList.add(cvo);
    } else {
      CartExtension.CartItemList cartItems = cart.getCartItems();
      Integer numberOfUniqueItems = cartItems.size();
      CartExtension.CartDeliveryGroup cartDeliveryGroup = cartDeliveryGroups.get(0);
      CartExtension.CartDeliveryGroupMethodList cartDeliveryGroupMethods = cartDeliveryGroup.getCartDeliveryGroupMethods();

      // Clean up the CartDeliveryGroupMethods
      for (Integer i = (cartDeliveryGroupMethods.size() - 1); i >= 0; i--) {
        CartExtension.CartDeliveryGroupMethod method = cartDeliveryGroupMethods.get(i);
        cartDeliveryGroupMethods.remove(method);
      }
      // To clear selected Cart Delivery Group Method
      cartDeliveryGroup.setSelectedCartDeliveryGroupMethod(null);

      // Get the Shipping Product
      List<Product2> shippingProducts = [SELECT Id FROM Product2 LIMIT 1];

      if(shippingProducts.size() == 0) {
        CartExtension.CartValidationOutput cvo = new CartExtension.CartValidationOutput(CartExtension.CartValidationOutputTypeEnum.SHIPPING,
                CartExtension.CartValidationOutputLevelEnum.ERROR );
        cvo.setMessage('No Shipping Products have been defined');
        cartValidationOutputList.add(cvo);
      } else {
          String shippingProduct = Id.valueOf(shippingProducts[0].Id);
          // Create a CartDeliveryGroupMethod record for every shipping option returned from the external service
          CartExtension.CartDeliveryGroupMethod cartDeliveryGroupMethod01 = new CartExtension.CartDeliveryGroupMethod('Ground Shipping', 10.99, shippingProduct);
          cartDeliveryGroupMethod01.setCarrier('USPS');
          cartDeliveryGroupMethod01.setClassOfService('Ground Shipping');
          CartExtension.CartDeliveryGroupMethod cartDeliveryGroupMethod02 = new CartExtension.CartDeliveryGroupMethod('Next Day Air', 15.99, shippingProduct);
          cartDeliveryGroupMethod02.setCarrier('UPS');
          cartDeliveryGroupMethod02.setClassOfService('Next Day Air');
          cartDeliveryGroupMethods.add(cartDeliveryGroupMethod01);
          cartDeliveryGroupMethods.add(cartDeliveryGroupMethod02);
      }
    }
  }
}
