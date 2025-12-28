trigger QuoteTrigger on Quote (before insert,before update,after insert,after update,after delete,after undelete,before delete) {
     if(Trigger.isAfter){
          if(Trigger.isUpdate){
               QuoteTriggerUpdateHandler.handleAfterUpdate(Trigger.newMap,Trigger.oldMap);
          }
     }
}