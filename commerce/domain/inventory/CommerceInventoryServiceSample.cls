public virtual class CommerceInventoryServiceSample extends commerce_inventory.CommerceInventoryService {

    public override commerce_inventory.UpsertReservationResponse upsertReservation(commerce_inventory.UpsertReservationRequest upsertReservationRequest,
                                                                   commerce_inventory.InventoryReservation currentReservation,
                                                                   String reservationChangeType) {
        commerce_inventory.UpsertReservationResponse response = new commerce_inventory.UpsertReservationResponse();
        response.setSucceed(true);
        response.setReservationSourceId(upsertReservationRequest.getReservationSourceId());
        response.setReservationIdentifier(upsertReservationRequest.getReservationIdentifier());
        List<commerce_inventory.UpsertItemReservationResponse> responseItems = new List<commerce_inventory.UpsertItemReservationResponse>();

        for(commerce_inventory.UpsertItemReservationRequest item : upsertReservationRequest.getItems()) {
            commerce_inventory.UpsertItemReservationResponse  responseItem = new commerce_inventory.UpsertItemReservationResponse();
            responseItem.setQuantity(item.getQuantity());
            responseItem.setReservedAtLocationId(item.getReservedAtLocationId());
            responseItem.setItemReservationSourceId(item.getItemReservationSourceId());
            responseItem.setProductId(item.getProductId());
            responseItems.add(responseItem);
        }

        response.setItems(responseItems);

        if (upsertReservationRequest.getItems().size() != response.getItems().size()) {
            throw new NoDataFoundException();
        }

        return response;
    }

     public override commerce_inventory.DeleteReservationResponse deleteReservation(String reservationId,  commerce_inventory.InventoryReservation currentReservation) {
         system.debug('deleteReservation');
         return callDefaultDeleteReservation(reservationId, currentReservation);
    }

    public override commerce_inventory.InventoryReservation getReservation(String reservationId) {
        return callDefaultGetReservation(reservationId);
    }

    public override commerce_inventory.InventoryCheckAvailability checkInventory(commerce_inventory.InventoryCheckAvailability request) {
        for(commerce_inventory.InventoryCheckItemAvailability item : request.getInventoryCheckItemAvailability()) {
            item.setAvailable(true);
        }
        return request;
    }

    public override commerce_inventory.InventoryLevelsResponse getInventoryLevel(commerce_inventory.InventoryLevelsRequest request) {
        commerce_inventory.InventoryLevelsResponse response = new commerce_inventory.InventoryLevelsResponse();
        Set<commerce_inventory.InventoryLevelsItemResponse> items = new Set<commerce_inventory.InventoryLevelsItemResponse>();
        for(commerce_inventory.InventoryLevelsItemRequest item : request.getItemInventoryLevelRequests()) {
            commerce_inventory.InventoryLevelsItemResponse itemResponse = new commerce_inventory.InventoryLevelsItemResponse();
            itemResponse.setProductId(item.getProductId());
            itemResponse.setLocationSourceId(item.getLocationSourceId());
            itemResponse.setInventoryLocationSourceType('LocationGroup');
            itemResponse.setOnHand(double.valueOf('10.0'));
            itemResponse.setAvailableToFulfill(double.valueOf('10.0'));
            itemResponse.setAvailableToOrder(double.valueOf('10.0'));
            items.add(itemResponse);
        }

        response.setItemsInventoryLevels(items);

        if (response.getItemsInventoryLevels().size() != request.getItemInventoryLevelRequests().size()) {
            throw new NoDataFoundException();
        }

        return response;
    }
    
	@TestVisible
    private virtual commerce_inventory.DeleteReservationResponse callDefaultDeleteReservation(String reservationId,  commerce_inventory.InventoryReservation currentReservation) {
                 system.debug('callDefaultDeleteReservation');
        return super.deleteReservation(reservationId, currentReservation);
    }
    
	@TestVisible
    private virtual commerce_inventory.InventoryReservation callDefaultGetReservation(String reservationId) {
         return super.getReservation(reservationId);
    }
    
   
}