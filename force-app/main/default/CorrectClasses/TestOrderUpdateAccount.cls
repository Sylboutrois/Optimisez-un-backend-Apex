@isTest
private class TestOrderUpdateAccount {
    
    @testSetup
    static void setupTestData() {
        // Utilisation directe du Pricebook standard par son ID
        Pricebook2 standardPriceBook = new Pricebook2(Id = '01sgL0000000sekQAA', IsActive = true);
        update standardPriceBook; // Activation si nécessaire

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
        // Récupérer les commandes et changer leur statut en "Ordered"
        List<Order> orders = [SELECT Id, Status, AccountId, TotalAmount FROM Order WHERE Name IN ('Order1', 'Order2')];

        for (Order o : orders) {
            o.Status = 'Ordered';
        }
        update orders;

        // Vérification après mise à jour
        Account updatedAccount = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Name = 'Test Account' LIMIT 1];

        // Vérifier que la valeur a bien été mise à jour
        System.assertEquals(2200, updatedAccount.Chiffre_d_affaire__c, 
            'Le chiffre d\'affaires n\'a pas été correctement mis à jour.');
    }

    @isTest
    static void testTriggerDoesNotRunForSameStatus() {
        // Récupération de l'account avant la modification
        Account initialAccount = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Name = 'Test Account' LIMIT 1];

        // Récupération des commandes
        List<Order> orders = [SELECT Id, Status, AccountId, TotalAmount FROM Order WHERE Name = 'Order1'];

        // Mise à jour de la commande sans changer le statut
        Order testOrder = orders[0];
        update testOrder; // Pas de changement sur le statut

        // Vérification après mise à jour
        Account updatedAccount = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id = :initialAccount.Id];

        // Vérifier que le chiffre d'affaires **reste inchangé**
        System.assertEquals(initialAccount.Chiffre_d_affaire__c, updatedAccount.Chiffre_d_affaire__c, 
            'Le chiffre d\'affaires ne devrait pas être mis à jour.');
    }
}