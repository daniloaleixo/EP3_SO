
#
# Classe usada para identificar a estrutura usada em cada posicao do vetor que expressa 
# todas as paginas que estao na memoria fisica 
#
class MemoryPage
  attr_accessor :pid, :on_physical, :recently_used, :physical_index
  
  def initialize
    @pid = -1
    @on_physical = false
    @recently_used = false
    @physical_index = -1
  end
end