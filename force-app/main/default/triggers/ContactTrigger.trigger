trigger ContactTrigger on Contact(before insert, before update) {
    DocumentosValidacao.cpf(Trigger.new, Trigger.oldMap, 'CPF__c');
}
