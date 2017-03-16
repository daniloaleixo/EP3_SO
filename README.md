# EP3 - Sistemas Operacionais #


## Alunos ##

* Carlos Augusto Motta de Lima nUSP: 7991228
* Danilo Aleixo Gomes de Souza nUSP: 7972370

## Problema ## 
A tarefa neste EP é implementar um simulador de gerência de memória com diversos algoritmos para gerência do espaço livre e para substituição de páginas.
O simulador de gerência de memória deve receber como entrada um arquivo de trace, em texto puro, que possui como primeira linha:
```sh
total virtual s p
```
seguida de várias linhas com o seguinte formato:
```sh
t0 nome tf b p1 t1 p2 t2 p3 t3 [pn tn]
```
total é o total de memória fı́sica que deve ser simulada, virtual é o total de memória virtual que deve ser simulada e s é o tamanho da unidade de alocação a ser considerada para a execução dos algoritmos para gerência do espaço livre. p é o tamanho da página a ser considerada para a execução dos algoritmos de substituição de página. t0 é o instante de tempo em segundos que um processo chega no sistema, nome é uma string sem espaços em branco que identifica o processo, tf é o instante de tempo no qual o processo é finalizado, b é a quantidade de memória utilizada pelo processo.
Os valores p1, t1, ... pn, tn dizem respeito às posições de memória, no espaço de endereço “local” do processo, acessadas pelo processo. p1, t1 por exemplo informa que no instante de tempo t1, a posição p1 é acessada pelo processo. 
Todos os valores no arquivo de entrada são números inteiros. 
O simulador deve finalizar sua execução assim que todos os processos do arquivo de entrada forem finalizados.
Com relação aos algoritmos para gerência do espaço livre, neste EP o simulador deve implementar os seguintes algoritmos, considerando que o controle de qual espaço está livre e qual está ocupado é feito usando bitmap:
1. First Fit
2. Next Fit
3. Best Fit
4. Worst Fit
Com relação aos algoritmos de substituição de página, neste EP o simulador deve implementar os seguintes algoritmos:
1. Optimal (nesse caso o arquivo de entrada deve ser lido antes para gerar os rótulos das páginas)
2. Second-Chance
3. Clock
4. Least Recently Used (Quarta versão)

### Interação com o simulador ###
Quando executado na linha de comando (sem parâmetros) o simulador deve fornecer o prompt:
```sh
t0 nome tf b p1 t1 p2 t2 p3 t3 [pn tn]
```
Neste prompt os seguintes comandos precisam ser implementados:
* carrega <arquivo>: carrega o arquivo de nome <arquivo> para a simulação. Pode ser tanto o caminho relativo como absoluto do arquivo;
* espaco <num>: informa ao simulador que ele será executado com o algoritmo de gerenciamento de espaço livre de número <num>, de acordo com a numeração dos algoritmos apresentada anteriormente neste documento;
* substitui <num>: informa ao simulador que ele será executado com o algoritmo de substituição de páginas de número <num>, de acordo com a numeração dos algoritmos apresentada anteriormente neste documento;
* executa <intervalo>: executa o simulador e imprime o estado das memórias na tela de <intervalo> em <intervalo> segundos, juntamente com o conteúdo do bitmap que mantém o status da memória;
* sai: finaliza o simulador e volta para o shell do sistema operacional.
A memória deve ser simulada utilizando o arquivo /tmp/ep2.mem para a memória fı́sica e o arquivo /tmp/ep2.vir para a memória virtual. Estes arquivos devem ser criados toda vez que o simulador for inicializado e devem ter inicialmente um tamanho igual aos valores total e virtual definido no arquivo de entrada do simulador. Estes arquivos devem ser arquivos binários e devem conter inicialmente diversos valores -1 informando que toda a memória está livre para ser usada. À medida que a memória for sendo utilizada pelos processos simulados, as posições utilizadas por esses processos devem ser marcadas com números inteiros que identifiquem unicamente cada processo. Toda vez que um processo for carregado na memória ele deve escrever o número único que identifica ele (seria o equivalente ao PID no Linux) nas posições corretas dos arquivos. Toda vez que uma posição de memória for acessada, o PID também deve ser escrito nas posições corretas dos arquivos.
Em todos os momentos da simulação sempre haverá espaço na memória virtual suficiente para a soma dos tamanhos de todos os processos em execução nesses momentos.


## Instalação ## 
Para rodar o EP, basta dar permissão de execução para o arquivo ep3.rb.
Para isto, basta rodar o comando make.
```sh
make
```
Em seguida, basta executar diretamente através do comando:
```sh
./ep3.rb
```
## Ruby ##
Este EP foi desenvolvido em Ruby, na versão 2.2.3p173
Certifique-se de que a versão instalada é essa.

Na ausência do Ruby 2.2.3p173, siga os passos para instalá-lo:

* CASO TENHA RVM INSTALADO:
```sh
rvm install 2.2.3
rvm use 2.2.3
```
* CASO NÃO TENHA O RVM INSTALADO

	1. Faça o download do pacote através do seguinte endereço: https://cache.ruby-lang.org/pub/ruby/2.2/ruby-2.2.3.tar.gz Observação: este endereço foi retirado da página oficial do Ruby. Caso deseje fazer o download diretamente de lá, este é o endereço: https://www.ruby-lang.org/en/news/2015/08/18/ruby-2-2-3-released/ 
	2. Extraia o arquivo .tar.gz
	3. Acesse o diretório onde você extraiu o arquivo.
	4. Execute os seguintes comandos:
	```sh
	./configure
	make
	```
	5. Para confirmar se está usando a versão correta, rode o seguinte comando:
	```sh
	ruby -v
	```
Se você já estava usando uma outra versão de Ruby e a instalação da nova versão não foi bem sucedida, recomenda-se usar o pacote RVM (Ruby Version Manager). Mais informações sobre como instalá-lo e como mudar a versão do Ruby neste link: https://rvm.io/

## Execução ## 
O EP deve ser executado conforme descrito no enunciado. Algumas observações:

1. o valor padrão para algoritmo de gerência de memória ou para algoritmo de substituição de página é 1. Ou seja, se você tentar "executar <intervalo>"
no EP sem usar os comandos "espaco <numero>" ou "substituicao <numero>" antes, ele usará os algoritmos de número 1 (ou seja, First Fit e Optimal) 
2. para cada vez que você rodar o comando "executa <intervalo>", no fim da execução o programa limpará tudo o que foi carregado com a instrução "carrega <arquivo>". Logo, você deverá usar "carrega <arquivo>" antes de cada chamada de "executa <intervalo>"
3. se você usar a instrução "executa <intervalo>" sem passar nenhum valor para intervalo, o programa vai imprimir os dados solicitados a cada segundo
