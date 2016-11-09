# ************************************

  # EP3 - Sistemas Operacionais
  # Prof. Daniel Batista

  # Danilo Aleixo Gomes de Souza
  # n USP: 7972370

  # Carlos Augusto Motta de Lima
  # n USP: 7991228

# *************************************







#
# Classe usada para identificar a estrutura de cada linha do arquivo de trace
#

class TraceLine
  attr_accessor :t0, :process_name, :tf, :number_of_bytes, 
                :memory_accesses, :pid
  
  #
  # A funcao recebe como entrada a linha do arquivo de trace onde um processo eh descrito 
  # e coloca o t0, process_name, tf e number_of_bytes como atributos do objeto, alem disso
  # cria um vetor como todos os acessos a memoria feitos por esse processo
  #
  def initialize(file_line, pid_dictionary)
    line_elements = file_line.split(" ")
    
    @t0 = line_elements.shift.to_i
    @process_name = line_elements.shift
    @tf = line_elements.shift.to_i
    @number_of_bytes = line_elements.shift.to_i
    @pid = assign_pid(pid_dictionary)

    @memory_accesses = []
    until line_elements.empty?
      @memory_accesses << [line_elements.shift.to_i, line_elements.shift.to_i]
    end
  end

  #
  # Usamos essa funcao para escolher um novo pid para o proximo processo que chegar
  # no sistema, pegamos o ultimo pid no dicionario e incrementamos seu valor 
  #
  def assign_pid(pid_dictionary)
    pid = pid_dictionary.keys.max.to_i + 1
    pid_dictionary[pid] = @process_name
    return pid
  end
end