public class CommerceInventoryServiceSample extends commerce_inventory.CommerceInventoryService {

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
        Schema.InventoryReservation invReservation = [SELECT Id FROM InventoryReservation WHERE ID =: reservationId];
        commerce_inventory.DeleteReservationResponse response = new commerce_inventory.DeleteReservationResponse();
        response.setSucceed(true);
        try {
            delete(invReservation);
        } catch(Exception ex) {
            response.setSucceed(false);
            response.setErrorMessage(ex.getMessage());
        }
        return response;
    }

    public override commerce_inventory.InventoryReservation getReservation(String reservationId) {
        if (reservationId == 'INVALID') {
             throw new NoDataFoundException();
        }

        List<Schema.InventoryReservation> invReservations = [SELECT Id,
                                                                    ReservationDurationInSeconds,
                                                                    ErrorMessage,
                                                                    ErrorCode,
                                                                    ReservationSourceId,
                                                                    ReservationIdentifier
                                                             FROM   InventoryReservation
                                                             WHERE  ReservationIdentifier =: reservationId];

        if (invReservations.size() == 0) {
            return null;
        }

        Schema.InventoryReservation invReservation = invReservations.get(0);

        commerce_inventory.InventoryReservation response = new  commerce_inventory.InventoryReservation();

        response.setId(invReservation.Id);
        response.setDurationInSeconds(10);
        response.setReservationIdentifier(invReservation.ReservationIdentifier);
        response.setReservationSourceId(invReservation.ReservationSourceId);
        response.setErrorCode(invReservation.ErrorCode);
        response.setErrorMessage(invReservation.ErrorMessage);

        List<Schema.InventoryItemReservation> invItemsReservations = [SELECT Id,
                                                                             InventoryReservationId,
                                                                             Quantity,
                                                                             ReservedAtLocationId,
                                                                             ItemReservationSourceId,
                                                                             ProductId,
                                                                             ErrorCode,
                                                                             ErrorMessage
                                                                      FROM   InventoryItemReservation
                                                                      WHERE  InventoryReservationId =: response.getId()];


        List<commerce_inventory.InventoryItemReservation> responseItems = new List<commerce_inventory.InventoryItemReservation>();

         if (invItemsReservations.size() > 0) {
            for(Schema.InventoryItemReservation item : invItemsReservations) {
                commerce_inventory.InventoryItemReservation responseItem = new commerce_inventory.InventoryItemReservation();
                responseItem.setId(item.Id);
                responseItem.setInventoryReservationId(item.InventoryReservationId);
                responseItem.setProductId(item.ProductId);
                responseItem.setQuantity(Double.valueOf(item.Quantity));
                responseItem.setItemReservationSourceId(item.ItemReservationSourceId);
                responseItem.setReservedAtLocationId(item.ReservedAtLocationId);
                responseItem.setErrorMessage(item.ErrorMessage);
                responseItem.setErrorCode(item.ErrorCode);
                responseItems.add(responseItem);
            }

            response.setItems(responseItems);

            if (response.getItems() != null && responseItems.size() != response.getItems().size()) {
                throw new NoDataFoundException();
            }
         }
         return response;
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

            if (item.getProductId() !=  Id.valueOf('01txx0000006uwD')) {
                items.add(itemResponse);
            }

        }

        response.setItemsInventoryLevels(items);

        if (response.getItemsInventoryLevels().size() != request.getItemInventoryLevelRequests().size()) {
            throw new NoDataFoundException();
        }

        return response;
    }
}