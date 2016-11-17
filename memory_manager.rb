# ************************************

  # EP3 - Sistemas Operacionais
  # Prof. Daniel Batista

  # Danilo Aleixo Gomes de Souza
  # n USP: 7972370

  # Carlos Augusto Motta de Lima
  # n USP: 7991228

# *************************************

# Usamos esta classe para gerenciar a memória. Portanto, a implementaçãoo dos 
# algoritmos de gerência de espaço livre e substituição de páginas estão aqui, 
# junto com as estruturas de dados usadas nesta tarefa.

class MemoryManager
  # vetor de todas as paginas que estarao na memoria virtual
  @@memory_pages_table = nil
  
  @@next_fit_last_assigned = 0
  
  # physical_memory_page_reference guarda para cada quadro de pagina o indice
  # da pagina na memoria virtual
  @@physical_memory_page_reference = nil

  # guarda o estado atual da memória física (para imprimi-la)
  @@physical_memory = nil

  # Fila de páginas que será usada no FIFO
  @@fifo_queue = []
  
  # 
  # Inicia as estruturas de dados usadas
  #
  def self.start(total_virtual_pages, total_physical_frame_pages, s_size, p_size)
    # Memory_pages_table: É um array com todas as paginas que estarão na memoria
    # virtual, então para cada segmento que existe um processo em memory_segment_list
    # suas respectivas páginas estarão representadas nessa estrutura.
    # Cada célula deste array possui as seguintes informações: PID do processo 
    # representado nesta página; se esta página está referenciada dentro da memória 
    # física, e seu índice; e se foi usada recentemente.
    # Aqui criamos esse array
    @@memory_pages_table = Array.new(total_virtual_pages).map { MemoryPage.new }

    # Physical_memory_page_reference:  Para a memória física temos dois arrays, o
    # physical_memory_page_reference tem para cada quadro de página na memória física
    # o índice da página no array memory_pages_table.
    # Aqui criamos o array
    @@physical_memory_page_reference = Array.new(total_physical_frame_pages, -1)
    
    # Physical_memory: enquanto que no physical_memory temos o PID do processo que
    # esta sendo executado na posição de memória. Obs: se não tiver nenhum processo
    # então recebe “-1” que é representado por 255, em binário 1111 1111.
    # aqui criamos esse array 
    @@physical_memory = Array.new(total_physical_frame_pages, 255)

    @@s = s_size
    @@p = p_size

    # bitmap: vetor de booleanos que contém uma posição para cada endereço da
    # memória virtual, contendo false nos índices dos endereços que estão
    # ocupados e true nos índices dos endereços vazios.
    @@bitmap = BitArray.new(total_virtual_pages * @@p / @@s)

    update_memory_files
  end


  # Reescreve os arquivos binários que representam as memórias virtual e física
  def self.update_memory_files
    # atualiza o arquivo de memória física
    print_format = @@physical_memory.map { |el| [el] * 16 }.flatten
    pack_argument = 'c' * print_format.size
    File.open("/tmp/ep2.mem", "wb") do |file|
      file << print_format.pack(pack_argument)
    end

    # atualiza o arquivo de memória virtual
    print_format = @@memory_pages_table.map { |el|
      [el.pid == -1 ? 255 : el.pid] * 16
    }.flatten
    pack_argument = 'c' * print_format.size
    File.open("/tmp/ep2.vir", "wb") do |file|
      file << print_format.pack(pack_argument)
    end
  end

  # 
  # A funcao atualiza o vetor memory_pages_table, entao quando um novo processo 
  # eh colocado no sistema a funcao mapeia as paginas que este processo utiliza 
  # para memory_pages_table e no caso da exclusao do processo coloca -1, indicando
  # que as paginas estao livres na memoria virtual
  # 
  def self.update_memory_pages_table(opts={})
    pid = opts[:pid]
    initial_page_position = opts[:initial_page_position]
    size_in_pages = opts[:size_in_pages]
    mode = opts[:mode]
    
    for i in initial_page_position..(initial_page_position + size_in_pages - 1) do
      case mode
      when :add
        @@memory_pages_table[i].pid = pid
      when :remove
        @@memory_pages_table[i].pid = -1
      end
    end
  end

  #
  # Adiciona um processo na lista encadeada segmentos de memoria
  #
  def self.add_process(process, initial_page_position)
    allocation_units = (process.number_of_bytes / 16.0).ceil

    process.initial_page_position = initial_page_position

    i = initial_page_position
    allocation_units.times do
      @@bitmap[i] = 1
      i += 1
    end

    update_memory_pages_table(pid: process.pid, size_in_pages: allocation_units,
                              initial_page_position: initial_page_position,
                              mode: :add)
  end

  #
  # Termina um processo, liberando o bitmap
  #
  def self.remove_process(time_event, pid_dictionary)
    process = time_event.process
    allocation_units = (process.number_of_bytes / 16.0).ceil

    i = process.initial_page_position
    allocation_units.times do
      @@bitmap[i] = 0
      i += 1
    end

    initial_page_position = process.initial_page_position
    # TODO por enquanto fica assim; depois tem que mudar
    size_in_pages = allocation_units

    pid_dictionary.delete(process.pid)
    update_memory_pages_table(mode: :remove,
                              initial_page_position: initial_page_position,
                              size_in_pages: size_in_pages)
  end

  #
  # Implementacao do algoritmo de gerencia de espaco livre -> First Fit
  # Se percorre o bitmap e se devolver o índice da primeira posição que
  # comporta process_size
  #
  def self.first_fit(process_size)
    size = 0
    index = -1
    i = 0
    @@bitmap.each do |bit|
      return index if size == process_size
      if bit == 0
        index = i if size == 0
        size += 1
      else
        index = -1
        size = 0
      end
      i += 1
    end
    nil
  end

  #
  # Implementacao do algoritmo de gerencia de espaco livre -> Next Fit
  #
  # onde percorremos a lista encadeada de segmentos de memoria e 
  # escolhemos a primeira posicao livre, porem partindo sempre da ultima 
  # posicao que um elemento foi adicionado
  #
  def self.next_fit(process_size)
    size = 0
    index = -1
    
    i = @@next_fit_last_assigned
    n = @@bitmap.size

    n.times do
      bit = @@bitmap[i]

      if size == process_size
        @@next_fit_last_assigned = index
        return index
      end

      if bit == 1 or i == n - 1
        index = -1
        size = 0
      else
        index = i if size == 0
        size += 1
      end

      i = (i + 1) % n
    end
    nil
  end

  def self.best_fit(process_size)
    size = 0
    best_found = index = -1
    best_found_size = @@bitmap.size + 1
    i = 0
    @@bitmap.each do |bit|
      if bit == 0
        index = i if size == 0
        size += 1
      else
        if size >= process_size and size < best_found_size
          best_found_size = size
          best_found = index
        end
        index = -1
        size = 0
      end
      i += 1
    end
    
    if @@bitmap[i - 1] == 0
      if size >= process_size and size < best_found_size
        best_found_size = size
        best_found = index
      end
    end

    p best_found

    best_found
  end

  #
  # Implementação do algortimo de substituicao de pagina -> NRU
  # (Not Recently Used)
  #
  def self.not_recently_used_page
    # varre primeiramente a memoria fisica e verifica se existe algum espaco livre
    index = @@physical_memory_page_reference.index(-1)
    return index unless index.nil?
    
    # se nao achar espaco livre precisamos verificar quais paginas nao foram usadas 
    # recentemente e para isso acessamos essa informacao na memory_pages_table
    @@physical_memory_page_reference.each_with_index { |el, i|
      return i unless @@memory_pages_table[el].recently_used
    }
    return 0
  end

  #
  # Implementação do algortimo de substituicao de pagina -> FIFO
  # (First In First Out)
  #
  def self.first_in_first_out(memory_page)
    # varre primeiramente a memoria fisica e verifica se existe algum espaco livre
    index = @@physical_memory_page_reference.index(-1)


    if index.nil?
      return @@fifo_queue.shift.physical_index
    else
      @@fifo_queue << memory_page
      return index
    end
  end

  #
  # Implementação do algortimo de substituicao de pagina -> Second Chance
  #
  def self.second_chance(memory_page)
    # varre primeiramente a memoria fisica e verifica se existe algum espaco livre
    index = @@physical_memory_page_reference.index(-1)

    # se nao tem nenhum espaco livre entao pegamos o elemento mais antigo e verificamos o bit R
    if index.nil?
      elemento_mais_antigo = @@fifo_queue.shift

      # se o bit for 1 entao setamos para 0 e colocamos no final da fila
      while elemento_mais_antigo.r == 1
        elemento_mais_antigo.r = 0
        @@fifo_queue << elemento_mais_antigo
        elemento_mais_antigo = @@fifo_queue.shift
      end
      # quando acharmos um com bit 0 devolvemos o indice 
      return elemento_mais_antigo.physical_index
    else
      @@fifo_queue << memory_page
      return index
    end
  end

  # Lida com os acessos às posições de memória. Varre a memória física para
  # saber se a página solicitada está presente nela. Se não
  # estiver, é preciso usar um algoritmo de substituição de página
  def self.memory_access(time_event, page_replacement_mode)
    page_position = page_index_of_memory_position(time_event)
    page = @@memory_pages_table[page_position]
    
    return nil if page_position.nil?

    # verifica se a página já está na memória física. Se sim, retorna true
    # (memória acessada com sucesso)
    if page.on_physical
      page.recently_used = true
      return true 
    end

    # Se chegamos nessa linha, é porque a página solicitada não está na memória
    # física. Então, temos que usar um algoritmo de substituição de página.
    physical_index = page_replacement_algorithm(page_replacement_mode, page)

    # se existe uma pagina que iremos remover da memoria fisica fazemos:
    if @@physical_memory_page_reference[physical_index] != -1
      removed_page = @@memory_pages_table[@@physical_memory_page_reference[physical_index]]
      removed_page.recently_used = removed_page.on_physical = false
      removed_page.physical_index = -1
    end

    # agora inserimos a pagina na memoria fisica 
    page.on_physical = true
    page.physical_index = physical_index
    page.recently_used = true

    # Quando inserimos uma página da memória virtual na memória física,
    # atualizamos também o vetor @@physical_memory, que contém o estado atual
    # da memória física.
    @@physical_memory[physical_index] = page.pid

    # TODO LEMBRAR QUE S É DIFERENTE DE P
    @@physical_memory_page_reference[physical_index] = page_position
  end

  #
  # A funcao usa o algoritmo de gerencia de memoria livre de acordo com o que
  # o usuario escolheu
  # 
  def self.memory_management_algorithm(memory_management_mode, number_of_bytes)
    size = (number_of_bytes / @@s).ceil
    case memory_management_mode
    when 1 then first_fit(size)
    when 2 then next_fit(size)
    when 3 then best_fit(size)
    end
  end


  #
  # A funcao usa o algoritmo de substituicao de pagina de acordo com o que o usuario escolheu
  # 
  def self.page_replacement_algorithm(page_replacement_mode, memory_page)
    case page_replacement_mode
    when 1 then not_recently_used_page
    when 2 then first_in_first_out(memory_page)
    when 3 then second_chance(memory_page)
    end
  end

  # Transforma posição local da memória de um processo em índice página em que
  # ela está
  def self.page_index_of_memory_position(time_event)
    time_event.process.initial_page_position +
    (time_event.memory_position / 16.0).floor
  end

  # A funcao reseta os bits "recently_used" das paginas que estao na memoria fisica
  # por implementacao esperamos 3 segundos para fazer essa atualizacao
  def self.reset_bit_r_from_pages
    @@memory_pages_table.each do |memory_page|
      memory_page.recently_used = false
    end
  end

  # Imprime as estruturas de dados usadas no EP
  def self.print_everything(t)
    if t == -1
      print "Estado final:\n"
    else
      print "t = #{t}s\n"
    end

    print "Bitmap: #{@@bitmap}\n"
    
    print "Estado da memória virtual:\n"
    p @@memory_pages_table.map(&:pid)

    print "\n"

    print "Estado da memória física:\n"
    p @@physical_memory
    p @@physical_memory_page_reference
    p "------------------------------------------------------------------------"
  end

  # Reinicializa as estruturas de dados usadas no EP
  def self.clean
    @@memory_pages_table = nil
    @@next_fit_last_assigned = 0
    @@physical_memory_page_reference = nil
    @@physical_memory = nil
    @@fifo_queue = []
  end
end
