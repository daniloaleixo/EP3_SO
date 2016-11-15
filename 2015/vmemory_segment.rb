
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
