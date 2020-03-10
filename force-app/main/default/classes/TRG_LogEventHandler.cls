/**
* @author Gil Avignon
* @date 06/11/2018
* @description Log Event trigger handler
* @group Trigger Handler
*/
public with sharing class TRG_LogEventHandler {
    private static final String CLASS_NAME = TRG_LogEventHandler.class.getName();

    /**
    * @author Gil Avignon
    * @date 26/04/2019
    * @description Check and Validate the From Address when users send Emails
    * @param List<EmailMessage> emailMessages
    * @return void
    */
    public static void saveRecords(List<LogEvent__e> logEvents){
        List<Log__c> logs = new List<Log__c>();
        Boolean hasErrors = false;
        for(LogEvent__e logEvent : logEvents){
            logs.add(UTIL_Logger.log(logEvent));
        }
        if(logs.size() > 0){
            List<Database.SaveResult> results = Database.insert(logs, false);
            for (Database.SaveResult sr : results) {
                if (!sr.isSuccess()) {
                    hasErrors = true;
                    for(Database.Error err : sr.getErrors()) {
                        LogEvent__e logEvent = UTIL_Logger.logEvent(null, err.getMessage(), 'TRG_LogEventHandler', 'saveRecords', null, sr.getId(), null);
                    }
                }
            }
            if(hasErrors){
                UTIL_Logger.commitLogEvents();
            }
        }
    }
}
