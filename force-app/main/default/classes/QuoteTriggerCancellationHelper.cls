public class QuoteTriggerCancellationHelper {
  public static void handleCancellation(List<QuoteLineItem> qlis, Quote q) {
    List<Asset> assetsToBeCreated = new List<Asset>();
    List<Asset> assetsToBeDeleted = new List<Asset>();
    List<QuoteLineItem> qlisToBeUpdated = new List<QuoteLineItem>();
    for (QuoteLineItem qli : qlis) {
      if (
        qli.cancelled_lineitem__c &&
        qli.Asset__c != null &&
        qli.Service_End_Date__c != null
      ) {
        if (qli.CreatedAsset__c == false) {
          Asset newAsset = new Asset();
          //Delete existing asset
          assetsToBeDeleted.add(new Asset(Id = qli.Asset__c));
          newAsset.Product2Id = qli.Product2Id;
          newAsset.Quote_Line_Item__c = qli.Id;
          newAsset.AccountId = q.AccountId;
          newAsset.Status = 'Cancelled';
          newAsset.Quantity = qli.Quantity;
          newAsset.Price = qli.UnitPrice * (qli.Quantity);
          newAsset.Name = 'ASS-' + qli.Id.toString();
          newAsset.Service_End_Date__c = qli.Service_End_Date__c;
          assetsToBeCreated.add(newAsset);

          qlisToBeUpdated.add(
            new QuoteLineItem(
              Id = qli.Id,
              CreatedAsset__c = true,
              OLI_Status__c = 'Complete'
            )
          );
        }
      } else {
        if (qli.createdasset__c == false) {
          if (qli.Asset__c == null) {
            qli.OLI_Status__c = 'Entitlement Processing Error';
            qli.Error_Description__c = 'Asset is not linked to the quote line item';
            qlisToBeUpdated.add(qli);
            continue;
          }
          if (qli.Service_End_Date__c == null) {
            qli.OLI_Status__c = 'Entitlement Processing Error';
            qli.Error_Description__c = 'Service end date is not set';
            qlisToBeUpdated.add(qli);
            continue;
          }
        }
      }
    }
    try {
      if (!assetsToBeDeleted.isEmpty()) {
        delete assetsToBeDeleted;
      }
      if (!assetsToBeCreated.isEmpty()) {
        insert assetsToBeCreated;
      }
      if (!qlisToBeUpdated.isEmpty()) {
        update qlisToBeUpdated;
      }
    } catch (Exception e) {
      System.debug('Error processing cancellation: ' + e.getMessage());
      throw new QuoteTriggerCancellationHelper.QuoteTriggerCancellationException(
        e.getMessage()
      );
    }
  }
  public class QuoteTriggerCancellationException extends Exception {
  }
}
