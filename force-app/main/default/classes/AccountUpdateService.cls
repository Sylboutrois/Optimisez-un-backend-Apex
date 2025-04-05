global class AccountUpdateService implements Database.Batchable<sObject>{

   global Database.QueryLocator start(Database.BatchableContext info){ 
       // Sélectionner uniquement les comptes avec au moins une commande "Ordered"
       return Database.getQueryLocator(
           'SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Order WHERE Status = \'Ordered\')'
       );
   }
    
   global void execute(Database.BatchableContext info, List<Account> scope){      
       // Requête pour récupérer les chiffres d'affaires groupés par compte
       Map<Id, Decimal> accountRevenueMap = new Map<Id, Decimal>();
       for (AggregateResult result : [
           SELECT AccountId, SUM(TotalAmount) totalRevenue 
           FROM Order WHERE Status = 'Ordered' 
           GROUP BY AccountId
       ]) {
           accountRevenueMap.put((Id)result.get('AccountId'), (Decimal)result.get('totalRevenue'));
       }
       
       // Mise à jour des comptes avec les valeurs récupérées
    for (Account acc : scope) {
    if (accountRevenueMap.containsKey(acc.Id)) {
        acc.Chiffre_d_affaire__c = accountRevenueMap.get(acc.Id);
    } else {
        acc.Chiffre_d_affaire__c = 0; // Si pas de commandes "Ordered", mettre 0
    }
}
       update scope;
   }    

   global void finish(Database.BatchableContext info){     
       // Envoyer une notification
       System.debug('Batch AccountUpdateService terminé avec succès.');
   } 
}