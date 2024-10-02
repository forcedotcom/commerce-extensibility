@isTest
public class CommerceInventoryServiceSampleTest {

    @IsTest
    public static void testUpsertReservation() {
        // Arrange
        commerce_inventory.UpsertItemReservationRequest itemRequest = new commerce_inventory.UpsertItemReservationRequest(double.valueOf('10.0'), Id.valueOf('0ghSG0000000JFbYAM'), Id.valueOf('0a9SG000003AfY1YAK'), Id.valueOf('01tSG000001NNgKYAW'));
        List<commerce_inventory.UpsertItemReservationRequest> itemReqeustList = new List<commerce_inventory.UpsertItemReservationRequest>();
        itemReqeustList.add(itemRequest);
        commerce_inventory.upsertReservationRequest request = new commerce_inventory.upsertReservationRequest('4y2ml0e1oG2qrcfdbNnNyk', '0a9SG000003AfY1YAK', itemReqeustList);
        CommerceInventoryServiceSample inventoryService = new CommerceInventoryServiceSample();
        
        // Act
        Test.startTest();
        commerce_inventory.UpsertReservationResponse actualResponse = inventoryService.upsertReservation(request, null,'');
        Test.stopTest();
        
        // Assert
        commerce_inventory.UpsertItemReservationResponse itemActualResponse = actualResponse.getItems().get(0);
        commerce_inventory.UpsertReservationResponse expectedResponse = createUpsertReservationResponse();
        commerce_inventory.UpsertItemReservationResponse itemExpectedResponse = expectedResponse.getItems().get(0);
        
        System.assertEquals(itemExpectedResponse.getProductId(), itemActualResponse.getProductId());
        
    }
    
    @IsTest
    public static void testDeleteReservation() {
        // Arrange
        CommerceInventoryServiceSampleMock inventoryServiceMock = new CommerceInventoryServiceSampleMock();
      
        // Act
        commerce_inventory.DeleteReservationResponse response = inventoryServiceMock.deleteReservation('10rxx000007LbIRAA0', null);
        
        // Assert
        System.assertEquals(true, response.getSucceed());
    }

   @IsTest
    public static void testGetReservation() {

        // Arrange
        CommerceInventoryServiceSampleMock inventoryServiceMock = new CommerceInventoryServiceSampleMock();
       
        // Act
        commerce_inventory.InventoryReservation response = inventoryServiceMock.getReservation('10rxx000007LbIRAA0');
        commerce_inventory.InventoryReservation response2 = inventoryServiceMock.getReservation('10rxx000007LbIRAA1');

        // Assert
        System.assertNotEquals(null, response);
        System.assertEquals(null, response2);
    }
    
    @IsTest
    public static void testCheckInventory() {
        // Arrange
        commerce_inventory.InventoryCheckItemAvailability itemRequest = new commerce_inventory.InventoryCheckItemAvailability();
        Set<commerce_inventory.InventoryCheckItemAvailability> itemReqeustSet = new Set<commerce_inventory.InventoryCheckItemAvailability>();
        itemReqeustSet.add(itemRequest);
        commerce_inventory.InventoryCheckAvailability request = new commerce_inventory.InventoryCheckAvailability(itemReqeustSet);
        
        CommerceInventoryServiceSample inventoryService = new CommerceInventoryServiceSample();
        // Act
        Test.startTest();
        commerce_inventory.InventoryCheckAvailability actualResponse = inventoryService.checkInventory(request);
        Test.stopTest();
        // Assert
        commerce_inventory.InventoryCheckItemAvailability itemActualResponse;
        for (commerce_inventory.InventoryCheckItemAvailability item : actualResponse.getInventoryCheckItemAvailability()) {
            itemActualResponse = item;
            break;
        }
        System.assertEquals(true, itemActualResponse.isAvailable()); 
    }

    @IsTest
    public static void testgetInventoryLevel() {
        // Arrange
        commerce_inventory.InventoryLevelsItemRequest itemRequest = new commerce_inventory.InventoryLevelsItemRequest(Id.valueOf('01txx0000001aBcAAI'), 'sku1', Id.valueOf('a1Bxx0000005T9E'));
		Set<commerce_inventory.InventoryLevelsItemRequest> itemRequestSet = new Set<commerce_inventory.InventoryLevelsItemRequest>();
        itemRequestSet.add(itemRequest);
        commerce_inventory.InventoryLevelsRequest request = new commerce_inventory.InventoryLevelsRequest(null, itemRequestSet);

        CommerceInventoryServiceSample inventoryService = new CommerceInventoryServiceSample();
        // Act
        Test.startTest();
        commerce_inventory.InventoryLevelsResponse actualResponse = inventoryService.getInventoryLevel(request);
        Test.stopTest();
        // Assert
        commerce_inventory.InventoryLevelsItemResponse itemActualResponse;
        for (commerce_inventory.InventoryLevelsItemResponse item : actualResponse.getItemsInventoryLevels()) {
            itemActualResponse = item;
            break;
        }
        commerce_inventory.InventoryLevelsResponse expectedResponse = createInventoryLevelsResponse();
        commerce_inventory.InventoryLevelsItemResponse itemExpectedResponse;
        for (commerce_inventory.InventoryLevelsItemResponse item : expectedResponse.getItemsInventoryLevels()) {
            itemexpectedResponse = item;
            break;
        }

        System.assertEquals(itemExpectedResponse.getProductId(), itemActualResponse.getProductId());       
    }

    @IsTest
    public static void testgetInventoryLevelDataValidation() {

        // Arrange
        Set<commerce_inventory.InventoryLevelsItemRequest> itemRequest = new Set<commerce_inventory.InventoryLevelsItemRequest>();
        commerce_inventory.InventoryLevelsRequest request = new commerce_inventory.InventoryLevelsRequest(null, itemRequest);
        CommerceInventoryServiceSample inventoryService = new CommerceInventoryServiceSample();

        String errorMessage  = '';

        // Act
        Test.startTest();
        try {
            commerce_inventory.InventoryLevelsResponse actualResponse = inventoryService.getInventoryLevel(request);
            errorMessage  = 'Sucess Response';
        } catch(InventoryValidationException validationtEx) {
            errorMessage = validationtEx.getMessage();
            
        }
        Test.stopTest();

        // Assert
        System.assertEquals(true,errorMessage.contains('Invalid request size'));
    }

    private static commerce_inventory.UpsertReservationResponse createUpsertReservationResponse() {
        commerce_inventory.UpsertReservationResponse response = new commerce_inventory.UpsertReservationResponse();
        List<commerce_inventory.UpsertItemReservationResponse> items = new List<commerce_inventory.UpsertItemReservationResponse>();
        commerce_inventory.UpsertItemReservationResponse itemResponse = new commerce_inventory.UpsertItemReservationResponse();
        itemResponse.setQuantity(double.valueOf('10.0'));
        itemResponse.setReservedAtLocationId('0ghSG0000000JFbYAM');
        itemResponse.setItemReservationSourceId('0a9SG000003AfY1YAK');
        itemResponse.setProductId('01tSG000001NNgKYAW');
        items.add(itemResponse);
        response.setItems(items);
        return response;
    }

    private static commerce_inventory.InventoryLevelsResponse createInventoryLevelsResponse() {
        commerce_inventory.InventoryLevelsResponse response = new commerce_inventory.InventoryLevelsResponse();
        Set<commerce_inventory.InventoryLevelsItemResponse> items = new Set<commerce_inventory.InventoryLevelsItemResponse>();
        commerce_inventory.InventoryLevelsItemResponse itemResponse = new commerce_inventory.InventoryLevelsItemResponse();
        itemResponse.setProductId('01txx0000001aBcAAI');
        itemResponse.setLocationSourceId('a1Bxx0000005T9E');
        itemResponse.setInventoryLocationSourceType('LocationGroup');
        itemResponse.setOnHand(double.valueOf('10.0'));
        itemResponse.setAvailableToFulfill(double.valueOf('10.0'));
        itemResponse.setAvailableToOrder(double.valueOf('10.0'));
        items.add(itemResponse);
        response.setItemsInventoryLevels(items);
        return response;
    }
    
    private class CommerceInventoryServiceSampleMock extends CommerceInventoryServiceSample {
        
        public override commerce_inventory.DeleteReservationResponse callDefaultDeleteReservation(String reservationId,  commerce_inventory.InventoryReservation currentReservation) {
            commerce_inventory.DeleteReservationResponse responseMock = new commerce_inventory.DeleteReservationResponse();
            responseMock.setSucceed(true);
            return responseMock;
        }
        
    
        public override commerce_inventory.InventoryReservation callDefaultGetReservation(String reservationId) {
            if (reservationId == '10rxx000007LbIRAA0') {
                commerce_inventory.InventoryReservation responseMock = new commerce_inventory.InventoryReservation();
                responseMock.setReservationIdentifier(reservationId);
                return responseMock;    
            } else {
                return null;
            }        
        }
    }   
}