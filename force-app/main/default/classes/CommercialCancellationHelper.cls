public class CommercialCancellationHelper {
  public static final String CANCELLATION_STAGE = 'Proposal/Price Quote';
  public static final String PRICEBOOK_ID = label.Genesis_Pricebook;
  // Static variable to store test Pricebook ID for test context
  public static Id testPricebookId;
  public static Id processCancellation(
    List<CommercialCancellationController.AssetWrapper> assetsSelected,
    String accountName,
    String accountId,
    Set<Id> productIds
  ) {
    List<PricebookEntry> pbes;
    if (test.isRunningTest()) {
      Id pricebookIdToUse = testPricebookId != null
        ? testPricebookId
        : Test.getStandardPricebookId();
      pbes = [
        SELECT Id, Product2Id
        FROM PricebookEntry
        WHERE
          Pricebook2Id = :pricebookIdToUse
          AND Product2Id IN :productIds
          AND IsActive = TRUE
      ];
    } else {
      pbes = [
        SELECT Id, Product2Id
        FROM PricebookEntry
        WHERE
          Pricebook2Id = :PRICEBOOK_ID
          AND Product2Id IN :productIds
          AND IsActive = TRUE
      ];
    }
    if (pbes.isEmpty()) {
      throw new CommercialCancellationException(
        'No Pricebook Entries found for the products'
      );
    }
    Map<Id, Id> productIdToPricebookEntryId = new Map<Id, Id>();
    for (PricebookEntry pb : pbes) {
      productIdToPricebookEntryId.put(pb.Product2Id, pb.Id);
    }
    for (Id productId : productIds) {
      if (!productIdToPricebookEntryId.containsKey(productId)) {
        throw new CommercialCancellationException(
          'Pricebook Entry not found for the product: ' + productId
        );
      }
    }
    String opName =
      accountName +
      ' Cancellation ' +
      Datetime.now().format('dd/MM/yyyy HH:mm:ss').toString();
    Opportunity op = new Opportunity(
      Name = opName,
      StageName = CANCELLATION_STAGE,
      CloseDate = Date.today(),
      AccountId = accountId,
      Type = 'Cancellation',
      pricebook2id = test.isRunningTest()
        ? (testPricebookId != null
            ? testPricebookId
            : Test.getStandardPricebookId())
        : PRICEBOOK_ID
    );
    insert op;
    List<Asset> assetsToUpdate = new List<Asset>();
    List<OpportunityLineItem> opItems = new List<OpportunityLineItem>();
    for (CommercialCancellationController.AssetWrapper aw : assetsSelected) {
      assetsToUpdate.add(
        new Asset(
          Id = aw.asset.Id,
          Status = 'In-flight Removal',
          In_flight_Quantity__c = aw.Asset.Quantity
        )
      );
      OpportunityLineItem oi = new OpportunityLineItem(
        OpportunityId = op.Id,
        Product2Id = aw.asset.Product2Id,
        Quantity = aw.asset.Quantity * (-1),
        TotalPrice = aw.asset.Price * (-1),
        Service_End_Date__c = aw.selectedDate,
        PricebookEntryId = productIdToPricebookEntryId.get(aw.asset.Product2Id),
        Asset__c = aw.asset.Id
      );
      opItems.add(oi);
    }

    if (!opItems.isEmpty()) {
      insert opItems;
    }
    if (!assetsToUpdate.isEmpty()) {
      update assetsToUpdate;
    }

    Quote q = new Quote(
      OpportunityId = op.Id,
      Status = 'Draft',
      Name = accountName +
        ' Cancellation Quote ' +
        Datetime.now().format('dd/MM/yyyy HH:mm:ss').toString(),
      Order_Type__c = 'Cancellation',
      pricebook2id = test.isRunningTest()
        ? (testPricebookId != null
            ? testPricebookId
            : Test.getStandardPricebookId())
        : PRICEBOOK_ID
    );
    insert q;
    List<QuoteLineItem> qlis = new List<QuoteLineItem>();
    for (OpportunityLineItem oi : opItems) {
      QuoteLineItem qli = new QuoteLineItem(
        QuoteId = q.Id,
        Product2Id = oi.Product2Id,
        Quantity = oi.Quantity * (-1),
        UnitPrice = (oi.TotalPrice != null &&
          oi.Quantity != null &&
          oi.Quantity != 0)
          ? (oi.TotalPrice / oi.Quantity) * (-1)
          : oi.TotalPrice * (-1),
        pricebookentryid = productIdToPricebookEntryId.get(oi.Product2Id),
        service_end_date__c = oi.Service_End_Date__c,
        Cancelled_LineItem__c = true,
        Asset__c = oi.Asset__c,
        OLI_Status__c = 'In Progress'
      );
      qlis.add(qli);
    }
    if (!qlis.isEmpty()) {
      insert qlis;
    }
    Opportunity opp = new Opportunity(Id = op.Id, SyncedQuoteId = q.Id);
    update opp;
    return opp.Id;
  }
}
