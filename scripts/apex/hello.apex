GithubBranchCreator branchCreator = new GithubBranchCreator();
GitHubBranchCreationResponse response = branchCreator.createBranch(
  'test-branch'
);
System.debug(response);
