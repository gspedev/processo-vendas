public without sharing class ContatoInicialServico {

    public static final String ASSUNTO = 'Contato Inicial';
    public static final String NOME_SITE = 'contato_inicial';
    private static final Integer VALIDADE_DIAS = 7;
    private static final String QUEBRA = '\n';

    @TestVisible
    private static String urlBaseTeste;

    public class Entrada {
        @InvocableVariable(required=true)
        public Id leadId;
    }

    public class Saida {
        @InvocableVariable
        public Boolean sucesso;
        @InvocableVariable
        public String mensagem;
        @InvocableVariable
        public String link;
        @InvocableVariable
        public String email;
        @InvocableVariable
        public String nome;
    }

    @InvocableMethod(label='Preparar contato inicial')
    public static List<Saida> preparar(List<Entrada> entradas) {
        Set<Id> ids = new Set<Id>();
        for (Entrada e : entradas) {
            ids.add(e.leadId);
        }
        Map<Id, Lead> leads = new Map<Id, Lead>(
            [SELECT Id, FirstName, LastName, Company, Email FROM Lead WHERE Id IN :ids WITH SYSTEM_MODE]
        );
        String base = urlBase();

        List<Task> novas = new List<Task>();
        List<Saida> saidas = new List<Saida>();
        Map<Integer, Lead> leadPorSaida = new Map<Integer, Lead>();
        for (Entrada e : entradas) {
            Lead lead = leads.get(e.leadId);
            Saida s = new Saida();
            if (lead == null || String.isBlank(lead.Email)) {
                s.sucesso = false;
                s.mensagem = 'O lead precisa ter um e-mail cadastrado.';
            } else if (String.isBlank(base)) {
                s.sucesso = false;
                s.mensagem = 'O site de contato ainda não está configurado.';
            } else {
                Task tarefa = new Task(
                    WhoId = lead.Id,
                    Subject = ASSUNTO,
                    Status = 'Waiting on someone else',
                    ActivityDate = Date.today().addDays(VALIDADE_DIAS),
                    Token_Acesso__c = gerarToken(),
                    Expira_Em__c = Datetime.now().addDays(VALIDADE_DIAS),
                    OwnerId = UserInfo.getUserId()
                );
                novas.add(tarefa);
                s.sucesso = true;
                s.link = base + '?t=' + tarefa.Token_Acesso__c;
                s.email = lead.Email;
                s.nome = String.isBlank(lead.FirstName) ? lead.LastName : lead.FirstName;
                leadPorSaida.put(saidas.size(), lead);
            }
            saidas.add(s);
        }

        Savepoint ponto = Database.setSavepoint();
        try {
            encerrarAbertas(ids);
            Database.insert(novas, AccessLevel.SYSTEM_MODE);
            enviarEmails(saidas, leadPorSaida);
        } catch (Exception e) {
            Database.rollback(ponto);
            for (Saida s : saidas) {
                if (s.sucesso == true) {
                    s.sucesso = false;
                    s.mensagem = 'Não foi possível enviar o e-mail agora. Tente novamente mais tarde.';
                }
            }
        }
        return saidas;
    }

    private static void enviarEmails(List<Saida> saidas, Map<Integer, Lead> leadPorSaida) {
        String remetente = UserInfo.getName();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Integer i = 0; i < saidas.size(); i++) {
            Saida s = saidas[i];
            if (s.sucesso != true) {
                continue;
            }
            String empresa = leadPorSaida.get(i).Company;
            Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
            m.setToAddresses(new List<String>{ s.email });
            m.setSubject(s.nome + ', vamos continuar nossa conversa?');
            m.setHtmlBody(corpoHtml(s, empresa, remetente));
            m.setPlainTextBody(corpoTexto(s, empresa, remetente));
            m.setSaveAsActivity(false);
            emails.add(m);
        }
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }

    private static String corpoHtml(Saida s, String empresa, String remetente) {
        String link = s.link.escapeHtml4();
        String quem = remetente.escapeHtml4();
        return '<div style="font-family:Arial,Helvetica,sans-serif;font-size:15px;color:#1f2d3d;max-width:560px">'
            + '<p>Olá, ' + s.nome.escapeHtml4() + '.</p>'
            + '<p>Aqui é ' + quem + ', da GTech. Para seguirmos com a ' + String.valueOf(empresa).escapeHtml4()
            + ', preciso confirmar alguns dados da sua empresa. Leva menos de um minuto.</p>'
            + '<p style="margin:24px 0"><a href="' + link + '" style="background:#385da9;color:#ffffff;'
            + 'text-decoration:none;padding:12px 22px;border-radius:8px;font-weight:bold">Preencher meus dados</a></p>'
            + '<p style="font-size:13px;color:#52606d">O link vale por ' + VALIDADE_DIAS
            + ' dias. Se o botão não abrir, copie este endereço:<br>' + link + '</p>'
            + '<p>Abraço,<br>' + quem + '<br>GTech</p></div>';
    }

    private static String corpoTexto(Saida s, String empresa, String remetente) {
        return 'Olá, ' + s.nome + '.' + QUEBRA + QUEBRA
            + 'Aqui é ' + remetente + ', da GTech. Para seguirmos com a ' + empresa
            + ', preciso confirmar alguns dados da sua empresa. Leva menos de um minuto:' + QUEBRA + QUEBRA
            + s.link + QUEBRA + QUEBRA
            + 'O link vale por ' + VALIDADE_DIAS + ' dias.' + QUEBRA + QUEBRA
            + 'Abraço,' + QUEBRA + remetente + QUEBRA + 'GTech';
    }

    private static void encerrarAbertas(Set<Id> leadIds) {
        List<Task> abertas = [
            SELECT Id
            FROM Task
            WHERE WhoId IN :leadIds AND Subject = :ASSUNTO AND Status != 'Completed' AND Token_Acesso__c != NULL
            WITH SYSTEM_MODE
        ];
        for (Task t : abertas) {
            t.Status = 'Deferred';
            t.Token_Acesso__c = null;
        }
        Database.update(abertas, AccessLevel.SYSTEM_MODE);
    }

    private static String gerarToken() {
        return EncodingUtil.convertToHex(Crypto.generateAesKey(256));
    }

    private static String urlBase() {
        if (urlBaseTeste != null) {
            return urlBaseTeste;
        }
        List<Site> sites = [SELECT Id FROM Site WHERE Name = :NOME_SITE LIMIT 1];
        if (sites.isEmpty()) {
            return null;
        }
        List<SiteDetail> detalhes = [SELECT SecureURL FROM SiteDetail WHERE DurableId = :sites[0].Id LIMIT 1];
        return detalhes.isEmpty() ? null : detalhes[0].SecureURL;
    }
}
