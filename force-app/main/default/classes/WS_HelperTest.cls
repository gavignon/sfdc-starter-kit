/**
* @author Gil Avignon
* @date 27/07/2018
* @description Test class for WS_Helper
* @group Tests
*/
@isTest
public class WS_HelperTest {
    private static final String FIRSTNAME_TEST = 'Test';
    private static final String LASTNAME_TEST = 'TestUser';
    private static UTIL_TestFactory.UserFactory userFactory = new UTIL_TestFactory.UserFactory();

    @TestSetup static void setup() {
        User u = userFactory.createRunningUserAdministrator();
        insert u;
    }

    @IsTest
    static void callWebServiceMock() {
        User u = [SELECT Id FROM User WHERE LastName = :LASTNAME_TEST LIMIT 1];

        System.runAs(u) {

            Map<String, String> pathParams = new Map<String, String>();
            pathParams.put('{bookingId}', 'CAS01234567');
            Map<String, String> params = new Map<String, String>();
            params.put('shippingCompany', 'CMACGM');


            WS_Helper.testAuthToken = 'TEST.ewoiZXhwIjogMTUzOTEwNTg4NAp9.TEST';
            Test.setMock(HttpCalloutMock.class, new WS_CalloutMock(200, '{"response": "success"}'));

            Test.startTest();
                WS_Helper.testMock = true;
                HttpResponse bkgResponse = WS_Helper.callWebservice('WS_HelperTest', 'callWebService', null, null, pathParams, params, null, null);

            Test.stopTest();
        }
    }

    @IsTest
    static void callWebServiceSuccess() {
        User u = [SELECT Id FROM User WHERE LastName = :LASTNAME_TEST LIMIT 1];

        System.runAs(u) {

            Map<String, String> pathParams = new Map<String, String>();
            pathParams.put('{bookingId}', 'CAS01234567');
            Map<String, String> params = new Map<String, String>();
            params.put('shippingCompany', 'CMACGM');

            WS_Helper.testAuthToken = 'TEST.ewoiZXhwIjogMTUzOTEwNTg4NAp9.TEST';
            Test.setMock(HttpCalloutMock.class, new WS_CalloutMock(200, '{"response": "success"}'));

            Test.startTest();
            WS_Helper.testMock = false;
            HttpResponse bkgResponse = WS_Helper.callWebservice('WS_HelperTest', 'callWebService', null, null, pathParams, params, null, null);
            Test.stopTest();
        }
    }

    @IsTest
    static void callWebServiceErrorCalloutException() {
        User u = [SELECT Id FROM User WHERE LastName = :LASTNAME_TEST LIMIT 1];

        System.runAs(u) {

            Map<String, String> pathParams = new Map<String, String>();
            pathParams.put('{bookingId}', 'CAS01234567');
            Map<String, String> params = new Map<String, String>();
            params.put('shippingCompany', 'CMACGM');

            WS_Helper.testAuthToken = 'TEST.ewoiZXhwIjogMTUzOTEwNTg4NAp9.TEST';
            Test.setMock(HttpCalloutMock.class, new WS_CalloutMock('CalloutException', 'Error in the callout'));

            Test.startTest();
            try{
                HttpResponse bkgResponse = WS_Helper.callWebservice('WS_HelperTest', 'callWebService', null, null, pathParams, params, null, null);
            }catch(Exception e){
                System.debug(e.getMessage());
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void callWebServiceError404() {
        User u = [SELECT Id FROM User WHERE LastName = :LASTNAME_TEST LIMIT 1];

        System.runAs(u) {

            Map<String, String> pathParams = new Map<String, String>();
            pathParams.put('{bookingId}', 'CAS01234567');
            Map<String, String> params = new Map<String, String>();
            params.put('shippingCompany', 'CMACGM');

            WS_Helper.testAuthToken = 'TEST.ewoiZXhwIjogMTUzOTEwNTg4NAp9.TEST';
            Test.setMock(HttpCalloutMock.class, new WS_CalloutMock(404, '{"response": "error"}'));

            Test.startTest();
            try{
                HttpResponse bkgResponse = WS_Helper.callWebservice('WS_HelperTest', 'callWebService', null, null, pathParams, params, null, null);
            }catch(Exception e){
                System.debug(e.getMessage());
            }
            Test.stopTest();
        }
    }




}
