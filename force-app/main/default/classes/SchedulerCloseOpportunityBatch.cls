public with sharing class SchedulerCloseOpportunityBatch implements Schedulable{


    public void execute(SchedulableContext ctx) {
        Database.executeBatch(new CloseOpportunityBatch(), 100);
    }
}