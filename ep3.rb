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

# objeto ProcessList com informações estruturadas do arquivo de trace
process_list = nil
# objeto TimeManager com lista de eventos a serem simulados
time_manager = nil
# hash que identifica o nome do processo com determinado PID
pid_dictionary = {}

# identificador do algoritmo de gerenciamento de espaco livre
memory_management_mode = 1
# identificador do algoritmo de substituicao de pagina
page_replacement_mode = 1

# loop do
#   print "[ep3]: "
#   # pega a linha de comando escrita pelo usuario
#   got = gets
#   if got.nil?
#     print "\n"
#     break
#   end
#   option = got.strip.split(" ")

  option = ARGV

  # case option.shift
  # when "sai" then break
  # when "carrega"
    # extrai os dados do arquivo de trace e armazena num objeto ProcessList
    process_list = ProcessList.new(option.first, pid_dictionary)

    time_manager = TimeManager.new(process_list.lines)

    # Inicializa as estruturas de dados
    MemoryManager.start process_list
    
  # when "espaco"
    MemoryManager.memory_management_mode = option[1].to_i

  # when "substitui"
    if option.first.to_i == 4
      raise 'Algoritmo ainda não implementado'
      exit(0)
    end
    MemoryManager.page_replacement_mode = option[2].to_i
    
  # when "executa"
    # coloca os processos 'em execução'
    print_interval = (option[3] or 1).to_i

    # se o algoritmo for optimal precisamos construir a lista de acessos 
    # de memoria de pagina
    if MemoryManager.get_page_replacement_mode == 1
      MemoryManager.build_optimal_queue time_manager.time_events_list
    end

    # initiate_time_counter = Time.now
    for i in 0..(time_manager.time_events_list.keys.max) do
      
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
          # add_process usa o algoritmo de gerência de memória livre selecionado
          # pelo usuário (usa o first fit se nenhum for selecionado)
          MemoryManager.add_process(time_event)

        when :remove_process
          MemoryManager.remove_process(time_event, pid_dictionary)

        when :memory_access
          MemoryManager.memory_access(time_event)

        end
        # atualiza os arquivos binarios
        MemoryManager.update_memory_files
      end
      # MemoryManager.print_everything(i) if i % print_interval == 0
      MemoryManager.time_now = i

    end
    # time_elapsed = Time.now - initiate_time_counter

    # MemoryManager.print_everything(-1)
    # reinicializa as variaveis para cada execucao
    process_list = nil
    pid_dictionary = {}
    memory_segments_list = nil

    MemoryManager.clean 

    p MemoryManager.get_page_faults()

  # else
  #   print "Comando inválido\n" \
  #         "Comandos: \ncarrega <arquivo>: \tcarrega arquivo para a simulação\n" \
  #         "espaco <num>: \t\tinforma ao simulador que ele sera executado com "\
  #         "o algoritmo de gerenciamento de espaco livre de número:\n" \
  #         "\t\t1 - First Fit\n" \
  #         "\t\t2 - Next Fit\n" \
  #         "\t\t3 - Best Fit\n" \
  #         "\t\t4 - Worst Fit\n" \
  #         "\n" \
  #         "substitui <num>: \t\tinforma ao simulador que ele sera executado "\
  #         "com o algoritmo de substituição de páginas de número:\n" \
  #         "\t\t1 - Optimal\n" \
  #         "\t\t2 - Second-Chance\n" \
  #         "\t\t3 - Clock\n" \
  #         "\t\t4 - Least Recently Used\n" \
  #         "\n" \
  #         "executa <intervalo>: \t\texecuta o simulador e imprime o estado " \
  #         "de memorias na tela de <intervalo> em <intervalo> segundos\n" \
  #         "\n" \
  #         "sai: \t\tfinaliza o simulador"
  #         "\n\n"
  # end
# end

