public class UserstoryAfterInsertHandler {
  public static void handleAfterInsert(List<User_Story__c> newList) {
    List<User_Story__c> githubBranchesToBeCreated = new List<User_Story__c>();
    for (User_Story__c us : newList) {
      if (us.FeatureBranchCreated__c == false) {
        githubBranchesToBeCreated.add(us);
      }
    }
    if (!githubBranchesToBeCreated.isEmpty()) {
      for (User_Story__c us : githubBranchesToBeCreated) {
        GithubBranchCreator.createBranchFuture('feature/' + us.Name, us.Id);
      }
    }
  }
}
