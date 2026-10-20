@IsTest
private class ConversaoLeadTest {

    private static Product2 novoProduto() {
        Product2 p = new Product2(Name = 'Consultoria de Teste', IsActive = true);
        insert p;
        return p;
    }

    private static Lead novoLeadPronto(String cnpj) {
        Lead lead = new Lead(
            FirstName = 'Ana',
            LastName = 'Silva',
            Company = 'Empresa Teste Ltda',
            Email = 'ana@example.com',
            CNPJ__c = cnpj,
            Porte__c = 'ME',
            WhatsApp__c = '(11) 99999-0000',
            Produto_Interesse__c = novoProduto().Id,
            Consentimento_LGPD__c = true,
            Consentimento_Data__c = Datetime.now()
        );
        insert lead;
        insert new Task(
            WhoId = lead.Id,
            Subject = 'Contato Inicial',
            Status = 'Completed',
            Resultado_Contato__c = 'Contatado com sucesso'
        );
        return lead;
    }

    private static Database.LeadConvertResult converter(Lead lead, Id contaExistente, Boolean criarOportunidade) {
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(lead.Id);
        lc.setConvertedStatus('Closed - Converted');
        lc.setDoNotCreateOpportunity(!criarOportunidade);
        if (contaExistente != null) {
            lc.setAccountId(contaExistente);
        }
        return Database.convertLead(lc);
    }

    @IsTest
    static void copiaDadosParaContaContatoEOportunidade() {
        Lead lead = novoLeadPronto('11222333000181');

        Database.LeadConvertResult r = converter(lead, null, true);

        System.assert(r.isSuccess());
        Account conta = [
            SELECT CNPJ__c, Porte__c, Razao_Social__c
            FROM Account
            WHERE Id = :r.getAccountId()
        ];
        System.assertEquals('11222333000181', conta.CNPJ__c);
        System.assertEquals('ME', conta.Porte__c);
        System.assertEquals('Empresa Teste Ltda', conta.Razao_Social__c);
        Contact contato = [
            SELECT WhatsApp__c, Consentimento_LGPD__c, Consentimento_Data__c
            FROM Contact
            WHERE Id = :r.getContactId()
        ];
        System.assertEquals('(11) 99999-0000', contato.WhatsApp__c);
        System.assert(contato.Consentimento_LGPD__c);
        System.assertNotEquals(null, contato.Consentimento_Data__c);
        Opportunity op = [SELECT Produto_Interesse__c FROM Opportunity WHERE Id = :r.getOpportunityId()];
        System.assertEquals([SELECT Produto_Interesse__c FROM Lead WHERE Id = :lead.Id].Produto_Interesse__c, op.Produto_Interesse__c);
    }

    @IsTest
    static void semOportunidadeNaoQuebra() {
        Lead lead = novoLeadPronto('11222333000181');

        Database.LeadConvertResult r = converter(lead, null, false);

        System.assert(r.isSuccess());
        System.assertEquals(null, r.getOpportunityId());
    }

    @IsTest
    static void naoSobrescreveContaExistente() {
        Account existente = new Account(Name = 'Conta Existente', CNPJ__c = '11444777000161', Porte__c = 'Grande');
        insert existente;
        Lead lead = novoLeadPronto('11222333000181');

        converter(lead, existente.Id, false);

        Account depois = [SELECT CNPJ__c, Porte__c, Razao_Social__c FROM Account WHERE Id = :existente.Id];
        System.assertEquals('11444777000161', depois.CNPJ__c);
        System.assertEquals('Grande', depois.Porte__c);
        System.assertEquals('Empresa Teste Ltda', depois.Razao_Social__c);
    }

    @IsTest
    static void nuncaDuplicaCnpjNaConversao() {
        insert new Account(Name = 'Outra Conta', CNPJ__c = '11222333000181');
        Lead lead = novoLeadPronto('11222333000181');

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(lead.Id);
        lc.setConvertedStatus('Closed - Converted');
        lc.setDoNotCreateOpportunity(true);
        try {
            Database.convertLead(lc);
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('DUPLICATE_VALUE'));
        }

        System.assertEquals(1, [SELECT COUNT() FROM Account WHERE CNPJ__c = '11222333000181']);
    }
}
