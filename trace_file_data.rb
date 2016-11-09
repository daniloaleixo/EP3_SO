

# ************************************

  # EP3 - Sistemas Operacionais
  # Prof. Daniel Batista

  # Danilo Aleixo Gomes de Souza
  # n USP: 7972370

  # Carlos Augusto Motta de Lima
  # n USP: 7991228

# *************************************










class TraceFileData
  attr_accessor :total, :virtual, :lines

  #
  # A funcao recebe como entrada o vetor de linhas, onde cada elemento do vetor eh uma linha do arquivo
  # de trace e separa as informacoes necessarias, como memoria virtual e total, em seguida
  # cria um objeto TraceLine para cada linha de processo
  #
  def initialize(file_lines, pid_dictionary)
    total_and_virtual = file_lines.shift.split(" ")
    @total = total_and_virtual.first.to_i
    @virtual = total_and_virtual.last.to_i

    @lines = []
    file_lines.each do |line|
      @lines << TraceLine.new(line, pid_dictionary)
    end
  end
end