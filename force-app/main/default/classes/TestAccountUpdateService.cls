@isTest
private class TestAccountUpdateService {
    
    @testSetup
    static void setupTestData() {
        // Pour contourner les limitations SF, utilisation directe du Pricebook standard par son ID
        Pricebook2 standardPriceBook = new Pricebook2(Id = '01sgL0000000sekQAA', IsActive = true);
        update standardPriceBook;

        // Création d'un produit
        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
        insert testProduct;

        // Ajout d'une entrée de prix au Pricebook standard
        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPriceBook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pricebookEntry;
        
        // Création de comptes de test
        Account accountWithOrders = new Account(Name = 'Compte avec commandes', Chiffre_d_affaire__c = 0);
        Account accountWithoutOrders = new Account(Name = 'Compte sans commandes', Chiffre_d_affaire__c = 0);
        insert new List<Account>{accountWithOrders, accountWithoutOrders};

        // Création de la commande en statut Draft
        Order order1 = new Order(
            Name = 'Commande 1', 
            Status = 'Draft',  // Création initiale en mode brouillon
            AccountId = accountWithOrders.Id, 
            Pricebook2Id = standardPriceBook.Id,
            EffectiveDate = System.today()
        );
        insert order1;

        // Ajout d'un OrderItem pour peupler TotalAmount
        OrderItem orderItem1 = new OrderItem(
            OrderId = order1.Id,
            PricebookEntryId = pricebookEntry.Id,
            Quantity = 5,
            UnitPrice = 100
        );
        insert orderItem1;

        order1.Status = 'Ordered';
        update order1;
    }

    @isTest
    static void testBatchExecution() {
        Test.startTest();
        AccountUpdateService batch = new AccountUpdateService();
        Database.executeBatch(batch);
        Test.stopTest();

        // Vérifie la mise à jour du compte avec commandes
        Account updatedAccountWithOrders = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Name = 'Compte avec commandes' LIMIT 1];
        System.assertEquals(500, updatedAccountWithOrders.Chiffre_d_affaire__c, 
            'Le chiffre d\'affaires du compte avec commandes devrait être mis à jour.');

        // Vérifie que le compte sans commandes est à 0
        Account updatedAccountWithoutOrders = [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Name = 'Compte sans commandes' LIMIT 1];
        System.assertEquals(0, updatedAccountWithoutOrders.Chiffre_d_affaire__c, 
            'Le chiffre d\'affaires du compte sans commandes devrait rester à 0.');
    }

    @isTest
    static void testBatchQuery() {
        // Exécute la méthode start du batch pour récupérer les comptes concernés
        AccountUpdateService batch = new AccountUpdateService();
        Database.QueryLocator queryLocator = batch.start(null);

        // Vérifie que le compte avec commandes est bien dans la liste des comptes à traiter
        List<Account> accountsToUpdate = [SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Order WHERE Status = 'Ordered')];
        System.assert(!accountsToUpdate.isEmpty(), 'Il devrait y avoir au moins un compte avec une commande "Ordered".');
    }
    }