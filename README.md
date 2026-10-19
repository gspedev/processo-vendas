# Processo de Vendas | GTech Vendas

Base comercial em Salesforce para o processo de vendas **B2B brasileiro**, do lead ao contrato. É o ponto de partida da org de portfólio da GTech (empresa fictícia).

## O que tem aqui

- **App Lightning "GTech Vendas"** com marca própria (cor e logo da GTech) e navegação enxuta: Home, Leads, Contas, Oportunidades, Cotações, Pedidos, Contratos e Contatos.
- **Campos B2B Brasil** em cada objeto: CNPJ (único na Conta), Razão Social, Inscrição Estadual e Municipal, CNAE, Porte, Regime Tributário, Contribuinte ICMS, CPF do contato, condição e forma de pagamento, frete, NF-e, reajuste e renovação de contrato.
- **Validation rules**: CNPJ (14 dígitos), CPF (11), chave da NF-e (44), dia de vencimento (1 a 31) e motivo obrigatório ao perder uma oportunidade.
- **Dynamic Forms** por objeto, com seções pensadas para o dia a dia comercial.
- **Permission set** `GTech_Vendas_Acesso` com acesso ao app, objetos e campos.
- Perfil Admin ajustado para esconder os apps padrão da Salesforce do App Launcher.

## Estrutura

```
force-app/main/default/
  applications/      app GTech Vendas
  contentassets/     logo
  flexipages/        Home e páginas de registro (Dynamic Forms)
  objects/           campos e validation rules de Lead, Conta, Contato,
                     Oportunidade, Cotação, Pedido e Contrato
  permissionsets/    GTech_Vendas_Acesso
  profiles/          visibilidade dos apps no perfil Admin
  settings/          Cotações habilitadas
```

## Como usar

Requer Salesforce CLI e uma Developer Edition.

```bash
sf org login web --alias minha-org
sf project deploy start -o minha-org --source-dir force-app
sf org assign permset -o minha-org --name GTech_Vendas_Acesso
```

Depois é só abrir o app **GTech Vendas** no App Launcher.

## Branches

- `main`: versão estável.
- `dev`: desenvolvimento.

## Observações

- CNPJ e CPF são guardados só com números. A validação confere formato e tamanho, não o dígito verificador.
- Todos os dados de exemplo são fictícios.
