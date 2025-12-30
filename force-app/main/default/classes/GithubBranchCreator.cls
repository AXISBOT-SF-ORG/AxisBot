public class GithubBranchCreator {
  private GithubAuthManager authManager;
  public GithubBranchCreator() {
    authManager = new GithubAuthManager();
  }
  @future(callout=true)
  public static void createBranchFuture(String branchName, String storyId) {
    try {
      GithubBranchCreator githubBranchCreator = new GithubBranchCreator();
      GitHubBranchCreationResponse response = githubBranchCreator.createBranch(
        branchName
      );
      User_Story__c us = [
        SELECT
          Id,
          FeatureBranchCreated__c,
          Github_Branch__c,
          Github_Branch_Creation_Error__c,
          Github_Branch_SHA__c
        FROM User_Story__c
        WHERE Id = :storyId
        LIMIT 1
      ];
      if (response.isSuccess) {
        us.FeatureBranchCreated__c = true;
        us.Github_Branch__c = response.branchUrl;
        us.Github_Branch_Creation_Error__c = null;
        us.Github_Branch_SHA__c = response.branchSHA;
      } else {
        us.FeatureBranchCreated__c = false;
        us.Github_Branch__c = null;
        us.Github_Branch_Creation_Error__c = response.message;
        us.Github_Branch_SHA__c = null;
      }
      Database.DMLOptions options = new Database.DMLOptions();
      options.allowFieldTruncation = true;
      Database.update(us, options);
    } catch (Exception e) {
      System.debug('Error creating branch: ' + e.getMessage());
      User_Story__c us = [
        SELECT
          Id,
          FeatureBranchCreated__c,
          Github_Branch__c,
          Github_Branch_Creation_Error__c,
          Github_Branch_SHA__c
        FROM User_Story__c
        WHERE Id = :storyId
        LIMIT 1
      ];
      us.FeatureBranchCreated__c = false;
      us.Github_Branch__c = null;
      us.Github_Branch_Creation_Error__c = 'Error: ' + e.getMessage();
      us.Github_Branch_SHA__c = null;
      Database.DMLOptions options = new Database.DMLOptions();
      options.allowFieldTruncation = true;
      Database.update(us, options);
    }
  }
  public GitHubBranchCreationResponse createBranch(String branchName) {
    try {
      String baseBranchSHA = getBaseBranchSHA();
      if (baseBranchSHA == null) {
        return new GitHubBranchCreationResponse(
          false,
          'Failed to get base branch SHA'
        );
      }
      String requestBody = JSON.serialize(
        new Map<String, Object>{
          'ref' => 'refs/heads/' + branchName,
          'sha' => baseBranchSHA
        }
      );
      HttpResponse response = authManager.makeRequest(
        'POST',
        '/repos/' +
          authManager.getGithubOwner() +
          '/' +
          authManager.getGithubRepo() +
          '/git/refs',
        true,
        requestBody
      );
      if (response.getStatusCode() == 201) {
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(
          response.getBody()
        );
        String branchUrl =
          'https://github.com/' +
          authManager.getGithubOrgName() +
          '/' +
          authManager.getGithubRepo() +
          '/tree/' +
          branchName;
        return new GitHubBranchCreationResponse(
          true,
          'Branch created successfully',
          branchName,
          result,
          branchUrl
        );
      } else if (response.getStatusCode() == 422) {
        return new GitHubBranchCreationResponse(
          false,
          'Branch already exists or invalid request'
        );
      } else {
        return new GitHubBranchCreationResponse(
          false,
          'Error: ' + response.getStatus()
        );
      }
    } catch (Exception e) {
      System.debug('Error creating branch: ' + e.getMessage());
      return new GitHubBranchCreationResponse(
        false,
        'Error: ' + e.getMessage()
      );
    }
  }

  private String getBaseBranchSHA() {
    String baseBranchName = authManager.getBranchName();
    try {
      HttpResponse response = authManager.makeRequest(
        'GET',
        '/repos/' +
          authManager.getGithubOwner() +
          '/' +
          authManager.getGithubRepo() +
          '/branches/' +
          baseBranchName,
        false,
        null
      );

      if (response.getStatusCode() == 200) {
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(
          response.getBody()
        );
        if (responseBody != null && responseBody.containsKey('commit')) {
          Object commitObj = responseBody.get('commit');
          if (commitObj != null) {
            Object commitMap = commitObj;
            Map<String, Object> commitMapTyped = (Map<String, Object>) commitMap;
            if (commitMapTyped != null && commitMapTyped.containsKey('sha')) {
              Object shaObj = commitMapTyped.get('sha');
              if (shaObj != null) {
                return String.valueOf(shaObj);
              }
            }
          }
        }
      }

      return null;
    } catch (Exception e) {
      System.debug('Error getting branch SHA: ' + e.getMessage());
      return null;
    }
  }

  public class GitHubBranchCreationResponse {
    public Boolean isSuccess;
    public String message;
    public Map<String, Object> data;
    public String branchName;
    public String branchSHA;
    public String branchUrl;

    public GitHubBranchCreationResponse(
      Boolean isSuccess,
      String message,
      String branchName,
      Map<String, Object> data,
      String branchUrl
    ) {
      this.isSuccess = isSuccess;
      this.message = message;
      this.data = data;
      Object obj = data.get('object');
      this.branchName = branchName;
      if (obj != null && obj instanceof Map<String, Object>) {
        Map<String, Object> objMap = (Map<String, Object>) obj;
        if (objMap.containsKey('sha')) {
          Object shaObj = objMap.get('sha');
          if (shaObj != null) {
            this.branchSHA = String.valueOf(shaObj);
          }
        }
      }
      this.branchUrl = branchUrl;
    }

    public GitHubBranchCreationResponse(Boolean isSuccess, String message) {
      this.isSuccess = isSuccess;
      this.message = message;
      this.data = null;
      this.branchSHA = null;
      this.branchName = null;
      this.branchUrl = null;
    }
  }
}
