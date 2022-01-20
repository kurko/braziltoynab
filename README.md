# BrazilToYnab

Este é um conjunto de scripts para ler dados de transações e importar no YNAB
(já que estamos em 2021 e ainda não temos openbanking no Brasil). YNAB é o app
[YouNeedABudget](youneedabudget.com).

| Plataformas suportadas                | ID de plataforma |
|---------------------------------------|------------------|
| - Cartões Porto Seguro: arquivos .xls | PORTOSEGURO      |

## Uso

1. Você precisa de Ruby na sua máquina local (Unix/MacOS).
1. Download: faça um `git clone` do repositório.
1. Configuração do YNAB: você precisa configurar o `API_TOKEN` do YNAB na sua
   máquina. Define a seguinte variável de ambiente:

   ```
   YNAB_ACCESS_TOKEN="escreva-aqui-o-seu-token-do-ynab"
   ```

   Você gera esse token na configurações de conta do seu YNAB.

1. Configuração de contas: agora você precisa criar as variáveis de ambiente que vão
   relacionar dados exportados do seu banco com as contas do YNAB.

   A lógica segue o formato:

   ```
   export BRAZILTOYNAB_${ID_DA_PLATAFORMA}_BUDGET="id-do-budget"
   export BRAZILTOYNAB_${ID_DA_PLATAFORMA}_${ULTIMOS_4_DIGITOS_DO_CARTAO}_ACCOUNT_ID="id-da-conta"
   ```

   Por exemplo, se você está usando `Porto Seguro` (ver ID na tabela acima) e o
   seu arquivo XLS exportado do site portoseguro.com.br (portal do cliente) tem
   os cartões com final `1234` e `5678` (eles aparecem como cabeçalho no
   arquivo), então configure as variáveis da seguinte forma:

   ```
   export BRAZILTOYNAB_PORTOSEGURO_BUDGET="id-do-budget"
   export BRAZILTOYNAB_PORTOSEGURO_1234_ACCOUNT_ID="id-da-conta-no-ynab-pro-cartao-1234"
   export BRAZILTOYNAB_PORTOSEGURO_5678_ACCOUNT_ID="id-da-conta-no-ynab-pro-cartao-5678"
   ```

   Outras variáveis de ambiente:

   - `BRAZILTOYNAB_${PLATAFORMA}_${cartao}_MEMO_PREFIX="Um prefixo: "`: se você
   quer que todas as transações desse cartão tenham um determinado prefixo no
   campo Memo no YNAB.

   Eu acho útil colocar os cartões todos na mesma conta do YNAB, e diferenciar
   eles por um prefixo no campo memo. Assim um único pagamento de fatura (uma transação)
   cobre os cartão adicionais. Se você colocar todos na mesma conta, vai precisa
   diferenciá-los de alguma forma. Se você prefere colocar cada cartão em uma
   conta separada, talvez não precise dessa configuração.

1. Executando: para sincronizar o XLS com YNAB, rode `bin/sync $NOME_DO_ARQUIVO`.

    Por exemplo, no Porto Seguro é gerado um arquivo com a data da próxima
    fatura e portanto você roda o script da seguinte forma:

    ```
    bin/sync Fatura20220220.xls
    ```

    Você pode passar opções como `bin/sync Fatura20220220.xls --override-memo`.
    Abaixo as opções suportadas:

    - `--override-memo`: com isso, os memos das transação vão ser sobrescritas,
    mesmo que já tenha editado elas no YNAB depois de uma importação anterior.
    Por exemplo, isto é útil caso você queira ajustar um prefixo de memo
    retroativamente. Lembre-se que todas as edições de memo que você fez nas
    transações do arquivo XLS serão perdidas e substituídas.


