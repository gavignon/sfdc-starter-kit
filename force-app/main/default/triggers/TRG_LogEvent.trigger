trigger TRG_LogEvent on LogEvent__e (after insert) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            TRG_LogEventHandler.saveRecords(Trigger.new);
        }
    }
}
