@IsTest
private class DocumentosTest {

    @IsTest
    static void cnpjValido() {
        System.assert(Documentos.cnpjValido('11222333000181'));
        System.assert(Documentos.cnpjValido('11.222.333/0001-81'));
    }

    @IsTest
    static void cnpjInvalido() {
        System.assert(!Documentos.cnpjValido(null));
        System.assert(!Documentos.cnpjValido('123'));
        System.assert(!Documentos.cnpjValido('11222333000182'));
        System.assert(!Documentos.cnpjValido('00000000000000'));
    }

    @IsTest
    static void cpfValidoEInvalido() {
        System.assert(Documentos.cpfValido('529.982.247-25'));
        System.assert(!Documentos.cpfValido('52998224726'));
        System.assert(!Documentos.cpfValido('11111111111'));
        System.assert(!Documentos.cpfValido(null));
    }

    @IsTest
    static void somenteDigitos() {
        System.assertEquals('11222333000181', Documentos.somenteDigitos('11.222.333/0001-81'));
        System.assertEquals(null, Documentos.somenteDigitos(null));
    }
}
