trigger AccountTrigger on Account(before insert, before update) {
    DocumentosValidacao.cnpj(Trigger.new, Trigger.oldMap, 'CNPJ__c');
}
