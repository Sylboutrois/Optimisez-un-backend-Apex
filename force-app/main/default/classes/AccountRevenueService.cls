public class AccountRevenueService {

    // Cette méthode met à jour le chiffre d'affaires des comptes
    // en fonction des commandes passées au statut "Ordered"
    public static void updateRevenueFromOrders(List<Order> newOrders, List<Order> oldOrders) {
        Set<Id> accountIds = new Set<Id>(); // Pour stocker les comptes à mettre à jour
        Map<Id, Decimal> accountRevenueMap = new Map<Id, Decimal>(); // Stocke les nouveaux chiffres d'affaires par compte

        // On identifie les comptes liés aux commandes dont le statut vient de passer à "Ordered"
        for (Integer i = 0; i < newOrders.size(); i++) {
            Order newOrder = newOrders[i];
            Order oldOrder = oldOrders[i];

            // Si la commande est passée à "Ordered" et a un compte associé
            if (newOrder.Status == 'Ordered' && oldOrder.Status != 'Ordered' && newOrder.AccountId != null) {
                accountIds.add(newOrder.AccountId); // On garde l'ID du compte à traiter
            }
        }

        // Si on a des comptes à mettre à jour
        if (!accountIds.isEmpty()) {
            // On récupère les comptes et leur chiffre d'affaires actuel
            Map<Id, Account> accountMap = new Map<Id, Account>(
                [SELECT Id, Chiffre_d_affaire__c FROM Account WHERE Id IN :accountIds]
            );

            // Pour chaque commande, on ajoute son montant au chiffre d'affaires du compte
            for (Integer i = 0; i < newOrders.size(); i++) {
                Order newOrder = newOrders[i];
                Order oldOrder = oldOrders[i];

                // On vérifie à nouveau les conditions (transition vers "Ordered", compte non nul)
                if (newOrder.Status == 'Ordered' && oldOrder.Status != 'Ordered' && newOrder.AccountId != null) {
                    Id accId = newOrder.AccountId;

                    if (accountMap.containsKey(accId)) {
                        // Valeur actuelle du chiffre d'affaires, ou 0 si null
                        Decimal currentCA = accountMap.get(accId).Chiffre_d_affaire__c != null 
                            ? accountMap.get(accId).Chiffre_d_affaire__c 
                            : 0;

                        // Montant de la commande (0 si null pour éviter les erreurs)
                        Decimal orderAmount = newOrder.TotalAmount != null 
                            ? newOrder.TotalAmount 
                            : 0;

                        // Si on a déjà cumulé des commandes pour ce compte, on les additionne
                        Decimal cumulative = accountRevenueMap.containsKey(accId)
                            ? accountRevenueMap.get(accId)
                            : currentCA;

                        // Mise à jour du total cumulé
                        accountRevenueMap.put(accId, cumulative + orderAmount);
                    }
                }
            }

            // Préparation des enregistrements Account à mettre à jour
            List<Account> accountsToUpdate = new List<Account>();
            for (Id accId : accountRevenueMap.keySet()) {
                accountsToUpdate.add(new Account(
                    Id = accId,
                    Chiffre_d_affaire__c = accountRevenueMap.get(accId)
                ));
            }

            // Mise à jour effective des comptes si nécessaire
            if (!accountsToUpdate.isEmpty()) {
                update accountsToUpdate;
            }
        }
    }
}