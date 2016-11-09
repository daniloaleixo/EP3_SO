
# ************************************

  # EP3 - Sistemas Operacionais
  # Prof. Daniel Batista

  # Danilo Aleixo Gomes de Souza
  # n USP: 7972370

  # Carlos Augusto Motta de Lima
  # n USP: 7991228

# *************************************





#
# Classe usada para identificar as informacoes de cada celula da lista encadeada
# de segmentos de memoria 
#
class VMemorySegment
  attr_accessor :initial_page_position, :size, :pid, :prox

  def initialize(initial_page_position, size, pid, prox)
    @initial_page_position = initial_page_position
    @size = size
    @pid = pid
    @prox = prox
  end
end
