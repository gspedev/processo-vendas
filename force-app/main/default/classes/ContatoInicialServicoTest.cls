@IsTest
private class ContatoInicialServicoTest {

    private static ContatoInicialServico.Entrada entrada(Id leadId) {
        ContatoInicialServico.Entrada e = new ContatoInicialServico.Entrada();
        e.leadId = leadId;
        return e;
    }

    @IsTest
    static void criaTarefaComTokenELink() {
        ContatoInicialServico.urlBaseTeste = 'https://exemplo.test/contato';
        Lead lead = new Lead(FirstName = 'Ana', LastName = 'Silva', Company = 'Empresa Teste', Email = 'ana@example.com');
        insert lead;

        List<ContatoInicialServico.Saida> saidas = ContatoInicialServico.preparar(
            new List<ContatoInicialServico.Entrada>{ entrada(lead.Id) }
        );

        System.assert(saidas[0].sucesso);
        System.assertEquals(1, Limits.getEmailInvocations());
        System.assertEquals('ana@example.com', saidas[0].email);
        System.assertEquals('Ana', saidas[0].nome);
        Task tarefa = [
            SELECT Subject, Status, Token_Acesso__c, Expira_Em__c
            FROM Task
            WHERE WhoId = :lead.Id
            WITH SYSTEM_MODE
        ];
        System.assertEquals('Contato Inicial', tarefa.Subject);
        System.assertEquals('Waiting on someone else', tarefa.Status);
        System.assertEquals(64, tarefa.Token_Acesso__c.length());
        System.assert(tarefa.Expira_Em__c > Datetime.now());
        System.assertEquals('https://exemplo.test/contato?t=' + tarefa.Token_Acesso__c, saidas[0].link);
    }

    @IsTest
    static void reenvioInvalidaTokenAnterior() {
        ContatoInicialServico.urlBaseTeste = 'https://exemplo.test/contato';
        Lead lead = new Lead(LastName = 'Silva', Company = 'Empresa Teste', Email = 'silva@example.com');
        insert lead;

        ContatoInicialServico.preparar(new List<ContatoInicialServico.Entrada>{ entrada(lead.Id) });
        ContatoInicialServico.preparar(new List<ContatoInicialServico.Entrada>{ entrada(lead.Id) });

        List<Task> tarefas = [SELECT Status, Token_Acesso__c FROM Task WHERE WhoId = :lead.Id WITH SYSTEM_MODE];
        System.assertEquals(2, tarefas.size());
        Integer comToken = 0;
        for (Task t : tarefas) {
            if (t.Token_Acesso__c != null) {
                comToken++;
                System.assertEquals('Waiting on someone else', t.Status);
            } else {
                System.assertEquals('Deferred', t.Status);
            }
        }
        System.assertEquals(1, comToken);
    }

    @IsTest
    static void leadSemEmailNaoCriaTarefa() {
        ContatoInicialServico.urlBaseTeste = 'https://exemplo.test/contato';
        Lead lead = new Lead(LastName = 'Sem Email', Company = 'Empresa Teste');
        insert lead;

        List<ContatoInicialServico.Saida> saidas = ContatoInicialServico.preparar(
            new List<ContatoInicialServico.Entrada>{ entrada(lead.Id) }
        );

        System.assert(!saidas[0].sucesso);
        System.assertEquals(0, Limits.getEmailInvocations());
        System.assertEquals(0, [SELECT COUNT() FROM Task WHERE WhoId = :lead.Id WITH SYSTEM_MODE]);
    }

    @IsTest
    static void semSiteConfiguradoRetornaErro() {
        ContatoInicialServico.urlBaseTeste = '';
        Lead lead = new Lead(LastName = 'Silva', Company = 'Empresa Teste', Email = 'silva@example.com');
        insert lead;

        List<ContatoInicialServico.Saida> saidas = ContatoInicialServico.preparar(
            new List<ContatoInicialServico.Entrada>{ entrada(lead.Id) }
        );

        System.assert(!saidas[0].sucesso);
        System.assertEquals(0, [SELECT COUNT() FROM Task WHERE WhoId = :lead.Id WITH SYSTEM_MODE]);
    }
}
