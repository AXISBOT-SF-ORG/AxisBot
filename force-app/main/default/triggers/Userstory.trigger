trigger Userstory on User_Story__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  if (Trigger.isBefore) {
    //     if (Trigger.isInsert) {
    //       UserstoryBeforeInsertHandler.handleBeforeInsert(Trigger.new);
    //     }
    //     if (Trigger.isUpdate) {
    //       UserstoryBeforeUpdateHandler.handleBeforeUpdate(Trigger.new, Trigger.old);
    //     }
    //     if (Trigger.isDelete) {
    //       UserstoryBeforeDeleteHandler.handleBeforeDelete(Trigger.old);
    //     }
  }
  if (Trigger.isAfter) {
    if (Trigger.isInsert) {
      UserstoryAfterInsertHandler.handleAfterInsert(Trigger.new);
    }
    //     if (Trigger.isUpdate) {
    //       UserstoryAfterUpdateHandler.handleAfterUpdate(Trigger.new, Trigger.old);
    //     }
    //     if (Trigger.isDelete) {
    //       UserstoryAfterDeleteHandler.handleAfterDelete(Trigger.old);
    //     }
    //     if (Trigger.isUndelete) {
    //       UserstoryAfterUndeleteHandler.handleAfterUndelete(Trigger.new);
    //     }
  }
}
