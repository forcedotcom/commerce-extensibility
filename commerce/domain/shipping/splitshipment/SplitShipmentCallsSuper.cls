/**
 * @description Sample Split Shipment Service Apex that calls the default implementation.
 */
global class SplitShipmentCallsSuper extends CartExtension.SplitShipmentService {

    /**
     * @description All classes extending CartExtension.SplitShipmentService must have a default constructor defined.
     */
    global SplitShipmentCallsSuper() {}

    /**
     * @description Constructor used by unit tests only. See <<SplitShipmentUnitTest>>.
     * @param mockService Mocked service which can be used to stub the default Split Shipment logic.
     */
    global SplitShipmentCallsSuper(final CartExtension.SplitShipmentServiceMock mockService) {
        super(mockService);
    }

    public override void arrangeItems(CartExtension.ItemArrangementRequest request) {
        super.arrangeItems(request);
    }
}