global with sharing class CloseOpportunityBatch implements Database.Batchable<sObject>{
    
    
     global Database.QueryLocator start(Database.BatchableContext bc) {

        Datetime baseDate = Date.today().addDays(-15);

        String query = 'SELECT Id FROM Opportunity WHERE StageName IN(\'Prospecting\', \'Qualification\') AND CreatedDate <=:baseDate';

        return Database.getQueryLocator(query);
     }


      global void execute(Database.BatchableContext bc, List<Opportunity> scope){

        for(Opportunity opp : scope){
            opp.StageName = 'Closed Lost';
            opp.Description = Label.ClosedOpportunityDescription;
        }

        update scope;
      }

      public void finish(Database.BatchableContext bc){}

}