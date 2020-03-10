/**
 * @author Gil Avignon <gavignon@salesforce.com>
 * @date Creation 20/05/2017
 * @date Modification 20/05/2017
 * @group Utilities
 * @description Utility class for managing validation rules
 */
@isTest
public class UTIL_TestValidationRule {

	/**
	 * @author Gil Avignon <gavignon@salesforce.com>
	 * @date 20/05/2017
	 * @description Fill fields depending on mandatory fields and validation rules
	 * @return the fields that will respect validation rules
	 */
	public static Map<String, Object> fillFields(String sObjectName, Map<String, Object> fields, String recordTypeName){
		Map<String, Object> finalFields = new Map<String, Object>();
		String randomNumber = String.valueOf(Math.random());
		Integer numberLength = 5;
		randomNumber = randomNumber.split('\\.')[1].substring(0,numberLength);

		if(sObjectName == 'Account') {
			// Mandatory fields
			fields.put('Name', 'Test account' + randomNumber);
		}

		finalFields.putAll(fields);

		return finalFields;
	}

}
