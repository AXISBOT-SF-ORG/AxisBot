public with sharing class RagLambdaProxy {
    @AuraEnabled(cacheable=true)
    public static String askRag(String payload){
        HttpRequest req=new HttpRequest();
        req.setEndpoint('callout:AWS_RAG_Lambda');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(payload);
        Http http=new Http();
        HttpResponse res=http.send(req);
        

        return res.getBody();
    }
}