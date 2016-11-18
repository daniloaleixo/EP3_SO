# ************************************

  # EP3 - Sistemas Operacionais
  # Prof. Daniel Batista

  # Danilo Aleixo Gomes de Souza
  # n USP: 7972370

  # Carlos Augusto Motta de Lima
  # n USP: 7991228

# *************************************

#
# Estrutura que representa uma página de memória virtual.
#    on_physical: true se a página está na memória física, false caso contrário
#  recently_used: true se a página foi usada recentemente, false caso contrário
# physical_index: índice do quadro de página que contém esta página
#            pid: PID do processo que está ocupando essa página (mesmo que o
#                 processo não precise da página inteira, ele vai ocupá-la
#                 exclusivamente para ele - conforme dito pelo professor no
#                 PACA)
#                 
#
class MemoryPage
  attr_accessor :on_physical, :recently_used, :physical_index, :r,
                :pid
  
  def initialize
    @pid = -1
    @on_physical = false
    @recently_used = false
    @physical_index = -1
    @r = 1
  end
end
