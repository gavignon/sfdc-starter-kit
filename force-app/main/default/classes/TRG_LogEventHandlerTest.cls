/**
* @author Gil Avignon
* @date 11/06/2019
* @description Test class for TRG_LogEventHandler
* @group Tests
*/
@IsTest
public with sharing class TRG_LogEventHandlerTest {
    private static final String FIRSTNAME_TEST = 'Test';
    private static final String LASTNAME_TEST = 'TestUser';
    private static Map<String, Id> recordTypesByDeveloperName = UTIL_RecordType.getRecordTypesDeveloper('Log__c');
    private static UTIL_TestFactory.UserFactory userFactory = new UTIL_TestFactory.UserFactory();

    @TestSetup
    static void setup() {
        User u = userFactory.createRunningUserAdministrator();
        insert u;
    }

    @isTest
    static void saveRecordsSuccess() {
        User u = [SELECT Id FROM User WHERE LastName = :LASTNAME_TEST LIMIT 1];

        System.runAs(u) {

            LogEvent__e logEvent = new LogEvent__e(
                    Identifier__c = UTIL_Logger.generateId(),
                    APIName__c = null,
                    ApexClass__c = 'C3S_TRG05LogEventHandlerTest',
                    ApexMethod__c = 'saveRecords',
                    Description__c = 'error',
                    Details__c = 'error',
                    Type__c = UTIL_Constants.LOG_TYPE_ERROR,
                    Endpoint__c = null,
                    RequestHeader__c = null,
                    RunningUser__c = UserInfo.getUserId(),
                    EntityId__c = null,
                    RecordTypeId__c = recordTypesByDeveloperName.get('Apex')
            );

            Test.startTest();
            EventBus.publish(logEvent);
            Test.stopTest();

            List<Log__c> logs = [SELECT Id FROM Log__c];
            System.assertEquals(1, logs.size());
        }
    }

    @isTest
    static void saveRecordsError() {
        User u = [SELECT Id FROM User WHERE LastName = :LASTNAME_TEST LIMIT 1];

        System.runAs(u) {

            LogEvent__e logEvent = new LogEvent__e(
                    Identifier__c = UTIL_Logger.generateId(),
                    APIName__c = 'I don\'t exist',
                    ApexClass__c = 'C3S_TRG05LogEventHandlerTest',
                    ApexMethod__c = 'saveRecords',
                    Description__c = 'error',
                    Details__c = 'error',
                    Type__c = UTIL_Constants.LOG_TYPE_ERROR,
                    Endpoint__c = null,
                    RequestHeader__c = null,
                    RunningUser__c = UserInfo.getUserId(),
                    EntityId__c = null,
                    RecordTypeId__c = recordTypesByDeveloperName.get('Apex')
            );

            Test.startTest();
            EventBus.publish(logEvent);
            Test.stopTest();

            List<Log__c> logs = [SELECT Id FROM Log__c];
            System.assertEquals(0, logs.size());
        }
    }
}
