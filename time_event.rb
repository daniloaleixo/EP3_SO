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
  attr_accessor :t0, :mode, :process_name, :number_of_bytes,
                :pid, :memory_position

  def initialize(opts={})
    @t0 = opts[:t0]
    @mode = opts[:mode]
    @process_name = opts[:process_name]
    @number_of_bytes = opts[:number_of_bytes]
    @pid = opts[:pid]
    @memory_position = opts[:memory_position]
  end
end
