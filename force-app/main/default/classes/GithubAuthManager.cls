public class GithubAuthManager {
  private Github_Devops_Config__mdt config;
  public GithubAuthManager() {
    config = Github_Devops_Config__mdt.getInstance('Github_Config');
  }

  public String getBranchName() {
    return config.Base_Branch__c;
  }
  public String getGithubBaseUrl() {
    return config.Github_Base_URL__c;
  }
  public Integer getTimeout() {
    return (Integer) config.Request_Timeout__c;
  }

  public String getGithubOwner() {
    return config.Github_Username__c;
  }
  public String getGithubRepo() {
    return config.Github_Repo__c;
  }
  public String getGithubOrgName() {
    return config.Github_Org_Name__c;
  }
  public HttpResponse makeRequest(
    String method,
    String endpoint,
    Boolean protectedEndpoint,
    String body
  ) {
    Http http = new Http();
    HttpRequest req = new HttpRequest();
    req.setMethod(method);
    String githubBaseUrl = getGithubBaseUrl();
    if (protectedEndpoint) {
      req.setHeader('Authorization', 'Bearer ' + config.Access_Token__c);
    }
    if (endpoint.startsWith('/')) {
      req.setEndpoint(githubBaseUrl + endpoint);
    } else {
      req.setEndpoint(endpoint);
    }
    req.setHeader('Content-Type', 'application/json');
    req.setHeader('Accept', 'application/vnd.github.v3+json');

    if (body != null) {
      req.setBody(body);
    }

    req.setTimeout(getTimeout());
    // handle redirects
    HttpResponse response = http.send(req);
    if (
      response.getStatusCode() == 302 ||
      response.getStatusCode() == 301 ||
      response.getStatusCode() == 307 ||
      response.getStatusCode() == 308 &&
      response.getHeader('Location') != null
    ) {
      return makeRequest(
        method,
        response.getHeader('Location'),
        protectedEndpoint,
        body
      );
    }
    return response;
  }
}
