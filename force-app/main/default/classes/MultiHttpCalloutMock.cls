@isTest
public class MultiHttpCalloutMock implements HttpCalloutMock {
  // Store responses for different requests
  private Map<String, HttpResponse> responseMap = new Map<String, HttpResponse>();
  private List<HttpResponse> sequentialResponses = new List<HttpResponse>();
  private Integer callCount = 0;
  private Boolean useSequentialMode = false;

  // Constructor for sequential responses (returns responses in order)
  public MultiHttpCalloutMock(List<HttpResponse> responses) {
    this.sequentialResponses = responses;
    this.useSequentialMode = true;
  }

  // Constructor for request-based responses (returns response based on request details)
  public MultiHttpCalloutMock() {
    this.useSequentialMode = false;
  }

  // Add a response for a specific request pattern
  public void addResponse(
    String method,
    String endpointPattern,
    HttpResponse response
  ) {
    String key = method + ':' + endpointPattern;
    responseMap.put(key, response);
  }

  public HttpResponse respond(HttpRequest request) {
    HttpResponse response;

    if (useSequentialMode) {
      // Return responses in order (first call gets first response, second call gets second, etc.)
      if (callCount < sequentialResponses.size()) {
        response = sequentialResponses[callCount];
        callCount++;
      } else {
        // If more callouts than responses, return the last response
        response = sequentialResponses[sequentialResponses.size() - 1];
      }
    } else {
      // Return response based on request method and endpoint
      String method = request.getMethod();
      String endpoint = request.getEndpoint();

      // Try to find matching response
      for (String key : responseMap.keySet()) {
        String[] parts = key.split(':');
        String keyMethod = parts[0];
        String endpointPattern = parts.size() > 1 ? parts[1] : '';

        if (keyMethod.equals(method) && endpoint.contains(endpointPattern)) {
          response = responseMap.get(key);
          break;
        }
      }

      // If no match found, return a default error response
      if (response == null) {
        response = new HttpResponse();
        response.setStatusCode(500);
        response.setStatus(
          'No mock response configured for: ' + method + ' ' + endpoint
        );
        response.setBody('{"error": "No mock response found"}');
      }
    }

    return response;
  }
}
