# ************************************

  # EP3 - Sistemas Operacionais
  # Prof. Daniel Batista

  # Danilo Aleixo Gomes de Souza
  # n USP: 7972370

  # Carlos Augusto Motta de Lima
  # n USP: 7991228

# *************************************

#
# Para lidar com os eventos no tempo, usamos uma hash chamada “time_events_list”
#
# Esse hash tem como chave o t0 de cada evento que irá ocorrer no sistema e como 
# valor tem um array de objetos TimeEvent, que têm como informações:
# 
#   to              ->    tempo inicial da entrada do evento
#   mode            ->    qual será o evento que irá ocorrer
#   process_name    ->    nome do processo
#   number_of_bytes ->    numero de bytes do processo
#   PID             ->    pid do processo
#   memory_position ->    posição de memória acessada
#
# Ordenamos a hash "time_events_list" pelas chaves. Assim, estando no instante
# de tempo Tn, acessaamos a hash na chave Tn e executamos os eventos.
#
class TimeManager
  attr_accessor :time_events_list

  # Constrói a hash de eventos a serem executados
  def initialize(trace_lines)
    @time_events_list = Hash.new { |h, k| h[k] = [] }
    
    trace_lines.each do |trace_line|
      add_process = TimeEvent.new(mode: :add_process, t0: trace_line.t0,
                                  process_name: trace_line.process_name,
                                  number_of_bytes: trace_line.number_of_bytes,
                                  pid: trace_line.pid)
      @time_events_list[trace_line.t0] << add_process

      remove_process = TimeEvent.new(mode: :remove_process,
                                     t0: trace_line.tf,
                                     pid: trace_line.pid)
      @time_events_list[trace_line.tf] << remove_process

      trace_line.memory_accesses.each do |memory_access|
        access = TimeEvent.new(mode: :memory_access, t0: memory_access.last,
                               memory_position: memory_access.first,
                               pid: trace_line.pid)
        @time_events_list[memory_access.last] << access
      end
    end
  end
end
