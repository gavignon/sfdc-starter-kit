/**
* @author Gil Avignon
* @date 14/06/2018
* @description Test class for UTIL_Logger
* @group Tests
*/
@isTest
public class UTIL_LoggerTest {

    private static final String FIRSTNAME_TEST = 'Test';
    private static final String LASTNAME_TEST = 'TestUser';
    private static UTIL_TestFactory.UserFactory userFactory = new UTIL_TestFactory.UserFactory();

    @testSetup static void setup() {
        User u = userFactory.createRunningUserAdministrator();
        insert u;
    }

    @isTest
    static void saveLog() {
        User u = [SELECT Id FROM User WHERE LastName = :LASTNAME_TEST LIMIT 1];

        System.runAs(u) {

            String description = 'Description';
            String apexClass = 'UTIL_Logger';
            String apexMethod = 'saveLog';
            String endpoint = 'https://endpoint.com';

            HttpRequest req = new HttpRequest();
            req.setHeader(UTIL_Constants.REQUEST_HEADER_TRACE_ORG, UserInfo.getOrganizationId());
            req.setEndpoint(endpoint);
            HttpResponse resp = new HttpResponse();
            resp.setBody('{"body": "example"}');

            Test.startTest();
            LogEvent__e logEvent1 = UTIL_Logger.logEvent(null, description, apexClass, apexMethod, endpoint, null, null);
            LogEvent__e logEvent2 = UTIL_Logger.logEventFromException(null, new CalloutException('ERROR'), apexClass, apexMethod, endpoint, null, null);
            LogEvent__e logEvent3 = UTIL_Logger.logEvent(null, apexClass, apexMethod, new HttpRequest(), new HttpResponse(), false);

            UTIL_Logger.commitLogEvents();
            Test.stopTest();

            Log__c l = [SELECT Id, Identifier__c, ApexClass__c, ApexMethod__c, APIName__c, Description__c, Endpoint__c FROM Log__c WHERE Identifier__c = :logEvent1.Identifier__c LIMIT 1];
            System.assertEquals(logEvent1.Identifier__c, l.Identifier__c);
            System.assertEquals(description, l.Description__c);
            System.assertEquals(apexClass, l.ApexClass__c);
            System.assertEquals(apexMethod, l.ApexMethod__c);
            System.assertEquals(null, l.APIName__c);
            System.assertEquals(endpoint, l.Endpoint__c);

            Log__c l2 = [SELECT Id, Identifier__c, ApexClass__c, ApexMethod__c, APIName__c, Description__c, Endpoint__c FROM Log__c WHERE Identifier__c = :logEvent2.Identifier__c LIMIT 1];
            System.assertEquals(logEvent2.Identifier__c, l2.Identifier__c);
            System.assertEquals('ERROR', l2.Description__c);
            System.assertEquals(apexClass, l2.ApexClass__c);
            System.assertEquals(apexMethod, l2.ApexMethod__c);
            System.assertEquals(null, l2.APIName__c);
            System.assertEquals(endpoint, l2.Endpoint__c);

            Log__c l3 = [SELECT Id, Identifier__c, ApexClass__c, ApexMethod__c, APIName__c, Description__c, Endpoint__c FROM Log__c WHERE Identifier__c = :logEvent3.Identifier__c LIMIT 1];
            System.assertEquals(logEvent3.Identifier__c, l3.Identifier__c);
            System.assertEquals(null, l3.Description__c);
            System.assertEquals(apexClass, l3.ApexClass__c);
            System.assertEquals(apexMethod, l3.ApexMethod__c);
            System.assertEquals(null, l3.APIName__c);

        }
    }

}
