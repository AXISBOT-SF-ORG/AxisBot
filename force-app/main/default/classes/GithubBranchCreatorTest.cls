@isTest
private class GithubBranchCreatorTest {
  @TestSetup
  static void makeData() {
    Release__c release = new Release__c(
      Name = 'Test Release',
      Release_Date__c = Date.today(),
      Status__c = 'Open'
    );
    insert release;
    Project__c project = new Project__c(Name = 'Test Project');
    insert project;
  }
  @isTest
  static void testCreateBranch_Success() {
    Project__c project = [SELECT Id FROM Project__c LIMIT 1];
    Release__c release = [SELECT Id FROM Release__c LIMIT 1];

    HttpResponse getResponse = new HttpResponse();
    getResponse.setStatusCode(200);
    getResponse.setStatus('OK');
    getResponse.setBody('{"commit":{"sha":"abc123def456"}}');

    HttpResponse postResponse = new HttpResponse();
    postResponse.setStatusCode(201);
    postResponse.setStatus('OK');
    postResponse.setBody('{"object":{"sha":"abc123def565456"}}');

    MultiHttpCalloutMock multiHttpCalloutMock = new MultiHttpCalloutMock(
      new List<HttpResponse>{ getResponse, postResponse }
    );

    Test.setMock(HttpCalloutMock.class, multiHttpCalloutMock);

    User_Story__c newStory = new User_Story__c(
      Name__c = 'Test Story For Branch Creation',
      FeatureBranchCreated__c = false, // This triggers the handler
      Status__c = 'Open',
      Developer__c = UserInfo.getUserId(),
      Release__c = release.Id,
      Project__c = project.Id
    );

    Test.startTest();
    insert newStory;
    Test.stopTest();

    User_Story__c updatedStory = [
      SELECT
        Id,
        FeatureBranchCreated__c,
        Github_Branch__c,
        Github_Branch_Creation_Error__c,
        Github_Branch_SHA__c
      FROM User_Story__c
      WHERE Id = :newStory.Id
      LIMIT 1
    ];
    System.assertEquals(true, updatedStory.FeatureBranchCreated__c);
    // System.assertEquals('https://github.com/test-org/test-repo/tree/feature/Test Story For Branch Creation', updatedStory.Github_Branch__c);
    System.assertEquals('abc123def565456', updatedStory.Github_Branch_SHA__c);
    System.assertEquals(null, updatedStory.Github_Branch_Creation_Error__c);
  }
  @isTest
  static void testCreateBranch_getBaseBranchSHA_failure() {
    Project__c project = [SELECT Id FROM Project__c LIMIT 1];
    Release__c release = [SELECT Id FROM Release__c LIMIT 1];

    HttpResponse getResponse = new HttpResponse();
    getResponse.setStatusCode(404);
    getResponse.setStatus('Not Found');
    getResponse.setBody('{"message":"Not Found"}');

    MultiHttpCalloutMock multiHttpCalloutMock = new MultiHttpCalloutMock(
      new List<HttpResponse>{ getResponse }
    );
    Test.setMock(HttpCalloutMock.class, multiHttpCalloutMock);
    User_Story__c newStory = new User_Story__c(
      Name__c = 'Test Story For Branch Creation',
      FeatureBranchCreated__c = false, // This triggers the handler
      Status__c = 'Open',
      Developer__c = UserInfo.getUserId(),
      Release__c = release.Id,
      Project__c = project.Id
    );
    Test.startTest();
    insert newStory;
    Test.stopTest();

    User_Story__c updatedStory = [
      SELECT
        Id,
        FeatureBranchCreated__c,
        Github_Branch__c,
        Github_Branch_Creation_Error__c,
        Github_Branch_SHA__c
      FROM User_Story__c
      WHERE Id = :newStory.Id
      LIMIT 1
    ];
    System.assertEquals(false, updatedStory.FeatureBranchCreated__c);
    System.assertEquals(null, updatedStory.Github_Branch__c);
    System.assertEquals(null, updatedStory.Github_Branch_SHA__c);
    System.assertEquals(
      'Error: Not Found',
      updatedStory.Github_Branch_Creation_Error__c
    );
  }
}
