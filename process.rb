# ************************************

  # EP3 - Sistemas Operacionais
  # Prof. Daniel Batista

  # Danilo Aleixo Gomes de Souza
  # n USP: 7972370

  # Carlos Augusto Motta de Lima
  # n USP: 7991228

# *************************************

#
# Estrutura de cada linha do arquivo de trace
#

class AProcess
  attr_accessor :t0, :process_name, :tf, :number_of_bytes,
                :memory_accesses, :pid, :initial_page_position
  
  # Recebe como entrada uma string contendo uma linha do arquivo de trace
  # e coloca t0, process_name, tf e number_of_bytes como atributos do objeto,
  # e cria também um vetor com os acessos de memória
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

  # Escolhe um pid para o processo
  def assign_pid(pid_dictionary)
    pid = pid_dictionary.keys.max.to_i + 1
    pid_dictionary[pid] = @process_name
    return pid
  end

  def size_in_pages
    (number_of_bytes / 16.0).ceil
  end
end
