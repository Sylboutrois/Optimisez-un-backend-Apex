@isTest
public class Test_CalculMontant {

    static Id pricebookId;
    static Id productId;
    static Id pricebookEntryId;
    static Id accountId;

    @testSetup
    static void setupTestData() {
        // Utilisation directe du Pricebook standard par son ID
        Pricebook2 standardPriceBook = new Pricebook2(Id = '01sgL0000000sekQAA', IsActive = true);
        update standardPriceBook;
        pricebookId = standardPriceBook.Id;

        // Création d'un produit
        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
        insert testProduct;
        productId = testProduct.Id;

        // Ajout d'une entrée de prix au Pricebook standard
        PricebookEntry standardEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = productId,
            UnitPrice = 100,
            IsActive = true
        );
        insert standardEntry;
        pricebookEntryId = standardEntry.Id;

        // Création d'un compte
        Account testAccount = new Account(Name = 'Test Account', Chiffre_d_affaire__c = 0);
        insert testAccount;
        accountId = testAccount.Id;

        // Création de 10 commandes
        List<Order> orders = new List<Order>();
        for (Integer i = 1; i <= 10; i++) {
            orders.add(new Order(
                Name = 'Order' + i,
                Status = 'Draft',
                AccountId = accountId,
                Pricebook2Id = pricebookId,
                EffectiveDate = System.today()
            ));
        }
        insert orders;

        // Ajout d'un OrderItem par commande
        List<OrderItem> items = new List<OrderItem>();
        for (Order o : orders) {
            items.add(new OrderItem(
                OrderId = o.Id,
                PricebookEntryId = pricebookEntryId,
                Quantity = 1,
                UnitPrice = 100
            ));
        }
        insert items;
    }

    @isTest
    static void testBulkCalculMontantTrigger() {
        // Récupérer les commandes à mettre à jour
        List<Order> ordersToUpdate = [SELECT Id, TotalAmount, ShipmentCost__c FROM Order];

        // Mise à jour : ajout de TotalAmount et ShipmentCost__c
        for (Integer i = 0; i < ordersToUpdate.size(); i++) {
            
            ordersToUpdate[i].ShipmentCost__c = 5 + i * 10;
        }

        update ordersToUpdate;

        // Vérification des Montant_Net__c
        List<Order> updatedOrders = [SELECT Id, TotalAmount, ShipmentCost__c, Montant_Net__c FROM Order];
        for (Order o : updatedOrders) {
            Decimal expected = o.TotalAmount - o.ShipmentCost__c;
            System.assertEquals(expected, o.Montant_Net__c, 'Montant_Net__c incorrect pour Order ' + o.Id);
        }
    }
}