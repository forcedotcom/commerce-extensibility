/**
* @description This is a sample implementation of Create Order extension.
* This class must extend CartExtension.CheckoutCreateOrder and must be linked to the Create Order extension point (Commerce_Domain_Checkout_CreateOrder).
*/
public virtual class CreateOrderSample extends CartExtension.CheckoutCreateOrder{

    public virtual override CartExtension.CreateOrderResponse createOrder(CartExtension.CreateOrderRequest request) {
        CartExtension.Cart cart = request.getCart();
        CartExtension.CreateOrderResponse response = callDefault(request);        
        CartExtension.OrderGraph orderGraph = response.getOrderGraph();
        Order order = orderGraph.getOrder();
        order.Description = 'Total rounded up cost of products: ';
        List<OrderItem> orderItems = orderGraph.getOrderItems();        
        Decimal roundedPrice = 0.0;
        for (OrderItem orderItem : orderItems) {
            roundedPrice += orderItem.UnitPrice.round(System.RoundingMode.CEILING);
        }
        order.Description += roundedPrice;
        return response;
    }
    
    @TestVisible
    private virtual CartExtension.CreateOrderResponse callDefault(CartExtension.CreateOrderRequest request) {
        return super.createOrder(request);        
    }


}