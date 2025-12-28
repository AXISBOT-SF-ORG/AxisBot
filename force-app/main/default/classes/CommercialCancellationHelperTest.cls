@isTest
private class CommercialCancellationHelperTest {
  @TestSetup
  static void setupTestData() {
    // Create an active test Pricebook
    Pricebook2 testPricebook = new Pricebook2(
      Name = 'Test Pricebook',
      IsActive = true
    );
    insert testPricebook;

    // Set the test Pricebook ID in the helper class for test context
    CommercialCancellationHelper.testPricebookId = testPricebook.Id;

    Account acc = new Account(Name = 'Test Account');
    insert acc;
    Product2 prod1 = new Product2(
      Name = 'Test Product 1',
      Family = 'Software',
      IsActive = true
    );
    insert prod1;
    Product2 prod2 = new Product2(
      Name = 'Test Product 2',
      Family = 'Software',
      IsActive = true
    );
    insert prod2;

    // IMPORTANT: Must create PricebookEntry in Standard Pricebook first
    // Salesforce requires Standard Pricebook entries before custom Pricebook entries
    Id standardPricebookId = Test.getStandardPricebookId();
    PricebookEntry standardPbe1 = new PricebookEntry(
      Pricebook2Id = standardPricebookId,
      Product2Id = prod1.Id,
      UnitPrice = 1000,
      IsActive = true
    );
    insert standardPbe1;
    PricebookEntry standardPbe2 = new PricebookEntry(
      Pricebook2Id = standardPricebookId,
      Product2Id = prod2.Id,
      UnitPrice = 1000,
      IsActive = true
    );
    insert standardPbe2;

    // Now create PricebookEntry records in the test Pricebook
    PricebookEntry pbe1 = new PricebookEntry(
      Pricebook2Id = testPricebook.Id,
      Product2Id = prod1.Id,
      UnitPrice = 1000,
      IsActive = true
    );
    insert pbe1;
    PricebookEntry pbe2 = new PricebookEntry(
      Pricebook2Id = testPricebook.Id,
      Product2Id = prod2.Id,
      UnitPrice = 1000,
      IsActive = true
    );
    insert pbe2;
    Opportunity opp = new Opportunity(
      Name = 'Test Opportunity',
      AccountId = acc.Id,
      StageName = 'Closed Won',
      CloseDate = Date.today(),
      Type = 'New Customer',
      Pricebook2Id = testPricebook.Id
    );
    insert opp;
    Quote q = new Quote(
      OpportunityId = opp.Id,
      Name = 'Test Quote',
      Status = 'Draft',
      Order_Type__c = 'Sale',
      pricebook2id = testPricebook.Id
    );
    insert q;
    List<QuoteLineItem> qlis = new List<QuoteLineItem>();
    QuoteLineItem qli1 = new QuoteLineItem(
      QuoteId = q.Id,
      OLI_Status__c = 'In Progress',
      Product2Id = prod1.Id,
      Quantity = 1,
      UnitPrice = 1000,
      pricebookentryid = pbe1.Id
    );
    qlis.add(qli1);
    QuoteLineItem qli2 = new QuoteLineItem(
      QuoteId = q.Id,
      OLI_Status__c = 'In Progress',
      Product2Id = prod2.Id,
      pricebookentryid = pbe2.Id,
      Quantity = 1,
      UnitPrice = 1000
    );
    qlis.add(qli2);
    insert qlis;
    Quote acceptedQuote = new Quote(Id = q.Id, Status = 'Accepted');
    update acceptedQuote;
    List<Asset> assets = [
      SELECT Id, Product2Id, Quantity, Price
      FROM Asset
      WHERE Quote_Line_Item__c IN :qlis
    ];
    if (!assets.isEmpty()) {
      System.debug('assets: ' + assets);
    }
    Asset asset1 = new Asset(
      Name = 'Test Asset 1',
      AccountId = acc.Id,
      Product2Id = prod1.Id,
      Status = 'Installed',
      Quantity = 1,
      Quote_Line_Item__c = qlis[0].Id,
      Price = 1000
    );
    insert asset1;
    Asset asset2 = new Asset(
      Name = 'Test Asset 2',
      AccountId = acc.Id,
      Product2Id = prod2.Id,
      Status = 'Installed',
      Quantity = 1,
      Quote_Line_Item__c = qlis[1].Id,
      Price = 1000
    );
    insert asset2;
  }

  @isTest
  static void testProcessCancellation_Success() {
    // Query the test Pricebook and set it in the helper
    Pricebook2 testPricebook = [
      SELECT Id
      FROM Pricebook2
      WHERE Name = 'Test Pricebook'
      LIMIT 1
    ];
    CommercialCancellationHelper.testPricebookId = testPricebook.Id;

    //Query the test Data from TestSetup
    Account acc = [SELECT Id, Name FROM Account LIMIT 1];
    List<Asset> assets = [
      SELECT Id, Product2Id, Quantity, Price
      FROM Asset
      WHERE AccountId = :acc.Id
    ];
    Tuple tuple = assetWrapperHelper(assets);
    Test.startTest();
    Id oppId = CommercialCancellationHelper.processCancellation(
      tuple.assetsSelected,
      acc.Name,
      acc.Id,
      tuple.productIds
    );
    Test.stopTest();

    //Assertions - Verify the Opportunity is created
    Opportunity opp = [
      SELECT Id, Name, StageName, CloseDate, AccountId
      FROM Opportunity
      WHERE Id = :oppId
    ];
    System.assertEquals(
      'Proposal/Price Quote',
      opp.StageName,
      'Opportunity Stage should be Proposal/Price Quote'
    );
  }

  @isTest
  static void testProcessCancellation_PricebookEntryNotFound() {
    //Query the test Data from TestSetup
    Account acc = [SELECT Id, Name FROM Account LIMIT 1];
    List<Asset> assets = [
      SELECT Id, Product2Id, Quantity, Price
      FROM Asset
      WHERE AccountId = :acc.Id
    ];
    Tuple tuple = assetWrapperHelper(assets);
    //Delete the PricebookEntry
    List<PricebookEntry> pbesToDelete = [
      SELECT Id
      FROM PricebookEntry
      WHERE Product2Id IN :tuple.productIds
    ];
    for (PricebookEntry pb : pbesToDelete) {
      pb.IsActive = false;
    }
    update pbesToDelete;
    //Query the test Pricebook and set it in the helper
    Pricebook2 testPricebook = [
      SELECT Id
      FROM Pricebook2
      WHERE Name = 'Test Pricebook'
      LIMIT 1
    ];
    CommercialCancellationHelper.testPricebookId = testPricebook.Id;

    CommercialCancellationException e = null;
    Test.startTest();
    try {
      CommercialCancellationHelper.processCancellation(
        tuple.assetsSelected,
        acc.Name,
        acc.Id,
        tuple.productIds
      );
    } catch (CommercialCancellationException ex) {
      e = ex;
    }
    Test.stopTest();
    //Assertions - Verify the exception is thrown
    System.assert(e != null, 'Exception should be thrown');
    System.assertEquals(
      'No Pricebook Entries found for the products',
      e.getMessage(),
      'Exception message should be No Pricebook Entries found for the products'
    );
  }
  static Tuple assetWrapperHelper(List<Asset> assets) {
    List<CommercialCancellationController.AssetWrapper> assetsSelected = new List<CommercialCancellationController.AssetWrapper>();
    Set<Id> productIds = new Set<Id>();
    for (Asset a : assets) {
      CommercialCancellationController.AssetWrapper aw = new CommercialCancellationController.AssetWrapper(
        a
      );
      //Last day of the month
      aw.selectedDate = Date.newInstance(
        Date.today().year(),
        Date.today().month(),
        Date.daysInMonth(Date.today().year(), Date.today().month())
      );
      productIds.add(a.Product2Id);
      assetsSelected.add(aw);
    }

    return new Tuple(assetsSelected, productIds);
  }

  class Tuple {
    public List<CommercialCancellationController.AssetWrapper> assetsSelected;
    public Set<Id> productIds;
    public Tuple(
      List<CommercialCancellationController.AssetWrapper> assetsSelected,
      Set<Id> productIds
    ) {
      this.assetsSelected = assetsSelected;
      this.productIds = productIds;
    }
  }
}
