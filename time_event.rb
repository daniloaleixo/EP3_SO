# ************************************

  # EP3 - Sistemas Operacionais
  # Prof. Daniel Batista

  # Danilo Aleixo Gomes de Souza
  # n USP: 7972370

  # Carlos Augusto Motta de Lima
  # n USP: 7991228

# *************************************

# O objeto TimeEvent pode ser um entre três tipos de evento, o que determina o
# modo como será processado o evento:
#    Adicionar Processo
#    Remover Processo
#    Acessar Memória
#
# Para algoritmos que precisam saber se a página na memória esta sendo usada,
# basta que voltemos no passado, por exemplo acessar a chave (Tn – 3) e
# atualizar as páginas dizendo se foram ou não acessadas.

class TimeEvent
  attr_accessor :mode, :process, :memory_position, :access_time

  def initialize(opts={})
    @process = opts[:process]
    @mode = opts[:mode]
    @memory_position = opts[:memory_position]
    @access_time = opts[:access_time]
  end
end
