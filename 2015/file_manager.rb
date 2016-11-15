#
# Classe usada para lidar com acessos a arquivos
#
class FileManager

  #
  # Abre o arquivo que foi passado pelo usuario e coloca todas as suas linhas
  # em um vetor que eh retornado pela funcao 
  #
  def self.read_trace_file(path)
    begin
      File.open(path, 'r') { |file|
        file.read.split("\n")
      }
    rescue Errno::ENOENT
      p "Não foi possível o arquivo. Tente novamento com um nove de arquivo válido."
      exit
    end
  end
end