require './simulated_file.rb'

class DiskOperations

  DISK_SIZE_IN_BYTES = 100_000_000
  BLOCK_SIZE_IN_BYTES = 4_000
  ROOT_SIZE_IN_BYTES = 12_000
  FAT_SIZE_IN_BYTES = 52_000
  INITIAL_FAT_POSITION = 4_000
  NUMBER_OF_BLOCKS_IN_DISK = (DISK_SIZE_IN_BYTES / BLOCK_SIZE_IN_BYTES)
  ROOT_FIRST_BLOCK = 15
  BITMAP_SIZE_IN_BYTES = 4_000
  BITMAP_LIMIT_BYTE = 3_125
  INITIAL_BITMAP_POS = BLOCK_SIZE_IN_BYTES + FAT_SIZE_IN_BYTES
  FINAL_BITMAP_POS = INITIAL_BITMAP_POS + BITMAP_SIZE_IN_BYTES - 1
  MAX_FILES_IN_DIR = 111
  FILE_METADATA_SIZE_INSIDE_DIRECTORY = 36

  attr_accessor :disk_path, :fat, :total_overhead_in_bytes
  
  def initialize(disk_path)
    @disk_path = disk_path
    @fat = []
    @total_overhead_in_bytes = BLOCK_SIZE_IN_BYTES + FAT_SIZE_IN_BYTES +
                               BITMAP_SIZE_IN_BYTES + ROOT_SIZE_IN_BYTES
    
    write_disk_file unless File.exists? disk_path
    initialize_fat
  end
  
  def open_disk
    File.open(disk_path, "rb")
  end

  def update_disk
    File.open(disk_path, "r+b")
  end

  def umount
    disk = update_disk
    disk.seek(INITIAL_FAT_POSITION)
    disk.write(@fat.pack('S' * (FAT_SIZE_IN_BYTES / 2)))
    disk.close

    @disk_path = nil
    @fat = []
  end

  def initialize_fat
    disk = open_disk
    disk.seek(INITIAL_FAT_POSITION)
    fat_bytes = disk.read(FAT_SIZE_IN_BYTES)
    disk.close

    @fat = fat_bytes.unpack('S' * (FAT_SIZE_IN_BYTES / 2))
    # aqui colocamos a informação do ROOT no FAT.
    @fat[15] = 16
    @fat[16] = 17
    @fat[17] = -1
  end

  def write_disk_file
    File.open(@disk_path, "wb") do |file|
      # super block
      
      first_block = [BLOCK_SIZE_IN_BYTES, NUMBER_OF_BLOCKS_IN_DISK] + ([0] * 3996)
      file << first_block.pack('SS' + ('c' * 3_996))

      # FAT
      @fat = [0] * NUMBER_OF_BLOCKS_IN_DISK
      # completa a última parte do último bloco do FAT com -1's
      fat_blocks_offset = ((@fat.size * 2) % 4_000) / 2
      fat_blocks = @fat + ([-1] * fat_blocks_offset)
      pack_argument = ('S' * NUMBER_OF_BLOCKS_IN_DISK) + ('S' * fat_blocks_offset)
      file << fat_blocks.pack(pack_argument)

      # bitmap
      # Os 18 primeiros blocos do disco estão ocupados pelo superblock, FAT,
      # bitmpa e root. No bitmap, então, escrevemos 18 bits 0. Para completar
      # 3 bytes, escrevemos dois bytes 0 (0000 0000) e um byte 63 (0011 1111),
      # que significa que os últimos seis bits do terceiro byte to bitmap
      # estão livres.
      bitmap = ["00000000".to_i(2), "00000000".to_i(2), "00111111".to_i(2)] +
               [255] * (BITMAP_LIMIT_BYTE - 3)
      bitmap += [0] * (BLOCK_SIZE_IN_BYTES - bitmap.size)
      file << bitmap.pack('c' * bitmap.size)
      
      # root
      root = [0] * ROOT_SIZE_IN_BYTES
      file << root.pack('c' * ROOT_SIZE_IN_BYTES)

      # espaço para arquivos e diretórios em geral
      available_space = [0] * (DISK_SIZE_IN_BYTES - file.size)
      file << available_space.pack('c' * available_space.size)
    end
  end

  def index_next_free_block
    disk = open_disk

    disk.seek(INITIAL_BITMAP_POS)
    while disk.pos < FINAL_BITMAP_POS do
      current_disk_pos = disk.pos
      control_byte = disk.readbyte
      if control_byte != 0
        index_inside_byte = control_byte.to_s(2).rjust(8, "0").index('1')
        related_bitmap_byte_pos = current_disk_pos - INITIAL_BITMAP_POS
        free_index = related_bitmap_byte_pos * 8 + index_inside_byte
        disk.close
        return free_index
      end
    end
    disk.close
  end

  def mkdir(path)
    disk = open_disk

    dir_tree = path.split("/")
    dir_tree.shift
    new_dir_name = dir_tree.pop
    new_dir_father_first_block = ROOT_FIRST_BLOCK

    # pega todos os arquivos da root
    root_files = decode_directory_block(ROOT_FIRST_BLOCK) +
                 decode_directory_block(ROOT_FIRST_BLOCK + 1) +
                 decode_directory_block(ROOT_FIRST_BLOCK + 2)

    current_dir_files = root_files
    # nesse laço, iteramos "descendo" nos diretórios um a um, e,
    # para cada diretório, buscamos, entre seus "filhos", o
    # diretório que tem o nome igual ao nome passado por parâmetro
    # como caminho do diretório a ser criado.
    dir_tree.each do |dir_name|
      current_dir_files.flatten.each do |file|
        if file.name.strip == dir_name.strip
          current_dir_files = decode_directory(file.first_block)
          new_dir_father_first_block = file.first_block
          break
        end
      end
    end

    # criar o diretório
    # ir pro ultimo bloco do diretório
    new_dir_father_final_block = new_dir_father_first_block
    while @fat[new_dir_father_final_block] != -1
      new_dir_father_final_block = @fat[new_dir_father_final_block]
    end

    # vê quanto espaço do diretório pai já está ocupado
    father_dir_files = decode_directory_block(new_dir_father_final_block)
    # aumenta o tamanho do diretório quando necessário
    if father_dir_files.size >= MAX_FILES_IN_DIR
      next_father_dir_block = index_next_free_block
      # no fat
      @fat[new_dir_father_final_block] = next_father_dir_block
      @fat[next_father_dir_block] = -1
      # no bitmap
      update_busy_block_in_bitmap(next_father_dir_block)

      new_dir_father_final_block = next_father_dir_block
    end
    father_dir_first_free_byte = father_dir_files.size * FILE_METADATA_SIZE_INSIDE_DIRECTORY

    new_dir_first_block = index_next_free_block
    simulated_new_dir = SimulatedFile.new(name: new_dir_name,
                                          size: -1,
                                          time_created: Time.now.to_i,
                                          time_modified: Time.now.to_i,
                                          time_accessed: Time.now.to_i,
                                          first_block: new_dir_first_block)
    # - colocar no FAT essas informações;
    @fat[new_dir_first_block] = -1

    # - colocar no Bitmap essa informação.
    update_busy_block_in_bitmap(new_dir_first_block)

    disk.close

    # escreve os metadados do novo diretório no disco
    disk = update_disk
    # escreve no diretório pai os metadados do diretório filho
    disk.seek(father_dir_first_free_byte + new_dir_father_final_block * BLOCK_SIZE_IN_BYTES)
    disk.write(simulated_new_dir.parse)

    disk.close
  end

  def ls(path)
    directory_data = get_block_from_dir(path)
    target_dir_first_block = directory_data[:target_dir_first_block]
    current_dir_files = directory_data[:current_dir_files]

    print "nome\ttamanho(ou dir)\tmodificado em\n"
    current_dir_files.flatten.each do |file|
      # nossos arquivos tem tamanho "-1" (que é convertido para 4294967295
      # na escrita do binário)
      if file.size == 4294967295
        print "#{file.name.strip}\tdir\t#{Time.at file.time_modified}\n"
      else
        print "#{file.name.strip}\t#{file.size}\t#{Time.at file.time_modified}\n"
      end
    end
    print "\n"
  end

  def touch(path)
    disk = update_disk

    file_name = path.split("/").last

    directory_data = get_block_from_dir(path)
    current_dir_files = directory_data[:current_dir_files]
    dir_first_block = directory_data[:target_dir_first_block]

    if current_dir_files.map(&:name).map(&:strip).include?(file_name)
      file_index_in_directory = 0
      current_dir_files.each_with_index do |file, i|
        if file.name == file_name
          file_index_in_directory = i
          break
        end
      end
      current_dir_files[file_index_in_directory].time_accessed = Time.now
      disk.seek(dir_first_block * BLOCK_SIZE_IN_BYTES +
                file_index_in_directory * FILE_METADATA_SIZE_INSIDE_DIRECTORY)
      disk.write(current_dir_files[file_index_in_directory].parse)
    else
      if current_dir_files.size >= MAX_FILES_IN_DIR
        alloc_new_block_for_full_dir(current_dir_files, dir_first_block)
      end
      new_file_index = index_next_free_block()
      # 1) guardar espaço no disco:
      #     fat
      @fat[new_file_index] = -1
      #     bitmap
      update_busy_block_in_bitmap(new_file_index)
      # 2) escrever os metadados no pai
      simulated_file = SimulatedFile.new(size: 0,
                                         time_created: Time.now.to_i,
                                         time_modified: Time.now.to_i,
                                         time_accessed: Time.now.to_i,
                                         first_block: new_file_index,
                                         name: file_name)
      first_dir_free_byte = dir_first_block * BLOCK_SIZE_IN_BYTES +
                            current_dir_files.size * FILE_METADATA_SIZE_INSIDE_DIRECTORY
      disk.seek(first_dir_free_byte)
      disk.write(simulated_file.parse)
    end

    disk.close
  end

  def cp(origin_path, destination_path)
    disk = update_disk
    origin_file = File.open(origin_path, "rb")

    size = origin_file.size

    dir_tree = destination_path.split("/")
    new_file_name = dir_tree.pop
  

    first_block = index_next_free_block
    new_file_number_of_blocks = block_size_completer(origin_file.size)
    previous_block = current_block = first_block
    new_file_number_of_blocks.times do
      content = origin_file.read(BLOCK_SIZE_IN_BYTES)

      disk.seek(current_block * BLOCK_SIZE_IN_BYTES)
      disk.write(content)

      @fat[previous_block] = current_block
      @fat[current_block] = -1

      update_busy_block_in_bitmap(current_block)

      break if origin_file.eof?

      previous_block = current_block
      current_block = index_next_free_block
    end

    origin_file.close

    simulated_file = SimulatedFile.new(size: size,
                                       time_created: Time.now.to_i,
                                       time_modified: Time.now.to_i,
                                       time_accessed: Time.now.to_i,
                                       first_block: first_block,
                                       name: new_file_name)

    dir_first_block = get_block_from_dir(dir_tree.join("/"))[:target_dir_first_block]

    pos = get_first_free_byte_of_dir(dir_first_block)
    disk.seek(pos)
    disk.write(simulated_file.parse)
    disk.close
  end

  def rm(path)
    disk = update_disk

    dir_tree = path.split("/")
    file_name = dir_tree.pop
    dir_first_block = get_block_from_dir(dir_tree.join("/"))[:target_dir_first_block]
    
    # atualiza os metadados
    removed_file = nil
    indexes = get_file_indexes(dir_first_block)
    last_dir_block = indexes.last
    file_block_index = indexes.first
    relative_pos_of_removed_file = 0
    indexes.each do |index|
      decode_directory_block(index).each_with_index do |file, i|
        if file.name.strip == file_name.strip
          removed_file = file
          file_block_index = index
          relative_pos_of_removed_file = i
          break
        end
      end
    end
    files_in_last_dir_block = decode_directory_block(last_dir_block)
    last_file_in_dir = files_in_last_dir_block.last
    relative_pos_of_last_file_in_dir = (files_in_last_dir_block.size - 1) * FILE_METADATA_SIZE_INSIDE_DIRECTORY
    
    temp_pos = last_dir_block * BLOCK_SIZE_IN_BYTES + relative_pos_of_last_file_in_dir
    disk.seek(temp_pos)
    disk.write(([0] * FILE_METADATA_SIZE_INSIDE_DIRECTORY).pack('c' * FILE_METADATA_SIZE_INSIDE_DIRECTORY))

    temp_pos = file_block_index * BLOCK_SIZE_IN_BYTES + relative_pos_of_removed_file * FILE_METADATA_SIZE_INSIDE_DIRECTORY
    disk.seek(temp_pos)
    disk.write(last_file_in_dir.parse)

    # remove do disco
    indexes = get_file_indexes(removed_file.first_block)
    indexes.each do |index|
      @fat[index] = 0
      update_free_block_in_bitmap(index)
      disk.seek(index * BLOCK_SIZE_IN_BYTES)
      disk.write(([0] * BLOCK_SIZE_IN_BYTES).pack('c' * BLOCK_SIZE_IN_BYTES))
    end

    disk.close
  end

  def get_first_free_byte_of_dir(first_block)
    last_block = get_file_indexes(first_block).last
    size = decode_directory_block(last_block).size
    if size > MAX_FILES_IN_DIR
      new_index = alloc_new_block_for_full_dir
      return new_index * BLOCK_SIZE_IN_BYTES
    else
      return size * FILE_METADATA_SIZE_INSIDE_DIRECTORY +
             last_block * BLOCK_SIZE_IN_BYTES
    end
  end

  def alloc_new_block_for_full_dir(current_dir_files, dir_first_block)
    next_dir_block = index_next_free_block
    # no fat
    dir_indexes = get_file_indexes(dir_first_block)
    @fat[dir_indexes.last] = next_dir_block
    @fat[next_dir_block] = -1

    update_busy_block_in_bitmap(next_dir_block)

    next_dir_block
  end

  # Recebe um path e retorna o índice do primeiro bloco do diretório,
  # além da lista de arquivos que este diretório contém.
  def get_block_from_dir(path)
    disk = open_disk
    dir_tree = path.split("/")
    dir_tree.shift
    target_dir_first_block = ROOT_FIRST_BLOCK

    # pega todos os arquivos da root
    root_files = decode_directory_block(ROOT_FIRST_BLOCK) +
                 decode_directory_block(ROOT_FIRST_BLOCK + 1) +
                 decode_directory_block(ROOT_FIRST_BLOCK + 2)

    current_dir_files = root_files

    dir_tree.each do |dir_name|
      current_dir_files.flatten.each do |file|
        if file.name.strip == dir_name.strip
          current_dir_files = decode_directory(file.first_block)
          target_dir_first_block = file.first_block
          break
        end
      end
    end
    disk.close
    {
      target_dir_first_block: target_dir_first_block,
      current_dir_files: current_dir_files.flatten
    }
  end

  # Recebe uma posição (em bytes) e lê o bloco que começa naquela
  # posição.
  def read_disk_block(position_in_bytes)
    disk = open_disk

    disk.seek(position_in_bytes)
    block_content = disk.read(BLOCK_SIZE_IN_BYTES)
    
    disk.close
    block_content
  end

  # Recebe o índice do primeiro bloco de um diretório e retorna a lista
  # de arquivos que este diretório contém.
  def decode_directory(first_block_index)
    block_indexes = [first_block_index]

    # varre o FAT e encontra a lista de TODOS os blocos que este diretório
    # ocupa.
    index = first_block_index
    loop do
      index = @fat[first_block_index]
      # TODO será que -1 aqui em baixo funciona?
      if index == 0 or index == -1
        break
      else
        block_indexes << index
      end
    end

    # decodifica cada bloco do diretório e soma todos
    directory_files = []
    block_indexes.each do |block_index|
      directory_files << decode_directory_block(block_index)
    end

    directory_files.flatten
  end

  def get_file_indexes(first_block_index)
    block_indexes = [first_block_index]

    # varre o FAT e encontra a lista de TODOS os blocos que este diretório
    # ocupa.
    index = first_block_index
    loop do
      index = @fat[index]
      # TODO será que -1 aqui em baixo funciona?
      if index == 0 or index == -1
        break
      else
        block_indexes << index
      end
    end
    block_indexes
  end

  # Recebe um índice de bloco e devolve um
  # array com as informações dos arquivos do diretório que esse bloco contém.
  def decode_directory_block(block_index)
    block = read_disk_block(BLOCK_SIZE_IN_BYTES * block_index)
    directory_files = []
    i = 0

    MAX_FILES_IN_DIR.times do
      # 16 é o tamanho dos nomes de arquivo
      file_name = block[i..(i+15)]
      # se o primeiro caracter do nome do arquivo for o que corresponde
      # ao código ASCII 0, consideramos que não há mais arquivos no
      # diretório.
      break if file_name[0].ord == 0
      # do índice 16 ao 35 da string, temos cinco inteiros que representam
      # os valores das variáveis descritas abaixo.
      size, time_created, time_modified, time_accessed, first_block = block[(i+16)..(i+35)].unpack('I' * 5)
      directory_files << SimulatedFile.new(size: size,
                                           time_created: time_created,
                                           time_modified: time_modified,
                                           time_accessed: time_accessed,
                                           first_block: first_block,
                                           name: file_name)
      i += FILE_METADATA_SIZE_INSIDE_DIRECTORY
    end
    directory_files.flatten
  end

  def print_bitmap
    disk = open_disk
    disk.seek(INITIAL_BITMAP_POS)
    bitmap_bytes = disk.read(BITMAP_SIZE_IN_BYTES).unpack('c' * BITMAP_SIZE_IN_BYTES)
    p bitmap_bytes
    disk.close
  end

  def update_busy_block_in_bitmap(block_index)
    disk = update_disk

    byte_position = block_index / 8
    bitmap_block_location = byte_position + INITIAL_BITMAP_POS
    disk.seek(bitmap_block_location)
    read_byte = disk.readbyte.to_s(2).rjust(8, "0")

    bit_position = block_index % 8
    read_byte[bit_position] = "0"

    disk.seek(bitmap_block_location)
    disk.write([read_byte.to_i(2)].pack('c'))

    disk.close
  end

  def update_free_block_in_bitmap(block_index)
    disk = update_disk

    byte_position = INITIAL_BITMAP_POS + block_index / 8
    bit_position = block_index % 8

    disk.seek(byte_position)

    read_byte = disk.readbyte.to_s(2).rjust(8, "0")
    read_byte[bit_position] = "1"

    disk.seek(byte_position)
    disk.write([read_byte.to_i(2)].pack('c'))

    disk.close
  end

  def first_empty_space_in_root(block_index)
    disk = open_disk
    current_root_block = ROOT_FIRST_BLOCK

    files_in_root_block = decode_directory_block(new_dir_father_final_block)
    father_dir_first_free_byte = father_dir_files.size * FILE_METADATA_SIZE_INSIDE_DIRECTORY

    disk.close
  end

  private
    # recebe um número em bytes e retorna a quantidade mínima de blocos
    # que esses bytes vão precisar ocupar
    def block_size_completer(byte_number)
      byte_number + 4_000 - (byte_number % 4_000)
    end
end