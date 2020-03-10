/**
* @author Gil Avignon
* @date 11/06/2018
* @description Test class for UTIL_RecordType
* @group Test
*/
@isTest
private class UTIL_RecordTypeTest {

	private static final String FIRSTNAME_TEST      = 'Test';
    private static final String LASTNAME_TEST       = 'TestUser';
    private static final String EMAIL               = 'test12@customer.test.com';
    private static UTIL_TestFactory.UserFactory userFactory = new UTIL_TestFactory.UserFactory();
	/*******************************************************************************************************
    * @description Create common test case data
    */
    @TestSetup static void setup() {
        User u = userFactory.createRunningUserAdministrator();
        insert u;


    }

    static testMethod void getTimeZoneTest() {
    	User u = [SELECT Id FROM User WHERE LastName = :LASTNAME_TEST LIMIT 1];
    	Map<String, String> mapTimezoneByOffset = new Map<String, String>();

    	String localDate = '11/20/2010 12:00:00 PM';

    	System.runAs(u) {

        Test.startTest();
        	String result = UTIL_RecordType.getTimeZone(mapTimezoneByOffset,localDate);
         Test.stopTest();

         System.AssertNotEquals(result,null);

        }
    }

    static testMethod void indexOfBodyTest() {
    	User u = [SELECT Id FROM User WHERE LastName = :LASTNAME_TEST LIMIT 1];

    	String htmlBody = '<body';

    	System.runAs(u) {

        Test.startTest();
        	Integer result = UTIL_RecordType.indexOfBody(htmlBody);
         Test.stopTest();

         System.AssertNotEquals(result,null);

        }
    }
}
