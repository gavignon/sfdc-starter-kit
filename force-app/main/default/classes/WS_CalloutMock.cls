/**
* @author Gil Avignon
* @date 27/07/2018
* @description Callout Mock Factory Class that create the Mock for callouts
* @group Web Service
*/
@IsTest
global class WS_CalloutMock implements HttpCalloutMock {

    private Integer statusCode;
    private String body;
    private Boolean generateException;
    private String exceptionType;
    private String exceptionMessage;

    public WS_CalloutMock(Integer status, String bodyString){
        this.statusCode = status;
        this.body = bodyString;
        this.generateException = false;
    }

    public WS_CalloutMock(String pExceptionType, String pExceptionMessage){
        this.generateException = true;
        this.exceptionType = pExceptionType;
        this.exceptionMessage = pExceptionMessage;
    }

    global HttpResponse respond(HttpRequest req) {

        if(this.generateException){
            switch on exceptionType {
                when 'CalloutException' {
                    CalloutException e = (CalloutException)CalloutException.class.newInstance();
                    e.setMessage(this.exceptionMessage);
                    throw e;
                }
                when else {
                    Exception e = (Exception)Exception.class.newInstance();
                    e.setMessage(this.exceptionMessage);
                    throw e;
                }
            }
        }

        HttpResponse resp = new HttpResponse();

        resp.setStatusCode(this.statusCode);
        resp.setBody(this.body);

        return resp;
    }
}
