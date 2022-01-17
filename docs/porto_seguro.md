## Baixando o arquivo

Você consegue encontrar o arquivo XLS no portal deles, em
https://cliente.portoseguro.com.br/portaldecliente/.

Não renomeie esse arquivo no seu computador porque o conteúdo dele não possui o
ano das compras. Se você está em janeiro e a compra consta como 01/01, você pode
estar olhando para uma compra parcelada do ano anterior.

Felizmente, o nome do arquivo segue o formato `Fatura20220102.xls` indicando qual é
a fatura que os itens entram. O algoritmo usa o ano no nome do arquivo (e.g
`2022`) para se orientar.

## Automatizando

Eu estou usando Keyboard Maestro para acessar o portal automaticamente, baixar o
arquivo e rodar este script. Em outras palavras, com um clique eu consigo
atualizar meu YNAB.

## Sobre o formato XLS

A Porto Seguro mantém a data original de compra. Se você está pagando a
prestação 10, a data no arquivo vai constar da prestação 1, não 10. Portanto o
algoritmo vai analisar a descrição e procurar por prestações (e.g `05/10` para
quinta prestação) e recriar a data que deve ser entrada no YNAB.
