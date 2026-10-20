public without sharing class ConversaoLead {

    public static void copiarDados(Map<Id, Lead> antigos, List<Lead> novos) {
        List<Lead> convertidos = new List<Lead>();
        for (Lead l : novos) {
            if (l.IsConverted && !antigos.get(l.Id).IsConverted) {
                convertidos.add(l);
            }
        }
        if (convertidos.isEmpty()) {
            return;
        }

        Set<Id> idsContas = new Set<Id>();
        Set<Id> idsContatos = new Set<Id>();
        Set<Id> idsOportunidades = new Set<Id>();
        Set<String> cnpjs = new Set<String>();
        for (Lead l : convertidos) {
            idsContas.add(l.ConvertedAccountId);
            idsContatos.add(l.ConvertedContactId);
            idsOportunidades.add(l.ConvertedOpportunityId);
            if (String.isNotBlank(l.CNPJ__c)) {
                cnpjs.add(l.CNPJ__c);
            }
        }
        idsContas.remove(null);
        idsContatos.remove(null);
        idsOportunidades.remove(null);

        Map<Id, Account> contas = new Map<Id, Account>(
            [
                SELECT Id, CNPJ__c, Porte__c, Razao_Social__c
                FROM Account
                WHERE Id IN :idsContas
                WITH SYSTEM_MODE
            ]
        );
        Map<Id, Contact> contatos = new Map<Id, Contact>(
            [
                SELECT Id, WhatsApp__c, Consentimento_LGPD__c, Consentimento_Data__c
                FROM Contact
                WHERE Id IN :idsContatos
                WITH SYSTEM_MODE
            ]
        );
        Map<Id, Opportunity> oportunidades = new Map<Id, Opportunity>(
            [
                SELECT Id, Produto_Interesse__c
                FROM Opportunity
                WHERE Id IN :idsOportunidades
                WITH SYSTEM_MODE
            ]
        );
        Set<String> cnpjsEmUso = cnpjsDeOutrasContas(cnpjs, idsContas);

        Map<Id, Account> contasAtualizar = new Map<Id, Account>();
        Map<Id, Contact> contatosAtualizar = new Map<Id, Contact>();
        Map<Id, Opportunity> oportunidadesAtualizar = new Map<Id, Opportunity>();

        for (Lead l : convertidos) {
            Account conta = contas.get(l.ConvertedAccountId);
            if (conta != null) {
                Boolean mudou = false;
                if (String.isBlank(conta.CNPJ__c) && String.isNotBlank(l.CNPJ__c) && !cnpjsEmUso.contains(l.CNPJ__c)) {
                    conta.CNPJ__c = l.CNPJ__c;
                    mudou = true;
                }
                if (String.isBlank(conta.Porte__c) && String.isNotBlank(l.Porte__c)) {
                    conta.Porte__c = l.Porte__c;
                    mudou = true;
                }
                if (String.isBlank(conta.Razao_Social__c) && String.isNotBlank(l.Company)) {
                    conta.Razao_Social__c = l.Company;
                    mudou = true;
                }
                if (mudou) {
                    contasAtualizar.put(conta.Id, conta);
                }
            }

            Contact contato = contatos.get(l.ConvertedContactId);
            if (contato != null) {
                Boolean mudou = false;
                if (String.isBlank(contato.WhatsApp__c) && String.isNotBlank(l.WhatsApp__c)) {
                    contato.WhatsApp__c = l.WhatsApp__c;
                    mudou = true;
                }
                if (contato.Consentimento_LGPD__c != true && l.Consentimento_LGPD__c == true) {
                    contato.Consentimento_LGPD__c = true;
                    contato.Consentimento_Data__c = l.Consentimento_Data__c;
                    mudou = true;
                }
                if (mudou) {
                    contatosAtualizar.put(contato.Id, contato);
                }
            }

            Opportunity oportunidade = oportunidades.get(l.ConvertedOpportunityId);
            if (oportunidade != null && oportunidade.Produto_Interesse__c == null && l.Produto_Interesse__c != null) {
                oportunidade.Produto_Interesse__c = l.Produto_Interesse__c;
                oportunidadesAtualizar.put(oportunidade.Id, oportunidade);
            }
        }

        Database.update(contasAtualizar.values(), AccessLevel.SYSTEM_MODE);
        Database.update(contatosAtualizar.values(), AccessLevel.SYSTEM_MODE);
        Database.update(oportunidadesAtualizar.values(), AccessLevel.SYSTEM_MODE);
    }

    private static Set<String> cnpjsDeOutrasContas(Set<String> cnpjs, Set<Id> idsContas) {
        Set<String> emUso = new Set<String>();
        if (cnpjs.isEmpty()) {
            return emUso;
        }
        for (Account a : [
            SELECT CNPJ__c
            FROM Account
            WHERE CNPJ__c IN :cnpjs AND Id NOT IN :idsContas
            WITH SYSTEM_MODE
        ]) {
            emUso.add(a.CNPJ__c);
        }
        return emUso;
    }
}
