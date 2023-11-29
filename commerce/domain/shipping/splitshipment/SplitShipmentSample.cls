/**
 * @description Custom Split Shipment Service sample.
 */
global class SplitShipmentSample extends CartExtension.SplitShipmentService {

    public virtual override void arrangeItems(CartExtension.ItemArrangementRequest request) {
        CartExtension.Cart cart = request.getCart();

        Iterator<CartExtension.ItemArrange> iterator = request.getItemArrangeList().iterator();
        while (iterator.hasNext()) {
            CartExtension.ItemArrange itemArrange = iterator.next();
            arrangeItemsByProductConveyability(cart, itemArrange);
        }
    }

    /**
     * @description Split up the shipment by conveyable and non-conveyable products. Products that are non-conveyable
     * cannot go on the conveyor belt at the warehouse because they are too big, bulky, and/or heavy. This means that
     * these non-conveyable items may require additional packaging and will take longer to get onto a delivery truck.
     * @param cart Holds details about a Cart
     * @param itemArrange Holds information on how the item should be arranged
     */
    private void arrangeItemsByProductConveyability(CartExtension.Cart cart, CartExtension.ItemArrange itemArrange) {
        // Get conveyable info for the product
        List<Product2> products = [SELECT IsConveyable__c FROM Product2 WHERE Id =: itemArrange.getProductId() LIMIT 1];
        Boolean isConveyable = Boolean.valueOf(products[0].IsConveyable__c);

        // If the product is non-conveyable, then we need to move the item to a non-conveyable CartDeliveryGroup
        if (!isConveyable) {
            // Check to see if we already have a CartDeliveryGroup for non-conveyable items
            CartExtension.CartDeliveryGroup nonConveyableCartDeliveryGroup = findNonConveyableCartDeliveryGroup(cart);

            if (nonConveyableCartDeliveryGroup == null) {
                // Create a CartDeliveryGroup for items that are non-conveyable
                nonConveyableCartDeliveryGroup = createNonConveyableCartDeliveryGroup(cart, itemArrange);
            }

            // Move the non-conveyable CartItem to the non-conveyable CartDeliveryGroup
            moveCartItemToTargetCartDeliveryGroup(cart, itemArrange, nonConveyableCartDeliveryGroup);
        }
    }

    /**
     * @description Check to see if we already have a non-conveyable CartDeliveryGroup in the Cart and if so, return it.
     * @param cart Holds details about a Cart
     *
     * @return CartExtension.CartDeliveryGroup
     */
    private CartExtension.CartDeliveryGroup findNonConveyableCartDeliveryGroup(CartExtension.Cart cart) {
        Iterator<CartExtension.CartDeliveryGroup> iterator = cart.getCartDeliveryGroups().iterator();
        while (iterator.hasNext()) {
            CartExtension.CartDeliveryGroup cartDeliveryGroup = iterator.next();

            // Check to see if we already have a CartDeliveryGroup for non-conveyable items
            if (!(Boolean)cartDeliveryGroup.getCustomField('IsConveyable__c')) {
                return cartDeliveryGroup;
            }
        }

        // We don't have a CartDeliveryGroup
        return null;
    }

    /**
     * @description Creates a Cart Delivery Group for items that cannot go on the conveyor belt in the warehouse.
     * @param cart Holds details about a Cart
     * @param itemArrange Holds details of how to arrange an item between CartDeliveryGroups
     */
    private CartExtension.CartDeliveryGroup createNonConveyableCartDeliveryGroup(CartExtension.Cart cart, CartExtension.ItemArrange itemArrange) {
        // Set up the non-conveyable CartDeliveryGroup
        CartExtension.CartDeliveryGroup cartDeliveryGroup = new CartExtension.CartDeliveryGroup();
        cartDeliveryGroup.setName('Non-Conveyable Cart Delivery Group');
        cartDeliveryGroup.setCustomField('IsConveyable__c', false);

        Address deliveryAddress = itemArrange.getDeliveryAddress();

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

    /**
     * @description Move the CartItem to the provided CartDeliveryGroup.
     * @param cart Representation of a WebCart
     * @param itemArrange Holds details of how to arrange an item between CartDeliveryGroups
     * @param targetCartDeliveryGroup The CartDeliveryGroup to which the provided CartItem should be moved
     */
    private void moveCartItemToTargetCartDeliveryGroup(CartExtension.Cart cart,
            CartExtension.ItemArrange itemArrange,
            CartExtension.CartDeliveryGroup targetCartDeliveryGroup) {
        Iterator<CartExtension.CartItem> iterator = cart.getCartItems().iterator();
        while (iterator.hasNext()) {
            CartExtension.CartItem cartItem = iterator.next();
            if (cartItem.getId() == itemArrange.getCartItemId()) {
                cartItem.setCartDeliveryGroup(targetCartDeliveryGroup);
            }
        }
    }
}