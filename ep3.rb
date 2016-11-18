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

loop do
  print "[ep3]: "
  # pega a linha de comando escrita pelo usuario
  got = gets
  if got.nil?
    print "\n"
    break
  end
  option = got.strip.split(" ")

  case option.shift
  when "sai" then break
  when "c"
    # extrai os dados do arquivo de trace e armazena num objeto ProcessList
    process_list = ProcessList.new(option.first, pid_dictionary)

    time_manager = TimeManager.new(process_list.lines)

    # Inicializa as estruturas de dados
    MemoryManager.start process_list
    
  when "s"
    MemoryManager.memory_management_mode = option.first.to_i

  when "substitui"
    MemoryManager.page_replacement_mode = option.first.to_i
    
  when "a"
    # coloca os processos 'em execução'
    print_interval = (option.first or 1).to_i

    for i in 0..(time_manager.time_events_list.keys.max) do
      initiate_time_counter = Time.now
      
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
      MemoryManager.print_everything(i) if i % print_interval == 0

      time_elapsed = Time.now - initiate_time_counter
      # dorme até chegarmos ao próximo segundo
      sleep(0.3 - time_elapsed)
    end

    MemoryManager.print_everything(-1)
    # reinicializa as variaveis para cada execucao
    process_list = nil
    pid_dictionary = {}
    memory_segments_list = nil

    MemoryManager.clean     
  else
    print "Comando inválido\n" \
          "Comandos: \ncarrega <arquivo>: \tcarrega arquivo para a simulação\n" \
          "espaco <num>: \t\tinforma ao simulador que ele sera executado com "\
          "o algoritmo de gerenciamento de espaco livre de número:\n" \
          "\t\t1 - First Fit\n" \
          "\t\t2 - Next Fit\n" \
          "\t\t3 - Best Fit\n" \
          "\t\t4 - Worst Fit\n" \
          "\n" \
          "substitui <num>: \t\tinforma ao simulador que ele sera executado "\
          "com o algoritmo de substituição de páginas de número:\n" \
          "\t\t1 - Optimal\n" \
          "\t\t2 - Second-Chance\n" \
          "\t\t3 - Clock\n" \
          "\t\t4 - Least Recently Used\n" \
          "\n" \
          "executa <intervalo>: \t\texecuta o simulador e imprime o estado " \
          "de memorias na tela de <intervalo> em <intervalo> segundos\n" \
          "\n" \
          "sai: \t\tfinaliza o simulador"
          "\n\n"
  end
end

