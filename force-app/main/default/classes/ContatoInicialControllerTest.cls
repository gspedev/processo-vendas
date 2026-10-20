@IsTest
private class ContatoInicialControllerTest {

    private static Lead novoLead() {
        Lead lead = new Lead(
            FirstName = 'Ana',
            LastName = 'Silva',
            Company = 'Empresa Teste',
            Email = 'ana@example.com'
        );
        insert lead;
        return lead;
    }

    private static String novoToken(Lead lead) {
        ContatoInicialServico.urlBaseTeste = 'https://exemplo.test/contato';
        ContatoInicialServico.Entrada e = new ContatoInicialServico.Entrada();
        e.leadId = lead.Id;
        ContatoInicialServico.preparar(new List<ContatoInicialServico.Entrada>{ e });
        return [SELECT Token_Acesso__c FROM Task WHERE WhoId = :lead.Id WITH SYSTEM_MODE].Token_Acesso__c;
    }

    private static ContatoInicialController abrir(String token) {
        PageReference pagina = Page.ContatoInicial;
        pagina.getParameters().put('t', token);
        Test.setCurrentPage(pagina);
        return new ContatoInicialController();
    }

    private static void preencher(ContatoInicialController c) {
        c.cnpj = '11.222.333/0001-81';
        c.porte = 'ME';
        c.segmento = 'Desenvolvimento de software';
        c.telefone = '(11) 3000-0000';
        c.whatsapp = '(11) 99999-0000';
        c.cargo = 'Diretora Comercial';
        c.consentimento = true;
    }

    @IsTest
    static void tokenValidoAbreFormulario() {
        Lead lead = novoLead();
        ContatoInicialController c = abrir(novoToken(lead));

        System.assertEquals('form', c.estado);
        System.assertEquals('Ana', c.nomeContato);
        System.assertEquals('Empresa Teste', c.empresa);
        System.assert(c.getPortes().size() > 1);
    }

    @IsTest
    static void tokenInvalidoOuAusente() {
        System.assertEquals('invalido', abrir(null).estado);
        System.assertEquals('invalido', abrir('abc').estado);
        System.assertEquals('invalido', abrir('a'.repeat(64)).estado);
    }

    @IsTest
    static void tokenExpiradoNaoAbre() {
        Lead lead = novoLead();
        String token = novoToken(lead);
        Task tarefa = [SELECT Id FROM Task WHERE WhoId = :lead.Id WITH SYSTEM_MODE];
        Database.update(new Task(Id = tarefa.Id, Expira_Em__c = Datetime.now().addDays(-1)), AccessLevel.SYSTEM_MODE);

        System.assertEquals('invalido', abrir(token).estado);
    }

    @IsTest
    static void envioValidoConcluiTarefaEAtualizaLead() {
        Lead lead = novoLead();
        ContatoInicialController c = abrir(novoToken(lead));
        preencher(c);

        c.enviar();

        System.assertEquals('sucesso', c.estado, c.ultimaFalha == null ? 'ok' : c.ultimaFalha);
        Task tarefa = [SELECT Status, Resultado_Contato__c FROM Task WHERE WhoId = :lead.Id WITH SYSTEM_MODE];
        System.assertEquals('Completed', tarefa.Status);
        System.assertEquals('Contatado com sucesso', tarefa.Resultado_Contato__c);
        Lead atualizado = [
            SELECT Status, CNPJ__c, Porte__c, Segmento_CNAE__c, Phone, WhatsApp__c, Title,
                Consentimento_LGPD__c, Consentimento_Data__c
            FROM Lead
            WHERE Id = :lead.Id
            WITH SYSTEM_MODE
        ];
        System.assertEquals('Working - Contacted', atualizado.Status);
        System.assertEquals('11222333000181', atualizado.CNPJ__c);
        System.assertEquals('ME', atualizado.Porte__c);
        System.assertEquals('Diretora Comercial', atualizado.Title);
        System.assert(atualizado.Consentimento_LGPD__c);
        System.assertNotEquals(null, atualizado.Consentimento_Data__c);
    }

    @IsTest
    static void linkNaoPodeSerUsadoDuasVezes() {
        Lead lead = novoLead();
        String token = novoToken(lead);
        ContatoInicialController primeiro = abrir(token);
        preencher(primeiro);
        primeiro.enviar();
        System.assertEquals('sucesso', primeiro.estado, primeiro.ultimaFalha == null ? 'ok' : primeiro.ultimaFalha);

        System.assertEquals('invalido', abrir(token).estado);
    }

    @IsTest
    static void cnpjInvalidoNaoSalva() {
        Lead lead = novoLead();
        ContatoInicialController c = abrir(novoToken(lead));
        preencher(c);
        c.cnpj = '11222333000182';

        c.enviar();

        System.assertEquals('form', c.estado);
        System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR));
        System.assertEquals('Open - Not Contacted', [SELECT Status FROM Lead WHERE Id = :lead.Id WITH SYSTEM_MODE].Status);
        System.assertEquals('Waiting on someone else', [SELECT Status FROM Task WHERE WhoId = :lead.Id WITH SYSTEM_MODE].Status);
    }

    @IsTest
    static void semConsentimentoNaoSalva() {
        Lead lead = novoLead();
        ContatoInicialController c = abrir(novoToken(lead));
        preencher(c);
        c.consentimento = false;

        c.enviar();

        System.assertEquals('form', c.estado);
        System.assertEquals('Open - Not Contacted', [SELECT Status FROM Lead WHERE Id = :lead.Id WITH SYSTEM_MODE].Status);
    }

    @IsTest
    static void camposObrigatoriosVazios() {
        Lead lead = novoLead();
        ContatoInicialController c = abrir(novoToken(lead));
        c.consentimento = true;
        c.cnpj = null;

        c.enviar();

        System.assertEquals('form', c.estado);
        System.assert(ApexPages.getMessages().size() >= 3);
    }
}
