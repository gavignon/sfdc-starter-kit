/**
* @author Gil Avignon
* @date 11/06/2018
* @description Utility class to manage global method, record types, Id generation ...
* @group Utility
*/
public with sharing class UTIL_RecordType {
    private static Map<String, Map<String, Id>> recordTypesByObjectAndName;
    private static Map<String, Map<String, Id>> recordTypesByObjectAndDeveloperName;

    static {
        prepareRecordTypeMaps();
    }

     public static Map<String, sObject[]> splitsObjectByRecordType(String objectTypeName, sObject[] recordList){
        Map<String, sObject[]> sObjectMap = new Map<String, sObject[]>();
        //On recupere les DeveloperName de l'objet
       // Map<Id, RecordType> RTMap = new Map<Id,RecordType>([SELECT DeveloperName FROM RecordType WHERE sObjectType=:objectTypeName]);

        Map<Id,String> RTMap=new  Map<Id,String>();
        for(Schema.RecordTypeInfo rtInfo : Schema.getGlobalDescribe().get(objectTypeName).getDescribe().getRecordTypeInfosByDeveloperName().values()){
                RTMap.put(rtInfo.getRecordTypeId(),rtInfo.getDeveloperName());
            }

        //classement de chaque élément
        if(!recordList.isEmpty()){
            for(sObject record : recordList){
                //récupération du developerName du record
                String recordTypeName = RTMap.get((Id) record.get('recordTypeId'));

                //On vérifie si on a déjà traité ce type de record
                if(sObjectMap.get(recordTypeName) == null){
                    sObjectMap.put(recordTypeName, new sObject[]{record});
                }else{
                    sObjectMap.get(recordTypeName).add(record);
                }
            }
        }
        return sObjectMap;
     }


    public static List<String> getFieldSetApiName(String fieldSetName, String sObjectName){
        List<String> apiName = new List<String>();
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe();
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(sObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
        for(Schema.FieldSetMember fieldSetMemberObj : fieldSetObj.getFields()){
            ApiName.add(fieldSetMemberObj.getFieldPath());
        }
        return apiName;
    }



    public static ConnectApi.BatchInput sendChatterNotification(String firstText, Id mention, String secondText,Id subjectId){

         ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
                    messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

                    // add some text before the mention
                    ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
                    textSegment.text = firstText;
                    messageInput.messageSegments.add(textSegment);

                    // add the mention
                    ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
                    mentionSegment.id = mention ;
                    messageInput.messageSegments.add(mentionSegment);

                    // add the text that was passed
                    textSegment = new ConnectApi.TextSegmentInput();
                    textSegment.text = secondText;
                    messageInput.messageSegments.add(textSegment);

                    ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
                    input.subjectId =subjectId;
                    input.body = messageInput;

                    ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(input);

                    System.debug(LoggingLevel.ERROR, '*** batchInput: ' + batchInput);
                    return batchInput;
    }





    private static void prepareRecordTypeMaps() {
        recordTypesByObjectAndName = new Map<String, Map<String, Id>>();
        recordTypesByObjectAndDeveloperName = new Map<String, Map<String, Id>>();
        for (RecordType rt : [SELECT sObjectType, Name, Id, DeveloperName FROM RecordType WHERE isActive = true]) {

            Map<String, Id> rtByName = recordTypesByObjectAndName.get(rt.sObjectType);
            Map<String, Id> rtByDeveloperName = recordTypesByObjectAndDeveloperName.get(rt.sObjectType);
            if (rtByName == null) {
                rtByName = new Map<String, Id>();
                recordTypesByObjectAndName.put(rt.sObjectType, rtByName);
            }
            rtByName.put(rt.Name, rt.Id);
            if (rtByDeveloperName == null) {
                rtByDeveloperName = new Map<String, Id>();
                recordTypesByObjectAndDeveloperName.put(rt.sObjectType, rtByDeveloperName);
            }
            rtByDeveloperName.put(rt.DeveloperName, rt.Id);
        }
    }

    public static Id getRecordTypeIdByDeveloperName(String developerName, String objectName) {
        Id resultId = null;
        if (String.isNotEmpty(developerName)) {
            resultId = getRecordTypesDeveloper(objectName).get(developerName);
        }
        return resultId;
    }

    public static Map<String, Id> getRecordTypesDeveloper(String objectName) {
        Map<String, Id> recordTypes = new Map<String, Id>();
        if (String.isNotEmpty(objectName)) {
            recordTypes = recordTypesByObjectAndDeveloperName.get(objectName);
        }
        return recordTypes;
    }

    public static Map<String, Id> getRecordTypes(String objectName) {
        Map<String, Id> recordTypes = new Map<String, Id>();
        if (String.isNotEmpty(objectName)) {
            recordTypes = recordTypesByObjectAndName.get(objectName);
            //recordTypes.putAll(recordTypesByObjectAndDeveloperName.get(objectName));
        }
        return recordTypes;
    }

    public static String getUniqueId(){
	    String milliseconds = String.ValueOf(System.Now().getTime()); //unix timestamp
	    Blob pseudoHash = Blob.ValueOf(milliseconds + String.ValueOf(Crypto.getRandomInteger()));
	    String uniqueString = EncodingUtil.convertToHex(pseudoHash);
	    uniqueString = uniqueString.length() > 255 ? uniqueString.substring(0,255) : uniqueString;
	    return uniqueString;
	}

    public static String shortenID(String idValue) {
        String[] keys = idValue.left(15).split('');
        while(keys.size() > 5 && keys[5] == '0') {
            keys.remove(5);
        }
        return String.join(keys,'');
    }

    public static String getThreadId(Id caseId) {
        return
            'ref:_' + shortenId(UserInfo.getOrganizationId()) +
            '._'    + shortenId(caseId) +  ':ref';
    }

    public static String getUTCOffset(String dateTimeString){
        String offset = '+00:00';
        String[] splitPlus = dateTimeString.split('\\+');
        Integer splitPlusSize = splitPlus.size();


        // If there is a positive UTC Offset
        if(splitPlusSize > 1){
            offset = '+' + splitPlus[splitPlusSize - 1];
        }else{
            String[] splitMinus = dateTimeString.split('-');
            Integer splitMinusSize = splitMinus.size();

            // Must be > to 3 because there is already two '-' in the DateTime format: YYYY-MM-DDThh:mm:ss-00:00
            if(splitMinusSize > 3){
                offset = '-' + splitMinus[splitMinusSize - 1];
            }
        }
        return offset;
    }

    public static Boolean validateEmail(String email) {
        Boolean res = true;


        String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$'; // source: <a href="http://www.regular-expressions.info/email.html" target="_blank" rel="nofollow">http://www.regular-expressions.info/email.html</a>
        Pattern MyPattern = Pattern.compile(emailRegex);
        Matcher MyMatcher = MyPattern.matcher(email);
        System.debug(LoggingLevel.ERROR, '*** validateEmail:MyMatcher.matches() ' +MyMatcher.matches() );
        if (!MyMatcher.matches())
            res = false;
        return res;
    }

    public static Integer indexOfBody(String HtmlBody) {

        String body= HtmlBody.toLowerCase();
        Integer endBody = -1;
        Integer startBody = body.indexOf('<body');
        if (startBody != -1) {
            endBody = body.indexOf('>',startBody) +1;
        }
        return endBody;
    }

    public static String getTimeZone(Map<String, String> mapTimezoneByOffset, String localDate){
        String timeZone = mapTimezoneByOffset.get(UTIL_RecordType.getUTCOffset(localDate));
        if(timeZone == null){
            timeZone = UserInfo.getTimeZone().getID();
        }
        return timeZone;
    }

    public static Map<String,String> getPicklistValues(String obj, String field) {
        return getPicklistValues(obj, field, false);
    }

    public static Map<String,String> getPicklistValues(String obj, String field, boolean toLower) {
        Map<String, String> valueByLabel = new Map<String, String>();

        Map<String, Schema.SObjectType> global_describe = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> object_fields_map = global_describe.get(obj).getDescribe().fields.getMap();
        Schema.DescribeFieldResult fieldResult = object_fields_map.get(field).getDescribe();
        Schema.sObjectField objectField = fieldResult.getSObjectField();
        List<PicklistEntry> entries = objectField.getDescribe().getPicklistValues();

        for(Schema.PicklistEntry e : entries) {
               valueByLabel.put(toLower ? e.getLabel().toLowerCase(): e.getLabel(), e.getValue());
        }

        return valueByLabel;
    }

    public static Map<String,String> getPicklistLabels(String obj, String field) {
        Map<String, String> labelByValue = new Map<String, String>();

        Map<String, Schema.SObjectType> global_describe = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> object_fields_map = global_describe.get(obj).getDescribe().fields.getMap();
        Schema.DescribeFieldResult fieldResult = object_fields_map.get(field).getDescribe();
        Schema.sObjectField objectField = fieldResult.getSObjectField();
        List<PicklistEntry> entries = objectField.getDescribe().getPicklistValues();

        for(Schema.PicklistEntry e : entries) {
               labelByValue.put(e.getValue(),e.getLabel());
        }

        return labelByValue;
    }

    public static String formatDateTime(String inputDateString){
        /*
        String[] timezoneArray = inputDateString.split('\\+');
        String operator = '';
        String timezone = '';
        String datetimeString = '';
        if(timezoneArray.size() > 1){
            operator = '+';
            timezone = timezoneArray[1];
            datetimeString = timezoneArray[0];
        }else{
            timezoneArray = inputDateString.split('\\-');
            if(timezoneArray.size() > 3){
                operator = '-';
            	timezone = timezoneArray[3];
                datetimeString = timezoneArray[0] + '-' + timezoneArray[1] + '-' + timezoneArray[2];
            }else{
                datetimeString = inputDateString.replaceAll('Z', '');
            }
        }

        String[] datetimeArray = datetimeString.split('T');
        String[] dateArray = datetimeArray[0].split('-');
        String year = dateArray[0];
        String month = dateArray[1];
        String day = dateArray[2];
        String[] timeArray = datetimeArray[1].split(':');
        String hour = timeArray[0];
        Integer hour = Integer.valueOf(timeArray[0]);
        if(operator == '+'){
            hour += Integer.valueOf(timezone.split(':')[0]);
        }
        if(operator == '-'){
            hour -= Integer.valueOf(timezone.split(':')[0]);
        }
        String hourString = hour.format();
        if(hour < 10){
            hourString = '0' + hourString;
        }

        String minutes = timeArray[1];
        String seconds = timeArray[2];

        String returnedString = day + '/' + month + '/' + year + ' ' + hour + ':' + minutes + ':' + seconds + ' GMT' + operator + timezone;

        return returnedString;
        */
        return inputDateString;
    }

    public static Boolean isSandbox() {
        return [select IsSandbox from Organization limit 1].IsSandbox;
    }

    public static String findWithRegularExpression(String inputString, String regex, String delimiterStart, String delimiterEnd, Integer fieldSizeLimit){
        String result = null;
        if(inputString != null){
            Pattern resultPattern = Pattern.compile(regex);
            Matcher resultMatcher = resultPattern.matcher(inputString);
            if(resultMatcher.find()){
                String foundString = resultMatcher.group();
                if(delimiterStart != null){
                    foundString = foundString.replaceFirst(delimiterStart, '');
                }
                if(delimiterEnd != null){
                    foundString = foundString.replaceFirst(delimiterEnd + '$', '');
                }
                result = fieldSizeLimit != null ? foundString.left(fieldSizeLimit) : foundString;
            }
        }

        return result;
    }

}
