@isTest 
private class Test_MyTeamOrdersController {

    @isTest
    static void testGetOrdersAndSumOrders() {
        // Création du compte
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Création du produit
        Product2 prod = new Product2(Name = 'Produit Test', IsActive = true);
        insert prod;

        // Récupération du Pricebook standard
        Id standardPBId = Test.getStandardPricebookId();

        // Création de l'entrée de pricebook
        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = standardPBId,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        // Création de 2 commandes en statut Draft
        Order ord1 = new Order(
            Name = 'Order1',
            Status = 'Draft',
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Pricebook2Id = standardPBId
        );
        Order ord2 = new Order(
            Name = 'Order2',
            Status = 'Draft',
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Pricebook2Id = standardPBId
        );
        insert new List<Order>{ord1, ord2};

        // Ajout des OrderItem à chaque commande
        OrderItem item1 = new OrderItem(
            OrderId = ord1.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 1000
        );
        OrderItem item2 = new OrderItem(
            OrderId = ord2.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 2000
        );
        insert new List<OrderItem>{item1, item2};

        ord1.Status = 'Ordered';
        ord2.Status = 'Ordered';
        update new List<Order>{ord1, ord2};

        // Test du contrôleur
        Test.startTest();
        MyTeamOrdersController ctrl = new MyTeamOrdersController();
        List<Order> result = ctrl.getOrders();
        Decimal total = ctrl.getSumOrders();
        Test.stopTest();

        // Vérifications
        System.assertEquals(2, result.size(), 'Deux commandes Ordered doivent être retournées.');
        System.assertEquals(3000, total, 'La somme des montants nets doit être 3000.');
    }
}