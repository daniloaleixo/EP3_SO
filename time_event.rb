

# O objeto TimeEvent pode ter 3 tipos de evento:
#    Adicionar Processo
#    Remover Processo
#    Acessar Memória
# E para cada tipo de evento temos uma interação diferente
#
# Assim podemos ordenar o hash (time_events_list) pelas chaves, e portanto para cada 
# segundo que se passa no sistema, vamos supor que estamos no tempo Tn, podemos
# acessamos a hash com a chave Tn e simplesmente executar os eventos.
#
# Para algoritmos que precisamos saber se a página na memória esta sendo usada,
# basta que voltemos no passado, por exemplo acessar a chave (Tn – 3) e atualizar
# as páginas dizendo se foram ou não acessadas.

class TimeEvent
  attr_accessor :t0, :mode, :process_name, :number_of_bytes,
                :pid, :memory_position

  def initialize(opts={})
    @t0 = opts[:t0] unless opts[:t0].nil?
    @mode = opts[:mode] unless opts[:mode].nil?
    @process_name = opts[:process_name] unless opts[:process_name].nil?
    @number_of_bytes = opts[:number_of_bytes] unless opts[:number_of_bytes].nil?
    @pid = opts[:pid] unless opts[:pid].nil?
    @memory_position = opts[:memory_position] unless opts[:memory_position].nil?
  end
end
