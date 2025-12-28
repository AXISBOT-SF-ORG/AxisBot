public class QuoteTriggerSaleHelper {
  public static void handleSale(Quote q, List<QuoteLineItem> qlis) {
    List<Asset> assetsToBeCreated = new List<Asset>();
    for (QuoteLineItem qli : qlis) {
      Asset a = new Asset(
        Product2Id = qli.Product2Id,
        AccountId = q.AccountId,
        Status = 'Installed',
        Quantity = qli.Quantity,
        Quote_Line_Item__c = qli.Id
      );
      assetsToBeCreated.add(a);
    }
    if (!assetsToBeCreated.isEmpty()) {
      insert assetsToBeCreated;
    }
  }
}
