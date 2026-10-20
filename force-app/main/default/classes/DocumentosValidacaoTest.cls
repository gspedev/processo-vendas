@IsTest
private class DocumentosValidacaoTest {

    @IsTest
    static void leadComCnpjValidoSalva() {
        insert new Lead(LastName = 'Silva', Company = 'Empresa Teste', CNPJ__c = '11222333000181');

        System.assertEquals(1, [SELECT COUNT() FROM Lead WHERE CNPJ__c = '11222333000181']);
    }

    @IsTest
    static void leadComCnpjInvalidoNaoSalva() {
        Database.SaveResult r = Database.insert(
            new Lead(LastName = 'Silva', Company = 'Empresa Teste', CNPJ__c = '11222333000182'),
            false
        );

        System.assert(!r.isSuccess());
        System.assert(r.getErrors()[0].getMessage().contains('CNPJ inválido'));
    }

    @IsTest
    static void contaComCnpjInvalidoNaoSalva() {
        Database.SaveResult r = Database.insert(new Account(Name = 'Conta Teste', CNPJ__c = '12345678000100'), false);

        System.assert(!r.isSuccess());
    }

    @IsTest
    static void contaComCnpjValidoSalva() {
        insert new Account(Name = 'Conta Teste', CNPJ__c = '11222333000181');

        System.assertEquals(1, [SELECT COUNT() FROM Account WHERE CNPJ__c = '11222333000181']);
    }

    @IsTest
    static void contatoComCpfInvalidoNaoSalva() {
        Database.SaveResult r = Database.insert(new Contact(LastName = 'Silva', CPF__c = '52998224726'), false);

        System.assert(!r.isSuccess());
        System.assert(r.getErrors()[0].getMessage().contains('CPF inválido'));
    }

    @IsTest
    static void contatoComCpfValidoSalva() {
        insert new Contact(LastName = 'Silva', CPF__c = '52998224725');

        System.assertEquals(1, [SELECT COUNT() FROM Contact WHERE CPF__c = '52998224725']);
    }

    @IsTest
    static void naoRevalidaDocumentoQueNaoMudou() {
        Lead lead = new Lead(LastName = 'Silva', Company = 'Empresa Teste', CNPJ__c = '11222333000181');
        insert lead;

        lead.Company = 'Outra Empresa';
        update lead;

        System.assertEquals('Outra Empresa', [SELECT Company FROM Lead WHERE Id = :lead.Id].Company);
    }

    @IsTest
    static void filialSemMatrizNaoSalva() {
        Database.SaveResult r = Database.insert(new Account(Name = 'Filial Teste', Tipo_Estabelecimento__c = 'Filial'), false);

        System.assert(!r.isSuccess());

        Account matriz = new Account(Name = 'Matriz Teste', Tipo_Estabelecimento__c = 'Matriz');
        insert matriz;
        r = Database.insert(new Account(Name = 'Filial Teste', Tipo_Estabelecimento__c = 'Filial', ParentId = matriz.Id), false);
        System.assert(r.isSuccess());
    }
}
