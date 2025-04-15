public class MyTeamOrdersController {
    
    private List<Order> orders;

    // Méthode principale pour récupérer les commandes avec statut 'Ordered'
    public List<Order> getOrders() {
        if (orders == null) {
            orders = [
                SELECT Id, Name, Account.Name, Status, NetAmount__c, OrderNumber, CreatedDate, Commande_prise_par__c
                FROM Order
                WHERE Status = 'Ordered'
                ORDER BY CreatedDate DESC
            ];
        }
        return orders;
    }
    public Decimal getSumOrders() {
        Decimal total = 0;
        for (Order o : getOrders()) {
            if (o.NetAmount__c != null) {
                total += o.NetAmount__c;
            }
        }
        return total;
    }
}