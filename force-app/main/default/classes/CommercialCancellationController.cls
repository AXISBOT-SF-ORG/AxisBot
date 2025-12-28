public with sharing class CommercialCancellationController {
  public String pageAlert { get; set; }
  public Boolean showAlert { get; set; }
  public String accId;
  public String accountNumber { get; set; }
  public String accountName;
  public Boolean hasAssets { get; set; }
  public String sortField { get; set; }
  public String sortDirection { get; set; }
  public ApexPages.StandardSetController ssc { get; set; }
  public List<AssetWrapper> wrappedAssets { get; set; }
  public Integer pageSize { get; set; }
  public String operation { get; set; }
  public Date selectedDate { get; set; }
  public CommercialCancellationController() {
    showAlert = false;
    pageAlert = '';
    hasAssets = false;
    pageSize = 10;
    sortField = 'Name';
    sortDirection = 'ASC';
    operation = 'Cancellation';
    selectedDate = Date.today();
    accId = ApexPages.currentPage().getParameters().get('accId');
    if (String.isBlank(accId)) {
      showAlert = true;
      pageAlert = 'AccountId Not Present in the URL';
      return;
    }

    initializeController();
  }

  public void initializeController() {
    String baseQuery =
      'SELECT Id,Name,AccountId,Account.AccountNumber,Account.Name,Product2Id,Product2.Name,Quantity,Price,Status FROM Asset where AccountId=\'' +
      String.escapeSingleQuotes(accId) +
      '\'';
    accountName = [SELECT Name FROM Account WHERE Id = :accId].Name;
    if (operation == 'Cancellation') {
      baseQuery += ' AND Status = \'Installed\' AND (In_flight_Quantity__c = NULL OR In_flight_Quantity__c = 0)';
    }
    if (string.isBlank(sortField))
      sortField = 'Name';
    baseQuery += ' ORDER BY ' + sortField + ' ' + sortDirection;
    try {
      ssc = new ApexPages.StandardSetController(
        Database.getQueryLocator(baseQuery)
      );
      ssc.setPageSize(pageSize);
    } catch (Exception e) {
      showAlert = true;
      pageAlert = 'Error Initializing Controller: ' + e.getMessage();
      wrappedAssets = new List<AssetWrapper>();
      return;
    }

    buildWrappers();
  }

  public void buildWrappers() {
    wrappedAssets = new List<AssetWrapper>();
    List<SObject> recs = ssc.getRecords();

    if (recs == null || recs.isEmpty()) {
      hasAssets = false;
      return;
    }

    for (SObject s : recs) {
      Asset a = (Asset) s;
      accountNumber = a.Account.AccountNumber;
      wrappedAssets.add(new AssetWrapper(a));
    }

    hasAssets = !wrappedAssets.isEmpty();
  }
  public PageReference sortByProduct() {
    return sortBy('Product2.Name');
  }

  public Integer getPageNumber() {
    return ssc == null ? 0 : ssc.getPageNumber();
  }
  public List<SelectOption> getPageOptions() {
    List<SelectOption> options = new List<SelectOption>();
    options.add(new SelectOption('10', '10'));
    options.add(new SelectOption('20', '20'));
    options.add(new SelectOption('50', '50'));

    return options;
  }

  public List<SelectOption> getOperationOptions() {
    List<SelectOption> options = new List<SelectOption>();
    options.add(new SelectOption('Cancellation', 'Cancellation'));
    options.add(new SelectOption('Retraction', 'Retraction'));
    options.add(new SelectOption('RPT', 'Renegotiation of Price and Terms'));
    return options;
  }
  public Integer getTotalPages() {
    return ssc == null
      ? 0
      : ssc.getResultSize() == 0
          ? 1
          : ((Integer) Math.ceil(
              (Decimal) ssc.getResultSize() / (Decimal) ssc.getPageSize()
            ));
  }
  public PageReference sortByAssetName() {
    return sortBy('Name');
  }
  public PageReference submitRecords() {
    List<AssetWrapper> assetsSelected = new List<AssetWrapper>();
    pageAlert = '';
    showAlert = false;
    for (AssetWrapper aw : wrappedAssets) {
      if (aw.checked) {
        assetsSelected.add(aw);
      }
      system.debug('assetsSelected: ' + assetsSelected.size());
    }
    if (assetsSelected.isEmpty()) {
      pageAlert = 'No assets selected. Atleast one asset is required';
      showAlert = true;
      return null;
    }
    if (Operation == 'Cancellation') {
      Set<Id> productIds = new Set<Id>();
      for (AssetWrapper aw : assetsSelected) {
        productIds.add(aw.asset.Product2Id);
        if (
          aw.selectedDate == null ||
          (isSelectedDateValid(aw.selectedDate) == false)
        ) {
          pageAlert = 'Please select the end date for the asset. The end date should be the Last day of the month';
          showAlert = true;
          return null;
        }
      }
      pageAlert = 'Cancellation in Progress';
      showAlert = true;
      //process the cancellation
      try {
        Id opptyId = CommercialCancellationHelper.processCancellation(
          assetsSelected,
          accountName,
          accId,
          productIds
        );

        PageReference pageRef = new PageReference('/' + opptyId);
        pageRef.setRedirect(true);
        return pageRef;
      } catch (Exception e) {
        pageAlert = 'Error processing cancellation: ' + e.getMessage();
        showAlert = true;
        return null;
      }
    } else {
      pageAlert = 'Selected Operation is not supported';
      showAlert = true;
      return null;
    }
  }

  public void clearAlertOnSelection() {
    for (AssetWrapper aw : wrappedAssets) {
      if (aw.checked) {
        showAlert = false;
        pageAlert = '';
        return;
      }
    }
  }

  private Boolean isSelectedDateValid(Date selectedDate) {
    Integer nextDay = selectedDate.addDays(1).day();

    if (nextDay == 1) {
      return true;
    }
    return false;
  }
  // sorting
  public PageReference sortBy(String field) {
    if (sortField == field) {
      sortDirection = sortDirection.equals('ASC') ? 'DESC' : 'ASC';
    } else {
      sortField = field;
      sortDirection = 'ASC';
    }
    initializeController();

    return null;
  }
  public class AssetWrapper {
    public Asset asset { get; set; }
    public Boolean checked { get; set; }
    public Boolean isEdited { get; set; }
    public Date selectedDate { get; set; }
    public AssetWrapper(Asset a) {
      asset = a;
      checked = false;
      isEdited = false;
      selectedDate = Date.today();
    }
  }
}