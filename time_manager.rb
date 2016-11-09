
# ************************************

  # EP3 - Sistemas Operacionais
  # Prof. Daniel Batista

  # Danilo Aleixo Gomes de Souza
  # n USP: 7972370

  # Carlos Augusto Motta de Lima
  # n USP: 7991228

# *************************************





#
# Para manipular o tempo usamos uma hash chamada “time_events_list”
#
# Esse hash tem como chave o t0 de cada evento que irá ocorrer no sistema e como 
# valor tem um objeto chamado TimeEvent, que tem como informações: to → tempo 
# inicial da entrada do evento; mode → qual será o evento que irá ocorrer; 
# process_name → nome do processo; 
# number_of_bytes → numero de bytes do processo;
# PID → pid do processo; memory_position → posição de memória acessada.
#
# Assim podemos ordenar o hash (time_events_list) pelas chaves, e portanto para cada 
# segundo que se passa no sistema, vamos supor que estamos no tempo Tn, podemos
# acessamos a hash com a chave Tn e simplesmente executar os eventos.
#
class TimeManager

  def self.time_events_list
    @@time_events_list
  end

  def self.build_time_events_list(trace_lines)
    @@time_events_list = Hash.new { |h, k| h[k] = [] }
    
    trace_lines.each do |trace_line|
      @@time_events_list[trace_line.t0] << TimeEvent.new(mode: :add_process,
                                                         t0: trace_line.t0,
                                                         process_name: trace_line.process_name,
                                                         number_of_bytes: trace_line.number_of_bytes,
                                                         pid: trace_line.pid)
      @@time_events_list[trace_line.tf] << TimeEvent.new(mode: :remove_process,
                                                         t0: trace_line.tf,
                                                         pid: trace_line.pid)
      trace_line.memory_accesses.each do |memory_access|
        @@time_events_list[memory_access.last] << TimeEvent.new(t0: memory_access.last,
                                                                 memory_position: memory_access.first,
                                                                 pid: trace_line.pid,
                                                                 mode: :memory_access)
      end
    end
  end
end