#!/usr/bin/env ruby

# ************************************

  # EP3 - Sistemas Operacionais
  # Prof. Daniel Batista

  # Danilo Aleixo Gomes de Souza
  # n USP: 7972370

  # Carlos Augusto Motta de Lima
  # n USP: 7991228

# *************************************


require './lib'

# objeto TraceFileData com informações estruturadas do arquivo de trace
trace_file = nil
# objeto TimeManager com lista de eventos a serem simulados
time_manager = nil
# hash que identifica o nome do processo com determinado PID
pid_dictionary = {}

# identificador do algoritmo de gerenciamento de espaco livre
memory_management_mode = 1
# identificador do algoritmo de substituicao de pagina
page_replacement_mode = 1

loop do
  print "[ep3]: "
  # pega a linha de comando escrita pelo usuario
  option = gets.strip.split(" ")

  case option.shift
  when "sai" then break
  when "carrega"
    # Inicializa as estruturas de dados

    # extrai os dados do arquivo de trace e armazena num objeto TraceFileData
    trace_file = TraceFileData.new(option.first, pid_dictionary)

    time_manager = TimeManager.new(trace_file.lines)

    # qtde de páginas de memória virtual e quadros de página na memória física
    total_virtual_pages = trace_file.virtual / 16
    total_physical_frame_pages = trace_file.total / 16

    MemoryManager.start(total_virtual_pages, total_physical_frame_pages)
    
  when "espaco"
    memory_management_mode = option.first.to_i

  when "substitui"
    page_replacement_mode = option.first.to_i
    
  when "executa"
    # coloca os processos 'em execução'
    print_interval = (option.first or 1).to_i

    for i in 0..(time_manager.time_events_list.keys.max) do
      initiate_time_counter = Time.now

      MemoryManager.print_everything(i) if i % print_interval == 0
      
      # o fluxo abaixo reseta os bits R (recently_used) de todas as páginas
      # a cada 3 segundos
      # 3 segundos foi um valor arbitrário escolhido por nós para tentar
      # manter a informação do bit R nem por muito tempo e nem por pouco demais.
      MemoryManager.reset_bit_r_from_pages if i % 3 == 0

      # lemos cada objeto TimeEvent que tem como chave o segundo em que está o
      # sistema, portanto supondo que estamos no segundo Tn, temos que executar
      # todos os eventos na lista de eventos que é valor da chave Tn na hash
      time_manager.time_events_list[i].each do |time_event|
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
          memory_segments_list = MemoryManager.add_process(params)
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

