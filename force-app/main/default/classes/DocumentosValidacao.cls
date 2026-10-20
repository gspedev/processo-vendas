public with sharing class DocumentosValidacao {

    public static void cnpj(List<SObject> registros, Map<Id, SObject> antigos, String campo) {
        for (SObject r : registros) {
            String valor = (String) r.get(campo);
            if (String.isBlank(valor) || !mudou(r, antigos, campo)) {
                continue;
            }
            if (!Documentos.cnpjValido(valor)) {
                r.addError(campo, 'CNPJ inválido: confira os dígitos.');
            }
        }
    }

    public static void cpf(List<SObject> registros, Map<Id, SObject> antigos, String campo) {
        for (SObject r : registros) {
            String valor = (String) r.get(campo);
            if (String.isBlank(valor) || !mudou(r, antigos, campo)) {
                continue;
            }
            if (!Documentos.cpfValido(valor)) {
                r.addError(campo, 'CPF inválido: confira os dígitos.');
            }
        }
    }

    private static Boolean mudou(SObject registro, Map<Id, SObject> antigos, String campo) {
        if (antigos == null || registro.Id == null || !antigos.containsKey(registro.Id)) {
            return true;
        }
        return registro.get(campo) != antigos.get(registro.Id).get(campo);
    }
}
