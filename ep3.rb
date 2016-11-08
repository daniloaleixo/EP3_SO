#!/usr/bin/env ruby

require './lib'

# variavel que contem as linhas do arquivo de trace
trace_file = nil
# a variavel contem um hash onde os PIDs estao conectados com seus respectivos nomes do processo
pid_dictionary = {}
# lista encadeada de segmentos de memoria virtual
memory_segments_list = nil

# varias para lidar com os tipos de algoritmos, tanto de substituicao de pagina,
# quanto de gerenciamento de espaco livre
memory_management_mode = 1
page_replacement_mode = 1

loop do
  print "[ep3]: "
  # pega a linha de comando escrita pelo usuario
  option = gets.strip.split(" ")

  case option.shift
  when "sai" then break
  when "carrega"
    # carrega as linhas do arquivo de trace e as armazena num vetor
    file_lines = FileManager.read_trace_file(option.first)

    # extrai os dados do vetor de linhas do arquivo de trace e armazena num
    # objeto TraceFileData
    trace_file = TraceFileData.new(file_lines, pid_dictionary)

    TimeManager.build_time_events_list(trace_file.lines)

    # Inicializa as estruturas de dados 
    total_virtual_pages = trace_file.virtual / 16
    total_physical_frame_pages = trace_file.total / 16
    memory_segments_list = MemoryManager.start(total_virtual_pages,
                                               total_physical_frame_pages)
    MemoryManager.update_memory_files
    
  when "espaco"
    memory_management_mode = option.first.to_i

  when "substitui"
    page_replacement_mode = option.first.to_i
    
  when "executa"
    # coloca os processos 'em execução'
    print_interval = (option.first or 1).to_i

    for i in 0..TimeManager.time_events_list.keys.sort.last do
      initiate_time_counter = Time.now

      MemoryManager.print_everything(memory_segments_list, i) if i % print_interval == 0
      
      # o fluxo abaixo reseta os bits R (recently_used) de todas as páginas
      # a cada 3 segundos
      # 3 segundos foi um valor arbitrário escolhido por nós para tentar
      # manter a informação do bit R nem por muito tempo e nem por pouco demais.
      MemoryManager.reset_bit_r_from_pages if i % 3 == 0

      # lemos cada objeto TimeEvent que tem como chave o segundo em que esta o sistema, portanto 
      # supondo que estamos no segundo Tn, temos que executar todos os eventos na hash que tenham 
      # a chave Tn
      TimeManager.time_events_list[i].each do |time_event|
        case time_event.mode
        when :add_process
          # A funcao usa o algoritmo de gerencia de memoria livre de acordo com o que o usuario escolheu
          initial_page_position = MemoryManager.memory_management_algorithm(memory_segments_list,
                                                                            memory_management_mode,
                                                                            time_event.number_of_bytes)
          params = { memory_segments_list: memory_segments_list,
                     pid: time_event.pid,
                     name: time_event.process_name,
                     size: (time_event.number_of_bytes / 16.0).ceil,
                     initial_page_position: initial_page_position,
                     pid_dictionary: pid_dictionary }
          memory_segments_list = MemoryManager.add_process_to_list(params)
        when :remove_process
          MemoryManager.remove_segment_from_list(memory_segments_list,
                                                 time_event.pid,
                                                 pid_dictionary)
        when :memory_access
          MemoryManager.memory_access(time_event.pid,
                                      memory_segments_list,
                                      time_event.memory_position,
                                      page_replacement_mode)
        end
        # atualiza os arquivos binarios
        MemoryManager.update_memory_files
      end
      time_elapsed = Time.now - initiate_time_counter
      # dorme até chegarmos ao próximo segundo
      sleep(1 - time_elapsed)
    end

    MemoryManager.print_everything(memory_segments_list, -1)
    # reinicializa as variaveis para cada execucao
    trace_file = nil
    pid_dictionary = {}
    memory_segments_list = nil

    MemoryManager.clean     
  else
    print "Comando inválido\n"
    print "Comandos: \ncarrega <arquivo>: \tcarrega arquivo para a simulação\n"
    print "espaco <num>: \t\tinforma ao simulador que ele sera executado com o algoritmo de gerenciamento",
    " de espaco livre de número:\n\t\t1 - First Fit\n\t\t2 - Next Fit\n\t\t3 - Best Fit\n\t\t4 - Worst Fit\n"
    print "substitui <num>: \t\tinforma ao simulador que ele sera executado com o algoritmo de substituição",
    " de páginas de número:\n\t\t1 - Optimal\n\t\t2 - Second-Chance\n\t\t3 - Clock\n\t\t4 - Least Recently Used\n"
    print "executa <intervalo>: \t\texecuta o simulador e imprime o estado de memorias na tela de <intervalo>",
    " em <intervalo> segundos\n"
    print "sai \t\tfinaliza o simulador"
    print "\n"
end
end

