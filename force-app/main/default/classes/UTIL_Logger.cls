/**
* @author Gil Avignon
* @date 01/08/2018
* @description Utility Class for Log Management
* @group Utility
*/
public class UTIL_Logger {
    private static Map<String, Id> recordTypesByDeveloperName = UTIL_RecordType.getRecordTypesDeveloper('Log__c');
    public static List<LogEvent__e> logEvents = new List<LogEvent__e>();
    private static Integer cpt = 0;
    // private static LogSettings__c mySettings = LogSettings__c.getInstance();
    
    @InvocableMethod(label='Log Error' description='Log error in Log__c custom object.')
    public static void logEventFromFlow(List<FlowRequest> flowRequest){
        String recordType = 'Apex';
        if(flowRequest[0].recordType != null){
            recordType = flowRequest[0].recordType;
        }
    
        String recordTypeId = recordType == 'Callout' ? LOG_CALLOUT_RTID : LOG_APEX_RTID;
        LogEvent__e logEvent = new LogEvent__e(
                Identifier__c = generateId(),
                APIName__c = flowRequest[0].apiName,
                ApexClass__c = flowRequest[0].apexClass.left(50),
                ApexMethod__c = flowRequest[0].apexMethod.left(50),
                Description__c = flowRequest[0].errorMessage.left(255),
                Details__c = flowRequest[0].errorMessage.left(131072),
                Type__c = C3S_UTI01_Constants.LOG_TYPE_ERROR,
                EntityId__c = flowRequest[0].entityId.left(18),
                RecordTypeId__c = recordTypeId,
                ResponseStatusCode__c = flowRequest[0].responseStatusCode,
                ResponseBody__c = flowRequest[0].errorMessage.left(131072),
                RunningUser__c = UserInfo.getUserId(),
                StackTrace__c = flowRequest[0].errorMessage.left(131072)
        );
        if(Test.isRunningTest()){
            logEvent.Identifier__c = String.valueOf(cpt);
            cpt++;
        }
        logEvents.add(logEvent);
        commitLogEvents();
    }

    /**
    * @author Gil Avignon
    * @date 25/07/2018
    * @description Create log record for Apex errors
    * @param apiName API Name
    * @param description Error description
    * @param apexClass Calling apex class
    * @param apexMethod Calling apex method
    * @param endpoint Endpoint
    * @param entityId Entity ID
    * @param headerInfo Header informations
    * @return LogEvent__e Generated log event
    */
    public static LogEvent__e logEvent(String apiName, String description, String apexClass, String apexMethod, String endpoint, Id entityId, String headerInfo){
        LogEvent__e logEvent = new LogEvent__e(
                Identifier__c = generateId(),
                APIName__c = apiName,
                ApexClass__c = apexClass,
                ApexMethod__c = apexMethod,
                Description__c = description.left(255),
                Details__c = description,
                Type__c = UTIL_Constants.LOG_TYPE_ERROR,
                Endpoint__c = endpoint,
                RequestHeader__c = headerInfo,
                RunningUser__c = UserInfo.getUserId(),
                EntityId__c = entityId,
                RecordTypeId__c = recordTypesByDeveloperName.get('Apex')
        );
        if(Test.isRunningTest()){
            logEvent.Identifier__c = String.valueOf(cpt);
            cpt++;
        }
        logEvents.add(logEvent);

        return logEvent;
    }

    /**
    * @author Gil Avignon
    * @date 02/07/2019
    * @description Create debug log record for Apex
    * @param description Error description
    * @param apexClass Calling apex class
    * @param apexMethod Calling apex method
    * @param entityId Entity ID
    * @return LogEvent__e Generated log event
    */
    public static void debug(String description,String entityData, String apexClass, String apexMethod, Id entityId){
        // if(mySettings.Active__c && mySettings.ApexClass__c == apexClass && mySettings.ApexMethod__c == apexMethod){
            LogEvent__e logEvent = new LogEvent__e(
                    Identifier__c = generateId(),
                    ApexClass__c = apexClass,
                    ApexMethod__c = apexMethod,
                    Description__c = description.left(255),
                    Details__c = description,
                    Type__c = UTIL_Constants.LOG_TYPE_DEBUG,
                    RunningUser__c = UserInfo.getUserId(),
                    EntityId__c = entityId,
                    EntityData__c = entityData,
                    RecordTypeId__c = recordTypesByDeveloperName.get('Apex')
            );
            if(Test.isRunningTest()){
                logEvent.Identifier__c = String.valueOf(cpt);
                cpt++;
            }
            logEvents.add(logEvent);
        // }
    }


    /**
    * @author Gil Avignon
    * @date 25/07/2018
    * @description Create log record for Apex errors
    * @param apiName API Name
    * @param e Exception
    * @param apexClass Calling apex class
    * @param apexMethod Calling apex method
    * @param endpoint Endpoint
    * @param entityId Entity ID
    * @param headerInfo Header informations
    * @return LogEvent__e Generated log event
    */
    public static LogEvent__e logEventFromException(String apiName, Exception e, String apexClass, String apexMethod, String endpoint, Id entityId, String headerInfo){
        String recordTypeId = recordTypesByDeveloperName.get('Apex');
        if(e instanceof CalloutException){
            recordTypeId = recordTypesByDeveloperName.get('Callout');
        }

        LogEvent__e logEvent = new LogEvent__e(
                Identifier__c = generateId(),
                APIName__c = apiName,
                ApexClass__c = apexClass,
                ApexMethod__c = apexMethod,
                Description__c = e.getMessage().left(255),
                Details__c = e.getMessage(),
                Type__c = UTIL_Constants.LOG_TYPE_ERROR,
                Endpoint__c = endpoint,
                ExceptionType__c = e.getTypeName(),
                RequestHeader__c = headerInfo,
                EntityId__c = entityId,
                RecordTypeId__c = recordTypeId,
                RunningUser__c = UserInfo.getUserId(),
                StackTrace__c = e.getStackTraceString()
        );
        if(Test.isRunningTest()){
            logEvent.Identifier__c = String.valueOf(cpt);
            cpt++;
        }

        logEvents.add(logEvent);

        return logEvent;
    }

    /**
    * @author Gil Avignon
    * @date 25/07/2018
    * @description Create log record for Apex errors
    * @param apiName API Name
    * @param e Exception
    * @param apexClass Calling apex class
    * @param apexMethod Calling apex method
    * @param endpoint Endpoint
    * @param entityId Entity ID
    * @param headerInfo Header informations
    * @return LogEvent__e Generated log event
    */
    public static LogEvent__e logEventFromExceptionWithData(String apiName, Exception e, String apexClass, String apexMethod, String endpoint, Id entityId, String entityData, String headerInfo){
        String recordTypeId = recordTypesByDeveloperName.get('Apex');
        if(e instanceof CalloutException){
            recordTypeId = recordTypesByDeveloperName.get('Callout');
        }

        LogEvent__e logEvent = new LogEvent__e(
                Identifier__c = generateId(),
                APIName__c = apiName,
                ApexClass__c = apexClass,
                ApexMethod__c = apexMethod,
                Description__c = e.getMessage().left(255),
                Details__c = e.getMessage(),
                Type__c = UTIL_Constants.LOG_TYPE_ERROR,
                Endpoint__c = endpoint,
                ExceptionType__c = e.getTypeName(),
                RequestHeader__c = headerInfo,
                EntityId__c = entityId,
                EntityData__c = entityData,
                RecordTypeId__c = recordTypeId,
                RunningUser__c = UserInfo.getUserId(),
                StackTrace__c = e.getStackTraceString()
        );
        if(Test.isRunningTest()){
            logEvent.Identifier__c = String.valueOf(cpt);
            cpt++;
        }

        logEvents.add(logEvent);

        return logEvent;
    }




    /**
    * @author Gil Avignon
    * @date 25/07/2018
    * @description Create log record for Apex errors
    * @param apiName API Name
    * @param apexClass Calling apex class
    * @param apexMethod Calling apex method
    * @param request HTTP Request
    * @param response HTTP Response
    * @param debugLogs Debug mode
    * @return LogEvent__e Generated log event
    */
    public static LogEvent__e logEvent(String apiName, String apexClass, String apexMethod, HttpRequest request, HttpResponse response, Boolean debugLogs) {
        // Manage Request Headers
        String headers = '';
        if(request.getHeader(UTIL_Constants.REQUEST_HEADER_KEY) != null){
            headers += UTIL_Constants.REQUEST_HEADER_KEY + ': ' + request.getHeader(UTIL_Constants.REQUEST_HEADER_KEY) + '\n';
        }
        if(request.getHeader(UTIL_Constants.REQUEST_HEADER_KEYID) != null){
            headers += UTIL_Constants.REQUEST_HEADER_KEYID + ': ' + request.getHeader(UTIL_Constants.REQUEST_HEADER_KEYID) + '\n';
        }
        if(request.getHeader(UTIL_Constants.REQUEST_HEADER_TRACE_ORG) != null){
            headers += UTIL_Constants.REQUEST_HEADER_TRACE_ORG + ': ' + request.getHeader(UTIL_Constants.REQUEST_HEADER_TRACE_ORG) + '\n';
        }
        if(request.getHeader(UTIL_Constants.REQUEST_HEADER_TRACE_USER) != null){
            headers += UTIL_Constants.REQUEST_HEADER_TRACE_USER + ': ' + request.getHeader(UTIL_Constants.REQUEST_HEADER_TRACE_USER) + '\n';
        }
        if(request.getHeader(UTIL_Constants.REQUEST_HEADER_TRACE_ENTITY) != null){
            headers += UTIL_Constants.REQUEST_HEADER_TRACE_ENTITY + ': ' + request.getHeader(UTIL_Constants.REQUEST_HEADER_TRACE_ENTITY);
        }

        // Manage Response Headers
        String respHeaders = '';
        List<String> respHeaderKeys = response.getHeaderKeys();
        for(String keyHeader : respHeaderKeys){
            respHeaders += keyHeader + ': ' + response.getHeader(keyHeader) + '\n';
        }

        String correlationId = '';
        // Manage Correlation ID
        if(response.getHeader('X-CorrelationID') != null){
            correlationId = response.getHeader('X-CorrelationID');
        }

        // Prettify Body
        Object reqBodyObj = null;
        String reqBodyString = '';
        if(request.getBody() != null && request.getBody() != ''){
            reqBodyObj = JSON.deserializeUntyped(request.getBody());
            if(reqBodyObj != null){
                reqBodyString = JSON.serializePretty(reqBodyObj);
            }
        }
        Object respBodyObj = null;
        String respBodyString = '';
        if(response.getBody() != null && response.getBody() != ''){
            respBodyObj = JSON.deserializeUntyped(response.getBody());
            if(respBodyObj != null){
                respBodyString = JSON.serializePretty(respBodyObj);
            }
        }

        // Create log
        LogEvent__e logEvent = new LogEvent__e(
                Identifier__c = generateId(),
                APIName__c = apiName,
                ApexClass__c = apexClass,
                ApexMethod__c = apexMethod,
                CorrelationId__c = correlationId,
                Type__c = debugLogs ? UTIL_Constants.LOG_TYPE_DEBUG : UTIL_Constants.LOG_TYPE_ERROR,
                Endpoint__c = request.getEndpoint(),
                RequestHeader__c = headers,
                RequestBody__c = reqBodyString,
                ResponseHeader__c = respHeaders,
                ResponseBody__c = respBodyString,
                ResponseStatus__c = String.valueOf(response.getStatus()),
                ResponseStatusCode__c = String.valueOf(response.getStatusCode()),
                RunningUser__c = UserInfo.getUserId(),
                EntityId__c = request.getHeader(UTIL_Constants.REQUEST_HEADER_TRACE_ENTITY),
                RecordTypeId__c = recordTypesByDeveloperName.get('Callout'),
                StackTrace__c = ''
        );
        if(Test.isRunningTest()){
            logEvent.Identifier__c = String.valueOf(cpt);
            cpt++;
        }

        logEvents.add(logEvent);

        return logEvent;
    }

    /**
    * @author Gil Avignon
    * @date 25/07/2018
    * @description Generate log unique Identifier
    * @param logEvent record
    * @return Log__c generated log Object record
    */
    public static Log__c log(LogEvent__e logEvent) {
        return new Log__c(
                Identifier__c = logEvent.Identifier__c,
                APIName__c = logEvent.APIName__c,
                ApexClass__c = logEvent.ApexClass__c,
                ApexMethod__c = logEvent.ApexMethod__c,
                CorrelationId__c = logEvent.CorrelationId__c,
                Description__c = logEvent.Description__c,
                Details__c = logEvent.Details__c,
                Type__c = logEvent.Type__c,
                Endpoint__c = logEvent.Endpoint__c,
                ExceptionType__c = logEvent.ExceptionType__c,
                RequestHeader__c = logEvent.RequestHeader__c,
                RequestBody__c = logEvent.RequestBody__c,
                ResponseHeader__c = logEvent.ResponseHeader__c,
                ResponseBody__c = logEvent.ResponseBody__c,
                ResponseStatus__c = logEvent.ResponseStatus__c,
                ResponseStatusCode__c = logEvent.ResponseStatusCode__c,
                RunningUser__c = logEvent.RunningUser__c,
                EntityId__c = logEvent.EntityId__c,
                EntityData__c = logEvent.EntityData__c,
                RecordTypeId = logEvent.RecordTypeId__c,
                StackTrace__c = logEvent.StackTrace__c
        );
    }

    /**
    * @author Gil Avignon
    * @date 25/07/2018
    * @description Generate log unique Identifier
    * @return String Generated log Identifier
    */
    public static String generateId(){
        String lastName = UserInfo.getLastName().toUpperCase();
        String firstName = UserInfo.getFirstName().toUpperCase();
        Datetime currentDate = Datetime.now();

        String generatedId = firstName.substring(0, 1) + lastName.substring(0, 2) + '-' + currentDate.format('YY')
                + currentDate.format('MM') + currentDate.format('dd') + '-' + currentDate.format('HH') + currentDate.format('mm')
                + currentDate.format('ss') + currentDate.format('SSS');

        return generatedId;
    }

    /**
    * @author Gil Avignon
    * @date 30/07/2018
    * @description Commit Debug log events
    * @return void
    */
    public static List<Database.SaveResult> commitLogEvents(){
        List<Database.SaveResult> results;
        if(logEvents.size() > 0){
            results = EventBus.publish(logEvents);
            logEvents.clear();
        }
        return results;
    }

}
