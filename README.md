/* ********************************
    EP3 - Sistemas Operacionais
    Prof. Daniel Batista

    Danilo Aleixo Gomes de Souza
    n USP: 7972370
  
    Carlos Augusto Motta de Lima
    n USP: 7991228

********************************** */


# EP3_SO


# Explicando as estruturas de Dados

	Gerenciamento de Memória

- Memory_segment_list: É uma lista encadeada de segmentos da memoria virtual,
onde para cada elemento da lista ligada, temos um segmento que ou esta livre,
ou esta com um processo no segmento. É a estrutura que os algoritmos de
gerenciamento de espaço livre vão usar para encontrar o próximo segmento livre.
Cada célula possui as seguintes informações: posição da página inicial para este
segmento; o tamanho do segmento; o PID do processo que esta representado no
segmento; e a próxima célula.

- Memory_pages_table: É um array com todas as paginas que estarão na memoria
virtual, então para cada segmento que existe um processo em memory_segment_list
suas respectivas páginas estarão representadas nessa estrutura.
Cada célula deste array possui as seguintes informações: PID do processo
representado nesta página; se esta página está referenciada dentro da memória
física, e seu índice; e se foi usada recentemente.

- Physical_memory_page_reference: Para a memória física temos dois arrays, o
physical_memory_page_reference tem para cada quadro de página na memória física
o índice da página no array memory_pages_table.

- Physical_memory: enquanto que no physical_memory temos o PID do processo que
esta sendo executado na posição de memória. Obs: se não tiver nenhum processo
então recebe “-1” que é representado por 255, em binário 1111 1111.

	
	Manipulando eventos

- Time_events_list: Esse hash tem como chave o t0 de cada evento que irá ocorrer no sistema e como
valor tem um objeto chamado TimeEvent, que tem como informações: 
to → tempo inicial da entrada do evento; 
mode → qual será o evento que irá ocorrer;
process_name → nome do processo;
number_of_bytes → numero de bytes do processo;
PID → pid do processo; 
memory_position → posição de memória acessada.
E existem três tipos de evento:
 	Adicionar Processo
	Remover Processo
	Acessar Memória
E para cada tipo de evento temos uma interação diferente, assim podemos ordenar o hash 
(time_events_list) pelas chaves, e portanto para cada segundo que se passa no sistema, 
vamos supor que estamos no tempo Tn, podemos acessamos a hash com a chave Tn e simplesmente executar os eventos.


# Explicando a estrutura do sistema 

- lib.rb: contém todos os arquivos que são usados por ep3.rb.
- file_manager.rb : classe que lida com o acesso a arquivos
- trace_line.rb: classe que lê uma linha do arquivo de trace e guarda-a em uma estrutura 
- trace_file_data.rb : classe que lê o trace file e guarda as informações importantes memoria total, virtual e as linhas de trace (instancias de trace_line)
- time_event.rb : classe que identifica objetos que estão no hash time_events_list
- time_manager.rb : classe que monta o hash time_events_list, incluindo os objetos do tipo TimeEvent, ao passar o trace_lines para a funcao build_time_events_list
- Vmemory_segment.rb: classe que representa a estrutura de cada celula da lista encadeada que representa a memoria virtual (Memory_segment_list)
- memory_page.rb : classe que representa a estrutura de cada elemento do vetor de páginas virtuais (Memory_pages_table)
- memory_manager.rb: onde todas as funcoes de gerenciamento de memorias estao implementadas


