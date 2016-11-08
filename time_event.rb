

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

class File
  attr_accessor :name, :size, :time_created, :time_modified, :time_accessed

  def initialize(opts={})
    @name = opts[:name] unless opts[:name].nil?
    @size = opts[:size] unless opts[:size].nil?
    @time_created = opts[:time_created] unless opts[:time_created].nil?
    @time_modified = opts[:time_modified] unless opts[:time_modified].nil?
    @time_accessed = opts[:time_accessed] unless opts[:time_accessed].nil?
  end
end
