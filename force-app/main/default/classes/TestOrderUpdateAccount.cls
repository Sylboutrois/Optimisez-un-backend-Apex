@isTest
private class TestOrderUpdateAccount {
    
    @testSetup
    static void setupTestData() {
        // Utilisation directe du Pricebook standard par son ID
        Pricebook2 standardPriceBook = new Pricebook2(Id = '01sgL0000000sekQAA', IsActive = true);
        update standardPriceBook;

        // Création d'un produit
        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
        insert testProduct;

        // Ajout d'une entrée de prix au Pricebook standard
        PricebookEntry standardEntry = new PricebookEntry(
            Pricebook2Id = standardPriceBook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert standardEntry;
        
        // Création d'un compte de test
        Account testAccount = new Account(Name = 'Test Account', Chiffre_d_affaire__c = 1000);
        insert testAccount;

        // Création des commandes associées au compte en utilisant le Pricebook standard
        List<Order> orders = new List<Order>{
            new Order(Name = 'Order1', Status = 'Draft', AccountId = testAccount.Id, Pricebook2Id = standardPriceBook.Id, EffectiveDate = System.today()),
            new Order(Name = 'Order2', Status = 'Draft', AccountId = testAccount.Id, Pricebook2Id = standardPriceBook.Id, EffectiveDate = System.today())
        };
        insert orders;

        // Ajout d'OrderItems aux commandes
        List<OrderItem> orderItems = new List<OrderItem>{
            new OrderItem(OrderId = orders[0].Id, PricebookEntryId = standardEntry.Id, Quantity = 5, UnitPrice = 100),
            new OrderItem(OrderId = orders[1].Id, PricebookEntryId = standardEntry.Id, Quantity = 7, UnitPrice = 100)
        };
        insert orderItems;
    }

   
    @isTest
    static void testOrderStatusChangeToOrdered() {
        // Récupérer les commandes et changer leur statut en Ordere
        List<Order> orders = [SELECT Id, Status, AccountId, TotalAmount FROM Order WHERE Name IN ('Order1', 'Order2')];

        for (Order o : orders) {
            o.Status = 'Ordered';
        }
        update orders;
}

    @isTest
   
    static void testTriggerDoesNotRunForSameStatus() {
        // Récupération de l'account avant la modification
        Account initialAccount = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Name = 'Test Account' LIMIT 1];

        // Récupération des commandes
        List<Order> orders = [SELECT Id, Status, AccountId, TotalAmount FROM Order WHERE Name = 'Order1'];

        // Mise à jour de la commande sans changer le statut
        Order testOrder = orders[0];
        update testOrder; 

        // Vérification après mise à jour
        Account updatedAccount = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id = :initialAccount.Id];

        // Vérifier que le chiffre d'affaires : reste inchangé
        System.assertEquals(initialAccount.Chiffre_d_affaire__c, updatedAccount.Chiffre_d_affaire__c, 
            'Le chiffre d\'affaires ne devrait pas être mis à jour.');
    }
@isTest
    static void testBulkTriggerWith150Orders() {
        // Récupération des données de test
        Account acc = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE Id = '01sgL0000000sekQAA' LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pb.Id LIMIT 1];

        // Création de 150 commandes
        List<Order> orders = new List<Order>();
        for (Integer i = 1; i <= 150; i++) {
            orders.add(new Order(
                Name = 'BulkOrder_' + i,
                Status = 'Draft',
                AccountId = acc.Id,
                Pricebook2Id = pb.Id,
                EffectiveDate = System.today()
            ));
        }
        insert orders;

        // Création d’un OrderItem pour chaque commande
        List<OrderItem> items = new List<OrderItem>();
        for (Order o : orders) {
            items.add(new OrderItem(
                OrderId = o.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 1,
                UnitPrice = 100
            ));
        }
        insert items;

        orders = [SELECT Id, Status, TotalAmount FROM Order WHERE Id IN :orders];

        Decimal expectedNewRevenue = 0;
        for (Order o : orders) {
            expectedNewRevenue += o.TotalAmount;
            o.Status = 'Ordered';
        }

        update orders;

        Account updatedAcc = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :acc.Id];
        Decimal expectedTotal = 1000 + expectedNewRevenue;

        System.assertEquals(expectedTotal, updatedAcc.Chiffre_d_affaire__c,
            'Le chiffre d\'affaires du compte est incorrect après traitement de 150 commandes.');
    }
}