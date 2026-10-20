public without sharing class ContatoInicialController {

    public String estado { get; private set; }
    public String nomeContato { get; private set; }
    public String empresa { get; private set; }

    public String cnpj { get; set; }
    public String porte { get; set; }
    public String segmento { get; set; }
    public String telefone { get; set; }
    public String whatsapp { get; set; }
    public String cargo { get; set; }
    public Boolean consentimento { get; set; }

    private String token;
    private Id tarefaId;
    private Id leadId;
    private Boolean preenchido = false;

    @TestVisible
    private String ultimaFalha;

    public ContatoInicialController() {
        token = ApexPages.currentPage().getParameters().get('t');
        consentimento = false;
        carregar();
    }

    public Boolean getTemErros() {
        return ApexPages.hasMessages(ApexPages.Severity.ERROR);
    }

    public List<SelectOption> getPortes() {
        List<SelectOption> opcoes = new List<SelectOption>{ new SelectOption('', 'Selecione') };
        for (Schema.PicklistEntry p : Lead.Porte__c.getDescribe().getPicklistValues()) {
            if (p.isActive()) {
                opcoes.add(new SelectOption(p.getValue(), p.getLabel()));
            }
        }
        return opcoes;
    }

    public PageReference enviar() {
        if (!carregar()) {
            return null;
        }
        if (!validar()) {
            estado = 'form';
            return null;
        }

        Savepoint ponto = Database.setSavepoint();
        try {
            Database.update(
                new Task(Id = tarefaId, Status = 'Completed', Resultado_Contato__c = 'Contatado com sucesso'),
                AccessLevel.SYSTEM_MODE
            );

            Lead lead = [SELECT Id, Status FROM Lead WHERE Id = :leadId WITH SYSTEM_MODE];
            lead.CNPJ__c = Documentos.somenteDigitos(cnpj);
            lead.Porte__c = porte;
            lead.Segmento_CNAE__c = recortar(segmento, 80);
            lead.Phone = recortar(telefone, 40);
            lead.WhatsApp__c = recortar(whatsapp, 40);
            lead.Title = recortar(cargo, 128);
            lead.Consentimento_LGPD__c = true;
            lead.Consentimento_Data__c = Datetime.now();
            if (lead.Status == 'Open - Not Contacted') {
                lead.Status = 'Working - Contacted';
            }
            Database.update(lead, AccessLevel.SYSTEM_MODE);
        } catch (Exception e) {
            ultimaFalha = e.getMessage();
            Database.rollback(ponto);
            erro('Não foi possível salvar agora. Tente novamente em alguns minutos.');
            estado = 'form';
            return null;
        }

        estado = 'sucesso';
        return null;
    }

    private Boolean carregar() {
        estado = 'invalido';
        if (String.isBlank(token) || token.length() != 64) {
            return false;
        }
        List<Task> tarefas = [
            SELECT Id, WhoId, Status, Expira_Em__c
            FROM Task
            WHERE Token_Acesso__c = :token AND Subject = :ContatoInicialServico.ASSUNTO
            WITH SYSTEM_MODE
            LIMIT 1
        ];
        if (tarefas.isEmpty()) {
            return false;
        }
        Task tarefa = tarefas[0];
        if (tarefa.Status == 'Completed' || tarefa.Expira_Em__c == null || tarefa.Expira_Em__c < Datetime.now()) {
            return false;
        }
        if (tarefa.WhoId == null || tarefa.WhoId.getSObjectType() != Lead.SObjectType) {
            return false;
        }

        tarefaId = tarefa.Id;
        leadId = tarefa.WhoId;
        if (!preenchido) {
            preencher();
            preenchido = true;
        }
        estado = 'form';
        return true;
    }

    private void preencher() {
        Lead lead = [
            SELECT FirstName, LastName, Company, Phone, WhatsApp__c, Title, CNPJ__c, Porte__c, Segmento_CNAE__c
            FROM Lead
            WHERE Id = :leadId
            WITH SYSTEM_MODE
        ];
        nomeContato = String.isBlank(lead.FirstName) ? lead.LastName : lead.FirstName;
        empresa = lead.Company;
        cnpj = lead.CNPJ__c;
        porte = lead.Porte__c;
        segmento = lead.Segmento_CNAE__c;
        telefone = lead.Phone;
        whatsapp = lead.WhatsApp__c;
        cargo = lead.Title;
    }

    private Boolean validar() {
        Boolean ok = true;
        if (!Documentos.cnpjValido(cnpj)) {
            erro('Informe um CNPJ válido.');
            ok = false;
        }
        if (String.isBlank(porte)) {
            erro('Selecione o porte da empresa.');
            ok = false;
        }
        if (String.isBlank(segmento)) {
            erro('Informe o segmento de atuação.');
            ok = false;
        }
        if (consentimento != true) {
            erro('É necessário aceitar o tratamento dos dados para continuar.');
            ok = false;
        }
        return ok;
    }

    private static String recortar(String valor, Integer tamanho) {
        return String.isBlank(valor) ? null : valor.trim().left(tamanho);
    }

    private static void erro(String mensagem) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, mensagem));
    }
}
