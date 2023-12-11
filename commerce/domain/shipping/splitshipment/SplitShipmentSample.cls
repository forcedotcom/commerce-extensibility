/**
 * @description Custom Split Shipment Service sample.
 */
global class SplitShipmentSample extends CartExtension.SplitShipmentService {

    public virtual override void arrangeItems(CartExtension.ItemArrangementRequest request) {
        CartExtension.Cart cart = request.getCart();
        Iterator<CartExtension.ItemArrange> itemArrangeIterator = request.getItemArrangeList().iterator();

        // Get all productIds from the ItemArrange list
        List<Id> productIds = new List<Id>();
        while (itemArrangeIterator.hasNext()) {
            CartExtension.ItemArrange itemArrange = itemArrangeIterator.next();
            productIds.add(itemArrange.getProductId());
        }

        // Get conveyability info for each product
        List<Product2> products = [
            SELECT
                Id
                , IsConveyable__c
            FROM Product2
            WHERE Id IN :productIds
        ];
        Iterator<Product2> productsIterator = products.iterator();

        Map<Id,Boolean> productConveyability = new Map<Id,Boolean>();
        while (productsIterator.hasNext()) {
            Product2 product = productsIterator.next();
            productConveyability.put(product.Id, product.IsConveyable__c);
        }

        // Arrange items by conveyability
        itemArrangeIterator = request.getItemArrangeList().iterator();
        while (itemArrangeIterator.hasNext()) {
            CartExtension.ItemArrange itemArrange = itemArrangeIterator.next();

            // If the item is non-conveyable, then move it to a non-conveyable CartDeliveryGroup
            if (productConveyability.get(itemArrange.getProductId()) != true) {
                arrangeNonConveyableItem(cart, itemArrange);
            }
        }
    }

    /**
     * @description Split up the shipment by conveyable and non-conveyable products. Products that are non-conveyable
     * cannot go on the conveyor belt at the warehouse because they are too big, bulky, and/or heavy. This means that
     * these non-conveyable items may require additional packaging and will take longer to get onto a delivery truck.
     * @param cart Holds details about a Cart
     * @param itemArrange Holds information on how the item should be arranged
     */
    private void arrangeNonConveyableItem(CartExtension.Cart cart, CartExtension.ItemArrange itemArrange) {
        // Check to see if we already have a CartDeliveryGroup for non-conveyable items
        CartExtension.CartDeliveryGroup nonConveyableCartDeliveryGroup = findNonConveyableCartDeliveryGroup(cart);

        if (nonConveyableCartDeliveryGroup == null) {
            // Create a CartDeliveryGroup for items that are non-conveyable
            nonConveyableCartDeliveryGroup = createNonConveyableCartDeliveryGroup(cart, itemArrange);
        }

        // Move the non-conveyable CartItem to the non-conveyable CartDeliveryGroup
        moveCartItemToTargetCartDeliveryGroup(cart, itemArrange, nonConveyableCartDeliveryGroup);
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