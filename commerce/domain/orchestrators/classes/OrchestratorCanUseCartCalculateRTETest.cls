/**
 * @description A sample unit test for CartCalculateHandlesCartCalculateRTE and CartCalculateRethrowsCartCalculateRTE.
 */
@IsTest
global class OrchestratorCanUseCartCalculateRTETest {

    @IsTest
    public static void testOrchestratorCanThrowCartCalculateRTE() {
        // Arrange
        CartExtension.Cart cart = CartExtension.CartTestUtil.createCart();
        CartCalculateThrowsCartCalculateRTE orchestrator = new CartCalculateThrowsCartCalculateRTE();
        CartExtension.CartCalculateOrchestratorRequest request = new CartExtension.CartCalculateOrchestratorRequest(
                cart,
                new CartExtension.BuyerActionsMock(cart),
                CartExtension.OptionalBuyerActionDetails.empty());

        String expectedExceptionMsg = 'Runtime exception from custom Apex Orchestrator';

        try {
            // Act
            Test.startTest();
            orchestrator.calculate(request);
            Test.stopTest();

            // Assert
            Assert.fail('No exception was thrown, when CartExtension.CartCalculateRuntimeException was expected');
        } catch (CartExtension.CartCalculateRuntimeException e) {
            Assert.areEqual(expectedExceptionMsg, e.getMessage());
        } catch (Exception e) {
            Assert.fail('Some other Exception was thrown, when CartExtension.CartCalculateRuntimeException was expected');
        }
    }

    @IsTest
    public static void testOrchestratorCanHandleCartCalculateRTEThrownFromApexCalculator() {
        // Arrange
        CartExtension.Cart cart = createCart();

        setUpExtension(cart.getWebStoreId(),
                'Commerce_Domain_Pricing_CartCalculator',
                'PricingCalculatorThrowsRTE',
                cart);

        CartCalculateHandlesCartCalculateRTE orchestrator = new CartCalculateHandlesCartCalculateRTE();
        CartExtension.CartCalculateOrchestratorRequest request = new CartExtension.CartCalculateOrchestratorRequest(
                cart,
                new CartExtension.BuyerActionsMock(cart),
                CartExtension.OptionalBuyerActionDetails.empty());

        try {
            // Act
            Test.startTest();
            orchestrator.calculate(request);
            Test.stopTest();
        } catch (CartExtension.CartCalculateRuntimeException e) {
            Assert.fail('CartExtension.CartCalculateRuntimeException should not have been thrown');
        } catch (Exception e) {
            Assert.fail('Exception should not have been thrown');
        }
    }

    private static CartExtension.Cart createCart() {
        Account account = new Account(Name = 'My Account');
        insert account;

        WebStore webStore = new WebStore(Name = 'My WebStore', OptionsCartCalculateEnabled = true);
        insert webStore;

        WebCart webCart = new WebCart(
                Name = 'My Cart',
                WebStoreId = webStore.Id,
                AccountId = account.Id,
                Status = 'Checkout');
        insert webCart;

        CartDeliveryGroup deliveryGroup = new CartDeliveryGroup(Name = 'DELIVERYGROUP_NAME', CartId = webCart.Id);
        insert deliveryGroup;

        CartItem cartItem1 = new CartItem(
                Name = 'My Cart Item 1',
                CartId = webCart.Id,
                CartDeliveryGroupId = deliveryGroup.Id,
                SKU = 'My SKU 1',
                ListPrice = 0.00,
                Type = CartExtension.SalesItemTypeEnum.PRODUCT.name());
        insert cartItem1;

        return CartExtension.CartTestUtil.getCart(webCart.Id);
    }

    private static void setUpExtension(Id webStoreId, String extensionPointName, String apexClassName, CartExtension.Cart cart) {
        ApexClass apexClass = [SELECT Id FROM ApexClass WHERE Name = :apexClassName LIMIT 1];
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            RegisteredExternalService registeredExternalService = new RegisteredExternalService(
                    DeveloperName = extensionPointName,
                    MasterLabel = extensionPointName,
                    ExternalServiceProviderId = apexClass.Id,
                    ExtensionPointName = extensionPointName,
                    ExternalServiceProviderType = 'Extension'
            );
            insert registeredExternalService;

            StoreIntegratedService storeIntegratedService = new StoreIntegratedService(Integration = registeredExternalService.Id,
                    ServiceProviderType = 'Extension', StoreId = webStoreId);
            insert storeIntegratedService;
        }
    }
}