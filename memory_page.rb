# ************************************

  # EP3 - Sistemas Operacionais
  # Prof. Daniel Batista

  # Danilo Aleixo Gomes de Souza
  # n USP: 7972370

  # Carlos Augusto Motta de Lima
  # n USP: 7991228

# *************************************


#
# Estrutura usada em cada posicao do vetor que contém
# todas as paginas que estao na memoria fisica
#
class MemoryPage
  attr_accessor :pid, :on_physical, :recently_used, :physical_index, :r
  
  def initialize
    @pid = -1
    @on_physical = false
    @recently_used = false
    @physical_index = -1
    @r = 1
  end
end