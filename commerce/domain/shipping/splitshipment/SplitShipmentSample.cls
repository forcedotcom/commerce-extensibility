/**
 * @description Custom Split Shipment Service sample.
 */
global class SplitShipmentSample extends CartExtension.SplitShipmentService {

    /**
     * @description All classes extending CartExtension.SplitShipmentService must have a default constructor defined.
     */
    global SplitShipmentSample() {}

    /**
     * @description Constructor used by unit tests only. See <<SplitShipmentUnitTest>>.
     * @param mockService Mocked service which can be used to stub the default Split Shipment logic.
     */
    global SplitShipmentSample(final CartExtension.SplitShipmentServiceMock mockService) {
        super(mockService);
    }

    public virtual override void arrangeItems(CartExtension.ItemArrangementRequest request) {
        CartExtension.Cart cart = request.getCart();
        List<CartExtension.ItemArrange> itemArrangeList = request.getItemArrangeList();

        for (CartExtension.ItemArrange itemArrange : itemArrangeList) {
            CartExtension.CartDeliveryGroup cartDeliveryGroup = findOrCreateDeliveryGroup(cart, itemArrange);
            updateOrCreateCartItemToCartDeliveryGroup(cart, cartDeliveryGroup, itemArrange);
        }
    }

    /**
     * @description Either finds a Cart Delivery Group based on the given inputs or creates a new one.
     * @param cart Representation of a `WebCart` record
     * @param itemArrange Holds details of how to arrange an item between delivery groups
     */
    private CartExtension.CartDeliveryGroup findOrCreateDeliveryGroup(CartExtension.Cart cart, CartExtension.ItemArrange itemArrange) {
        Address deliveryAddress = itemArrange.getDeliveryAddress();

        if (itemArrange.getDeliveryGroupId() != null) {
            Iterator<CartExtension.CartDeliveryGroup> cdgIterator = cart.getCartDeliveryGroups().iterator();
            while (cdgIterator.hasNext()) {
                CartExtension.CartDeliveryGroup cartDeliveryGroup = cdgIterator.next();
                if (cartDeliveryGroup.getId() == itemArrange.getDeliveryGroupId()) {
                    return cartDeliveryGroup;
                }
            }
        } else if ((itemArrange.getDeliveryAddress() != null || itemArrange.getDeliveryAddressId() != null) && itemArrange.getDeliveryGroupName() != null) {
            Iterator<CartExtension.CartDeliveryGroup> cdgIterator = cart.getCartDeliveryGroups().iterator();

            if (itemArrange.getDeliveryAddress() != null) {
                deliveryAddress = itemArrange.getDeliveryAddress();
            } else {
                ID accountId = cart.getAccountId();
                ID addressId = itemArrange.getDeliveryAddressId();
                ContactPointAddress contactPointAddress = [SELECT Address FROM ContactPointAddress WHERE (ParentId = :accountId AND Id = :addressId) LIMIT 1];
                deliveryAddress = contactPointAddress.Address;
            }
            while (cdgIterator.hasNext()) {
                CartExtension.CartDeliveryGroup cartDeliveryGroup = cdgIterator.next();
                if (areAddressesEqual(deliveryAddress, cartDeliveryGroup.getDeliverToAddress()) && itemArrange.getDeliveryGroupName().equals(cartDeliveryGroup.getName())) {
                    return cartDeliveryGroup;
                }
            }
        }
        return createCartDeliveryGroup(cart, itemArrange, deliveryAddress);
    }

    /**
     * @description Creates a Cart Delivery Group.
     * @param cart Representation of a `WebCart` record
     * @param itemArrange Holds details of how to arrange an item between delivery groups
     * @param deliveryAddress Address information for where the item is being delivered
     */
    private CartExtension.CartDeliveryGroup createCartDeliveryGroup(CartExtension.Cart cart, CartExtension.ItemArrange itemArrange, Address deliveryAddress) {
        CartExtension.CartDeliveryGroup cartDeliveryGroup = new CartExtension.CartDeliveryGroup();

        if (itemArrange.getDeliveryGroupName() != null) {
            cartDeliveryGroup.setName(itemArrange.getDeliveryGroupName());
        }

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
            if (deliveryAddress.getStateCode() != null) {
                cartDeliveryGroup.setDeliverToStateCode(deliveryAddress.getStateCode());
            }
            if (deliveryAddress.getCountryCode() != null) {
                cartDeliveryGroup.setDeliverToCountryCode(deliveryAddress.getCountryCode());
            }
            if (deliveryAddress.getLatitude() != null) {
                cartDeliveryGroup.setDeliverToLatitude(deliveryAddress.getLatitude());
            }
            if (deliveryAddress.getLongitude() != null) {
                cartDeliveryGroup.setDeliverToLongitude(deliveryAddress.getLongitude());
            }
            if (deliveryAddress.getGeocodeAccuracy() != null) {
                cartDeliveryGroup.setDeliverToGeocodeAccuracy(deliveryAddress.getGeocodeAccuracy());
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
     * @description Sets the quantity and associates the target Cart Delivery Group for a Cart Item, if it is provided. 
     * If a Cart Item is not provided, then a new one is created with the provided quantity and Cart Delivery Group.
     * 
     * @param cart Representation of a `WebCart` record
     * @param targetCartDeliveryGroup The Cart Delivery Group to associate with the Cart Item
     * @param itemArrange Holds details of how to arrange an item between delivery groups
     */
    private void updateOrCreateCartItemToCartDeliveryGroup(CartExtension.Cart cart, CartExtension.CartDeliveryGroup targetCartDeliveryGroup, CartExtension.ItemArrange itemArrange) {
        if (itemArrange.getCartItemId() == null) {
            CartExtension.CartItem cartItem = new CartExtension.CartItem(CartExtension.SalesItemTypeEnum.PRODUCT, targetCartDeliveryGroup, 'My Cart Item');
            cartItem.setProduct2Id(itemArrange.getProductId());
            cartItem.setQuantity(itemArrange.getQuantity());
            cart.getCartItems().add(cartItem);
        } else {
            Iterator<CartExtension.CartItem> cartItemsIterator = cart.getCartItems().iterator();
            while (cartItemsIterator.hasNext()) {
                CartExtension.CartItem cartItem = cartItemsIterator.next();
                if (cartItem.getId() == itemArrange.getCartItemId()) {
                    if (itemArrange.getQuantity() == 0.0) {
                        cart.getCartItems().remove(cartItem);
                    } else {
                        cartItem.setQuantity(itemArrange.getQuantity());
                        cartItem.setCartDeliveryGroup(targetCartDeliveryGroup);
                    }
                }
            }
        }
    }

    /**
     * @description Checks whether two addresses are equal.
     * @param address1 Address 1
     * @param address2 Address 2
     */
    private Boolean areAddressesEqual(Address address1, Address address2) {
        if (address1 == null && address2 == null) {
            return true;
        }
        if (address1 == null || address2 == null) {
            return false;
        }
        if (address1.getCity() != address2.getCity()) {
            return false;
        }
        if (address1.getCountry() != address2.getCountry()) {
            return false;
        }
        if (address1.getCountryCode() != address2.getCountryCode()) {
            return false;
        }
        if (address1.getGeocodeAccuracy() != address2.getGeocodeAccuracy()) {
            return false;
        }
        if (address1.getPostalCode() != address2.getPostalCode()) {
            return false;
        }
        if (address1.getState() != address2.getState()) {
            return false;
        }
        if (address1.getStateCode() != address2.getStateCode()) {
            return false;
        }
        if (address1.getStreet() != address2.getStreet()) {
            return false;
        }

        return true;
    }
}