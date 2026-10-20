public with sharing class Documentos {

    private static final List<Integer> PESOS_CNPJ_1 = new List<Integer>{ 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2 };
    private static final List<Integer> PESOS_CNPJ_2 = new List<Integer>{ 6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2 };

    public static String somenteDigitos(String valor) {
        return valor == null ? null : valor.replaceAll('[^0-9]', '');
    }

    public static Boolean cnpjValido(String valor) {
        String cnpj = somenteDigitos(valor);
        if (cnpj == null || cnpj.length() != 14 || repetido(cnpj)) {
            return false;
        }
        Integer dv1 = digitoCnpj(cnpj, PESOS_CNPJ_1);
        Integer dv2 = digitoCnpj(cnpj, PESOS_CNPJ_2);
        return dv1 == Integer.valueOf(cnpj.substring(12, 13)) && dv2 == Integer.valueOf(cnpj.substring(13, 14));
    }

    public static Boolean cpfValido(String valor) {
        String cpf = somenteDigitos(valor);
        if (cpf == null || cpf.length() != 11 || repetido(cpf)) {
            return false;
        }
        Integer dv1 = digitoCpf(cpf, 9);
        Integer dv2 = digitoCpf(cpf, 10);
        return dv1 == Integer.valueOf(cpf.substring(9, 10)) && dv2 == Integer.valueOf(cpf.substring(10, 11));
    }

    private static Boolean repetido(String digitos) {
        return digitos.replace(digitos.substring(0, 1), '').length() == 0;
    }

    private static Integer digitoCnpj(String cnpj, List<Integer> pesos) {
        Integer soma = 0;
        for (Integer i = 0; i < pesos.size(); i++) {
            soma += Integer.valueOf(cnpj.substring(i, i + 1)) * pesos[i];
        }
        Integer resto = Math.mod(soma, 11);
        return resto < 2 ? 0 : 11 - resto;
    }

    private static Integer digitoCpf(String cpf, Integer tamanho) {
        Integer soma = 0;
        for (Integer i = 0; i < tamanho; i++) {
            soma += Integer.valueOf(cpf.substring(i, i + 1)) * (tamanho + 1 - i);
        }
        Integer resto = Math.mod(soma * 10, 11);
        return resto == 10 ? 0 : resto;
    }
}
