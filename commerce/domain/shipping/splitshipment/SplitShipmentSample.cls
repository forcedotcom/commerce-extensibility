/**
 * @description Custom Split Shipment Service sample.
 */
global class SplitShipmentSample extends CartExtension.SplitShipmentService {

    /**
     * @description All classes extending CartExtension.SplitShipmentService must have a default constructor defined.
     */
    global SplitShipmentSample() {}

    public virtual override void arrangeItems(CartExtension.ItemArrangementRequest request) {
        CartExtension.Cart cart = request.getCart();

        Iterator<CartExtension.ItemArrange> itemArrangeIterator = request.getItemArrangeList().iterator();
        while (itemArrangeIterator.hasNext()) {
            arrangeItemsByCartItemQuantity(cart, itemArrangeIterator.next());
        }
    }

    /**
     * @description Item arrangement algorithm based on a maximum CartItem quantity per CartDeliveryGroup.
     * @param cart Holds details about a Cart
     * @param itemArrange Holds details of how to arrange an item between CartDeliveryGroups
     */
    private void arrangeItemsByCartItemQuantity(CartExtension.Cart cart, CartExtension.ItemArrange itemArrange) {
        // Find the CartItem using the cartItemId provided by the ItemArrange object
        Iterator<CartExtension.CartItem> cartItemsIterator = cart.getCartItems().iterator();
        while (cartItemsIterator.hasNext()) {
            CartExtension.CartItem cartItem = cartItemsIterator.next();
            if (cartItem.getId() == itemArrange.getCartItemId()) {
                // Check to see if we need to create more CartDeliveryGroups based on quantity
                if (shouldSplitShipmentByQuantity(cartItem.getQuantity(), itemArrange.getQuantity())) {
                    splitShipmentByQuantity(cart, cartItem, itemArrange);
                }
            }
        }
    }

    /**
     * @description Determines whether or not the shipment should be split into multiple shipments, based on quantity.
     * @param cartItemQuantity Quantity associated to a CartItem
     * @param maxCartItemQuantityPerDeliveryGroup Maximum CartItem quantity per CartDeliveryGroup (provided by ItemArrange)
     *
     * @return Boolean True if the quantity associated to the CartItem exceeds the quantity associated to ItemArrange
     */
    private Boolean shouldSplitShipmentByQuantity(Decimal cartItemQuantity, Decimal maxCartItemQuantityPerDeliveryGroup) {
        return cartItemQuantity > maxCartItemQuantityPerDeliveryGroup;
    }

    /**
     * @description Splits the shipment into N CartItems and N CartDeliveryGroups, based on quantity.
     * @param cart Holds details about a Cart
     * @param cartItem Holds details about a CartItem
     * @param itemArrange Holds details of how to arrange an item between CartDeliveryGroups
     */
    private void splitShipmentByQuantity(CartExtension.Cart cart, CartExtension.CartItem cartItem, CartExtension.ItemArrange itemArrange) {
        // Adjust the original CartItem's quantity to maxCartItemQuantityPerDeliveryGroup and create N number of
        // CartItems and CartDeliveryGroups until we've accounted for the entire quantity
        Decimal maxCartItemQuantityPerDeliveryGroup = itemArrange.getQuantity();
        Decimal remainingQuantity = cartItem.getQuantity() - maxCartItemQuantityPerDeliveryGroup;
        cartItem.setQuantity(maxCartItemQuantityPerDeliveryGroup);

        Address deliveryAddress = itemArrange.getDeliveryAddress();
        Integer numCartItems = cart.getCartItems().size();
        Integer cartItemNumber = numCartItems + 1;
        while (remainingQuantity > 0) {
            // Create a new CartDeliveryGroup
            CartExtension.CartDeliveryGroup cartDeliveryGroup = createCartDeliveryGroup(cart, itemArrange, deliveryAddress);

            // Create a new CartItem and associate it to the newly created CartDeliveryGroup
            CartExtension.CartItem newCartItem = new CartExtension.CartItem(CartExtension.SalesItemTypeEnum.PRODUCT, cartDeliveryGroup, 'My Cart Item ' + cartItemNumber++);
            newCartItem.setProduct2Id(itemArrange.getProductId());
            // Update the new CartItem quantity to whichever is smaller, either the remainingQuantity or
            // maxCartItemQuantityPerDeliveryGroup, so that we don't include more quantity of the CartItem than required
            newCartItem.setQuantity(Math.min(remainingQuantity, maxCartItemQuantityPerDeliveryGroup));

            // Associate the new CartItem to the Cart
            cart.getCartItems().add(newCartItem);

            // Adjust the remaining quantity that still needs to be accounted
            remainingQuantity -= maxCartItemQuantityPerDeliveryGroup;
        }
    }

    /**
     * @description Creates a Cart Delivery Group.
     * @param cart Holds details about a Cart
     * @param itemArrange Holds details of how to arrange an item between CartDeliveryGroups
     * @param deliveryAddress Address information for where the item is being delivered
     */
    private CartExtension.CartDeliveryGroup createCartDeliveryGroup(CartExtension.Cart cart, CartExtension.ItemArrange itemArrange, Address deliveryAddress) {
        CartExtension.CartDeliveryGroup cartDeliveryGroup = new CartExtension.CartDeliveryGroup();

        if (deliveryAddress != null) {
            if (deliveryAddress.getStreet() != null) {
                cartDeliveryGroup.setDeliverToStreet(deliveryAddress.getStreet());
            }
            if (deliveryAddress.getCity() != null) {
                cartDeliveryGroup.setDeliverToCity(deliveryAddress.getCity());
            }
            if (deliveryAddress.getState() != null) {
                cartDeliveryGroup.setDeliverToState(deliveryAddress.getState());
            }
            if (deliveryAddress.getPostalCode() != null) {
                cartDeliveryGroup.setDeliverToPostalCode(deliveryAddress.getPostalCode());
            }
            if (deliveryAddress.getCountry() != null) {
                cartDeliveryGroup.setDeliverToCountry(deliveryAddress.getCountry());
            }
        }

        if (itemArrange.getDeliverToName() != null) {
            cartDeliveryGroup.setDeliverToName(itemArrange.getDeliverToName());
        }
        if (itemArrange.getDeliverToFirstName() != null) {
            cartDeliveryGroup.setDeliverToFirstName(itemArrange.getDeliverToFirstName());
        }
        if (itemArrange.getDeliverToLastName() != null) {
            cartDeliveryGroup.setDeliverToLastName(itemArrange.getDeliverToLastName());
        }
        if (itemArrange.getDeliverToCompanyName() != null) {
            cartDeliveryGroup.setCompanyName(itemArrange.getDeliverToCompanyName());
        }

        cart.getCartDeliveryGroups().add(cartDeliveryGroup);
        return cartDeliveryGroup;
    }
}