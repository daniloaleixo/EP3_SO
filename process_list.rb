# ************************************

  # EP3 - Sistemas Operacionais
  # Prof. Daniel Batista

  # Danilo Aleixo Gomes de Souza
  # n USP: 7972370

  # Carlos Augusto Motta de Lima
  # n USP: 7991228

# *************************************

class ProcessList
  attr_accessor :total, :virtual, :lines

  #
  # A funcao recebe como entrada um vetor de linhas do arquivo de trace
  # e separa as informacoes necessarias, como memoria virtual e total,
  # criando um objeto TraceLine para cada linha de processo
  #
  def initialize(path, pid_dictionary)
    file_lines = trace_file_lines(path)
    @total, @virtual = file_lines.shift.split(" ").map(&:to_i)
    @lines = file_lines.map { |line| AProcess.new(line, pid_dictionary) }
  end

  private
    #
    # Abre o arquivo que foi passado pelo usuario e coloca todas as suas linhas
    # em um vetor que eh retornado pela funcao 
    #
    def trace_file_lines(path)
      begin
        File.open(path, 'r') { |file| file.read.lines }
      rescue Errno::ENOENT
        p "Não foi possível o arquivo (nome inválido)"
        exit
      end
    end
end
