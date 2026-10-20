trigger LeadTrigger on Lead(before insert, before update, after update) {
    if (Trigger.isBefore) {
        DocumentosValidacao.cnpj(Trigger.new, Trigger.oldMap, 'CNPJ__c');
    } else if (Trigger.isAfter && Trigger.isUpdate) {
        ConversaoLead.copiarDados(Trigger.oldMap, Trigger.new);
    }
}
