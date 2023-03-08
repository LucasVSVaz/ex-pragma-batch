global with sharing class SummarizeForecastBatch implements Database.Batchable<sObject>, Database.Stateful {

    private AccountInfo accountInfo = null;

    public Database.QueryLocator start(Database.BatchableContext context) {

        String query = 'SELECT Id FROM Account';

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext context, List<Account> scope){

        List<AggregateResult> aggregateResultByAccountList = [
            SELECT Account__c, SUM(Value__c) Value
            FROM Forecast__c
            WHERE Account__c IN:scope
            GROUP BY Account__c
        ];

        List<AggregateResult> aggregateResultByAccountProductList = [
            SELECT Account__c, Product__c, SUM(Value__c) Value
            FROM Forecast__c
            WHERE Account__c IN:scope
            GROUP BY Account__c, Product__c
        ];

        List<ForecastSummary__c> forecastSummaryList = new List<ForecastSummary__c>();

        
        for(AggregateResult accountResult : aggregateResultByAccountList){
            Decimal totalValue = (Decimal)accountResult.get('value');

            forecastSummaryList.add(new ForecastSummary__c(
                Key__c = (String)accountResult.get('Account__c'),
                Value__c = totalValue
            ));

            if(this.accountInfo == null || totalValue > this.accountInfo.Value){
                this.accountInfo = new AccountInfo(
                    (String)accountResult.get('Account__c'),
                    totalValue
                );
            }
        }

        for(AggregateResult accountProductResult : aggregateResultByAccountProductList){
            forecastSummaryList.add(new ForecastSummary__c(
                Key__c = (String)accountProductResult.get('Account__c') + '' + (String)accountProductResult.get('Product__c'),
                Value__c = (Decimal)accountProductResult.get('value')
            ));
        }

        upsert forecastSummaryList Key__c;
    }

    public void finish(Database.BatchableContext bc){

        Account account = [
            SELECT Id, Name
            FROM Account
            WHERE Id =:this.accountInfo.AccountId
        ];

        ForecastEmailNotification__c ForecastEmailSettings = ForecastEmailNotification__c.getValues('ForecastAccountProduct'); 
        

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{ForecastEmailSettings.ToAddress__c});
        mail.setSubject(ForecastEmailSettings.Subject__c);

        String body = String.format('{0}. Account {1} had a total forecast of {2}',
        new List<Object>{ForecastEmailSettings.Body__c, account.Name, this.accountInfo.Value});

        mail.setPlainTextBody(body);

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
        
    }

    public class AccountInfo{
        public Id AccountId {get;set;}
        public Decimal Value {get;set;}

        public AccountInfo(Id AccountId, Decimal Value) {
            this.AccountId = AccountId;
            this.Value = Value;
        }
    }

}