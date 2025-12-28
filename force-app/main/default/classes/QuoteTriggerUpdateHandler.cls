public without sharing class QuoteTriggerUpdateHandler {
  public static void handleAfterUpdate(
    Map<Id, Quote> newMap,
    Map<Id, Quote> oldMap
  ) {
    System.debug('In After Update Trigger new Items: ' + newMap.keySet());
    System.debug('In After Update Trigger old Items: ' + oldMap.keySet());
    // Map<Id,Opportunity> allOpptys=new Map<Id,Opportunity>();
    List<String> opptyIds = new List<String>();
    List<String> quoteIds = new List<String>();
    List<Opportunity> oppsToBeUpdated = new List<Opportunity>();
    Map<Id, List<QuoteLineItem>> qlisMap = new Map<Id, List<QuoteLineItem>>();
    List<Asset> assetsToBeCreated = new List<Asset>();
    for (Quote q : newMap.values()) {
      opptyIds.add(q.OpportunityId);
      quoteIds.add(q.Id);
    }
    List<QuoteLineItem> qlis = [
      SELECT
        Id,
        Product2Id,
        TotalPrice,
        Quantity,
        QuoteId,
        Cancelled_LineItem__c,
        Asset__c,
        UnitPrice,
        Service_End_Date__c,
        OLI_Status__c,
        Error_Description__c,
        CreatedAsset__c
      FROM QuoteLineItem
      WHERE QuoteId IN :quoteIds
    ];
    for (QuoteLineItem qli : qlis) {
      if (!qlisMap.containsKey(qli.QuoteId)) {
        qlisMap.put(qli.QuoteId, new List<QuoteLineItem>());
      }
      qlisMap.get(qli.QuoteId).add(qli);
    }
    for (Quote q : newMap.values()) {
      Quote qOld = oldMap.get(q.Id);
      if (q.Status == 'Accepted' && qOld.Status != 'Accepted') {
        // for (QuoteLineItem qli : qlisMap.get(q.Id)) {
        //   Asset a = new Asset(
        //     Product2Id = qli.Product2Id,
        //     AccountId = q.AccountId,
        //     Status = 'Installed',
        //     Quantity = qli.Quantity,
        //     Quote_Line_Item__c = qli.Id,
        //     Price = qli.TotalPrice,
        //     Name = 'ASS-' + qli.Id.toString()
        //   );
        //   assetsToBeCreated.add(a);
        // }

        if (q.order_type__c == 'Cancellation') {
          List<QuoteLineItem> qlisToBeCancelled = qlisMap.get(q.Id);
          QuoteTriggerCancellationHelper.handleCancellation(
            qlisToBeCancelled,
            q
          );
        }

        if (q.order_type__c == 'Sale') {
          List<QuoteLineItem> qlisToBeSold = qlisMap.get(q.Id);
          QuoteTriggerSaleHelper.handleSale(q, qlisToBeSold);
        }

        if (q.OpportunityId != null) {
          Opportunity op = new Opportunity(
            Id = q.OpportunityId,
            StageName = 'Closed Won',
            CloseDate = Date.today()
          );
          oppsToBeUpdated.add(op);
        }
      }
    }

    if (!oppsToBeUpdated.isEmpty()) {
      update oppsToBeUpdated;
    }

    if (!assetsToBeCreated.isEmpty()) {
      insert assetsToBeCreated;
    }
  }
}
