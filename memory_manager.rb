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

  def self.memory_pages_table
    @@memory_pages_table
  end
  
  # 
  # Inicia as estruturas de dados usadas
  #
  def self.start(total_virtual_pages, total_physical_frame_pages,
                 total_virtual_addresses, s_size, p_size)
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

    # bitmap: vetor de booleanos que contém uma posição para cada endereço da
    # memória virtual, contendo false nos índices dos endereços que estão
    # ocupados e true nos índices dos endereços vazios.
    @@bitmap = Array.new(total_virtual_addresses, false)

    @@s = s_size
    @@p = p_size

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
    size = opts[:size]
    mode = opts[:mode]

    for i in initial_page_position..(initial_page_position + size - 1) do
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
  def self.add_process(opts={})
    # os argumentos serão recebidos via hash.
    pid = opts[:pid]
    name = opts[:name]
    initial_page_position = opts[:initial_page_position]
    # size é o tamanho em páginas de memória (já está dividido por 16)
    size = opts[:size]
    pid_dictionary = opts[:pid_dictionary]



    # criamos o novo segmento passando as infos que recebemos 
    new_memory_segment = VMemorySegment.new(initial_page_position, size, pid, 
                                            current_segment)

    # quando current_segment == previous_segment significa que a lista possui um 
    # elemento soh que indica que a memoria inteira
    # esta livre, portanto precisamos atualizar a cabeca da lista ao adicionar
    # o novo elemento 
    if current_segment == memory_segments_list 
      memory_segments_list = new_memory_segment
    else
      previous_segment.prox = new_memory_segment
    end

    #atualizamos o tamanho do espaco de memoria livre
    if current_segment.nil?
      return nil
    else
      current_segment.initial_page_position = initial_page_position + size
      current_segment.size -= new_memory_segment.size

      # verifica o caso de quando se insere atrás de um espaço livre, e esse
      # espaço livre tem que desaparecer.
      if((not current_segment.prox.nil? and
          current_segment.initial_page_position >= current_segment.prox.initial_page_position) or
          current_segment.size == 0)
        new_memory_segment.prox = current_segment.prox
        current_segment.prox = nil
      end
    end

    update_memory_pages_table(mode: :add, pid: pid, size: size,
                              initial_page_position: initial_page_position)

    #retorna a cabeca da lista encadeada
    return memory_segments_list
  end


  #
  # Removemos um segmento de memoria da lista encadeada de segmentos, tornando
  # a nova posicao uma posicao livre 
  #
  def self.remove_segment_from_list(memory_segments_list, pid, pid_dictionary)

    previous_segment = current_segment = memory_segments_list

    # varre a lista até o último elemento (current_segment == nil) ou até
    # encontrar o elemento com pid passado via argumento
    while !current_segment.nil? and current_segment.pid != pid
      previous_segment = current_segment
      current_segment = current_segment.prox
    end
    return nil if current_segment.nil?


    next_segment = current_segment.prox
    size = current_segment.size
    initial_page_position = current_segment.initial_page_position

    
    if previous_segment.pid == -1
      # entao o segmento anterior ao do processo removido está livre
      previous_segment.prox = next_segment
      current_segment.prox = nil
      # (não foi preciso dar free porque Ruby tem Gargabe Collector,
      #  por isso basta tirar o elemento da lista)
      previous_segment.size += current_segment.size
      current_segment = previous_segment
    else
      current_segment.pid = -1
    end

    if next_segment.nil?
      pid_dictionary.delete(pid)
      update_memory_pages_table(mode: :remove, size: size,
                                initial_page_position: initial_page_position)
      return memory_segments_list
    end

    if next_segment.pid == -1
      # se o seguimento seguinte ao removido for livre, o removemos da lista e
      # aumentamos o tamanho do segmento livre
      current_segment.prox = next_segment.prox
      current_segment.size += next_segment.size
      next_segment.prox = nil
    end

    pid_dictionary.delete(pid)
    update_memory_pages_table(mode: :remove, size: size,
                              initial_page_position: initial_page_position)
    return memory_segments_list
  end

  #
  # Implementacao do algoritmo de gerencia de espaco livre -> First Fit
  # Se percorre o bitmap e se devolver o índice da primeira posição que
  # comporta process_size
  #
  def self.first_fit(process_size)
    size = 0
    index = -1
    @@bitmap.each_with_index do |bit, i|
      if bit
        index = i if size == 0
        size += 1
      else
        index = -1
        size = 0
      end
    end
    index >= 0 ? index : nil
  end

  #
  # Implementacao do algoritmo de gerencia de espaco livre -> Next Fit
  #
  # onde percorremos a lista encadeada de segmentos de memoria e 
  # escolhemos a primeira posicao livre, porem partindo sempre da ultima 
  # posicao que um elemento foi adicionado
  #
  def self.next_fit(memory_segments_list, size)
    current_segment = memory_segments_list

    # encontra o segmento do qual começaremos a varrer a lista
    while not current_segment.nil?
      break if current_segment.initial_page_position >= @@next_fit_last_assigned
      current_segment = current_segment.prox
    end
    current_segment = memory_segments_list if current_segment.nil? 
    limit_segment = current_segment
    
    # varre a lista de limit_segment até o final
    while not current_segment.nil?
      if current_segment.pid == -1 and current_segment.size >= size
        @@next_fit_last_assigned = current_segment.initial_page_position + size
        return current_segment.initial_page_position
      end
      current_segment = current_segment.prox
    end
    
    # como não encontrou espaço livre do limite até o final, varre do início
    # até o limite buscando espaço livre.
    current_segment = memory_segments_list
    while current_segment != limit_segment
      if current_segment.pid == -1 and current_segment.size >= size
        @@next_fit_last_assigned = current_segment.initial_page_position + size
        return current_segment.initial_page_position
      end
      current_segment = current_segment.prox
    end
    return nil
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
  def self.memory_access(pid, memory_segments_list, 
                         memory_position, page_replacement_mode)
    page_position = page_index_of_memory_position(pid, memory_position,
                                                  memory_segments_list)
    return nil if page_position.nil?

    # varre a memória física para saber se 'page_position' está nela
    # se 'page_position' está em alguma posição de '@@physical_memory_page_reference',
    # retornamos 'true' (ou seja, a memória foi acessada com sucesso)
    if not @@physical_memory_page_reference.index(page_position).nil?
      @@memory_pages_table[page_position].recently_used = true
      return true 
    end

    # Se chegamos nessa linha, é porque a página solicitada não está na memória
    # física. Então, temos que usar um algoritmo de substituição de página.
    physical_index = page_replacement_algorithm(page_replacement_mode,
                                                @@memory_pages_table[page_position])


    # se existe uma pagina que iremos remover da memoria fisica fazemos:
    if @@physical_memory_page_reference[physical_index] != -1
      removed_page = @@memory_pages_table[@@physical_memory_page_reference[physical_index]]
      removed_page.recently_used = removed_page.on_physical = false
      removed_page.physical_index = -1
    end

    # agora inserimos a pagina na memoria fisica 
    inserted_page = @@memory_pages_table[page_position]
    inserted_page.on_physical = true
    inserted_page.physical_index = physical_index
    inserted_page.recently_used = true

    # Quando inserimos uma página da memória virtual na memória física,
    # atualizamos também o vetor @@physical_memory, que contém o estado atual
    # da memória física.
    @@physical_memory[physical_index] = inserted_page.pid

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

  # Retorna o indice da página que está na posição de memória
  # passada como parâmetro
  def self.page_index_of_memory_position(pid, memory_position,
                                         memory_segments_list)
    current_segment = memory_segments_list
    initial_page_position = nil
    
    # procura o segmento de memória que tenha o pid passado por parâmetro
    while current_segment != nil
      if current_segment.pid == pid
        initial_page_position = current_segment.initial_page_position
        break
      end
      current_segment = current_segment.prox
    end
    return nil if current_segment.nil?
    # descobre o índice da página que contem 'memory_position'
    page_position = initial_page_position + (memory_position / 16.0).floor
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

    print "Bitmap: #{@@bitmap.map { |bit| bit ? 1 : 0 }.join(" ")}\n"
    
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
