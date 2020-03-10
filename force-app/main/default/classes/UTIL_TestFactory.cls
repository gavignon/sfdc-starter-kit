/**
 * @author Gil Avignon <gavignon@salesforce.com>
 * @date Creation 12/04/2017
 * @date Modification 12/04/2017
 * @group Utilities
 * @description Utility class for creating test data
 */
@isTest
public class UTIL_TestFactory {
	private static String SYSTEM_ADMINISTRATOR_PROFILE_NAME = 'System Administrator';
	private static String CUSTOMER = '';
	/**
	 * @author Gil Avignon <gavignon@salesforce.com>
	 * @date 12/04/2017
	 * @date Modification 12/04/2017
	 * @description User test data factory
	 */
	public class UserFactory {
		/**
		 * @author Gil Avignon <gavignon@salesforce.com>
		 * @date 13/07/2016
		 * @description  create Administrator user
		 * @return  User
		 */
		public User createRunningUserAdministrator() {
			User administratorUser = new User(
				alias = 'Test',
				email = 'test.' + CUSTOMER + '@example.com',
				emailencodingkey = 'UTF-8',
				lastname = 'testUser',
				languagelocalekey = 'fr',
				localesidkey = 'fr_FR',
				// BypassVr__c = true,
				profileid = [
					SELECT Id
					FROM Profile
					WHERE Name = :SYSTEM_ADMINISTRATOR_PROFILE_NAME
					             LIMIT 1
				][0].Id,
				timezonesidkey = 'Europe/Paris',
				username = 'test.' + CUSTOMER + System.now().millisecond()
				           + UserInfo.getOrganizationId() + '@example.com'
				);
			return administratorUser;
		}
	}

	/**
	 * @author Gil Avignon <gavignon@salesforce.com>
	 * @date 28/04/2017
	 * @date Modification 28/04/2017
	 * @description Object test data factory
	 */
	public class ObjectFactory {
		/**
		 * @author Gil Avignon <gavignon@salesforce.com>
		 * @date 28/04/2017
		 * @description Create an object
		 * @param fields Field map
		 * @return SObject
		 */
		public SObject create(String sObjectName, Map<String, Object> fields, String recordTypeName){

			Id rTId = UTIL_RecordType.getRecordTypeIdByDeveloperName(recordTypeName, sObjectName);
			SObject objectRecord = Schema.getGlobalDescribe().get(sObjectName).newSObject();

			fields = UTIL_TestValidationRule.fillFields(sobjectName, fields, recordTypeName);

			for(String field : fields.keySet()) {
				objectRecord.put(field, fields.get(field));
			}
			return objectRecord;
		}

	}
}
