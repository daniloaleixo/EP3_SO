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
  def initialize(process_list)
    @time_events_list = Hash.new { |h, k| h[k] = [] }
    
    process_list.each do |process|
      add_process = TimeEvent.new(mode: :add_process, process: process)
      @time_events_list[process.t0] << add_process

      remove_process = TimeEvent.new(mode: :remove_process, process: process)
      @time_events_list[process.tf] << remove_process

      process.memory_accesses.each do |memory_access|
        access = TimeEvent.new(mode: :memory_access,
                               access_time: memory_access.last,
                               memory_position: memory_access.first,
                               process: process)
        @time_events_list[memory_access.last] << access
      end
    end
  end
end
