@isTest
public class SingleHttpCalloutMock implements HttpCalloutMock {
  private Integer statusCode;
  private String status;
  private String body;
  private Map<String, String> responseHeaders;

  public SingleHttpCalloutMock(
    Integer statusCode,
    String status,
    String body,
    Map<String, String> responseHeaders
  ) {
    this.statusCode = statusCode;
    this.status = status;
    this.body = body;
    this.responseHeaders = responseHeaders;
  }

  public HttpResponse respond(HttpRequest request) {
    HttpResponse response = new HttpResponse();
    response.setStatusCode(statusCode);
    response.setStatus(status);
    response.setBody(body);
    if (responseHeaders != null) {
      for (String headerKey : responseHeaders.keySet()) {
        response.setHeader(headerKey, responseHeaders.get(headerKey));
      }
    }
    return response;
  }
}
