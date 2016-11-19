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
  
  # seletor dos algoritmos de gerência de memória e substituição de páginas
  @@memory_management_mode = 1
  @@page_replacement_mode = 1

  @@next_fit_last_assigned = 0
  
  # physical_memory_page_reference guarda para cada quadro de pagina o indice
  # da pagina na memoria virtual
  @@physical_memory_page_reference = nil

  # guarda o estado atual da memória física (para imprimi-la)
  @@physical_memory = nil

  # Fila de páginas que será usada no Second Chance
  @@fifo_queue = []

  # Lista circular que é usada no algoritmo de Clock
  @@circular_list = []
  @@circular_list_last_reference = 0

  # Cria a estrutura para sabermos qual memoria sera acessada antes
  @@optimal_access_list = []
  # cria um hash para guardar a posicao inicial das paginas dos processos na memory_page_table
  @@process_initial_page_position = {}


  @@time_now = 0

  @@page_faults = 0
  @@quanto_rodei_para_achar_espaco_livre = 0


  
  # 
  # Inicia as estruturas de dados usadas
  #
  def self.start(process_list)
    @@s = process_list.s
    @@p = process_list.page_size
    @@addresses_per_page = @@p / @@s

    # memory_pages_table: É um array com todas as páginas que estarão na memória
    # virtual. Cada célula é um objeto de MemoryPage.
    # (vide memory_page.rb para descrição da classe)
    total_virtual_pages = (1.0 * process_list.virtual / @@p).ceil
    @@memory_pages_table = Array.new(total_virtual_pages).map { MemoryPage.new }

    # physical_memory_page_reference: tem para cada quadro de página na memória
    # física o índice (no array memory_pages_table) da página correspondente.
    total_physical_frame_pages = (1.0 * process_list.total / @@p).ceil
    @@physical_memory_page_reference = Array.new(total_physical_frame_pages, -1)
    
    # Physical_memory: physical_memory temos o PID do processo que está usando
    # aquela posição de memória. Obs: se não tiver nenhum processo
    # então recebe “-1” que é representado por 255, em binário 1111 1111.
    @@physical_memory = Array.new(total_physical_frame_pages, 255)

    # bitmap: vetor de bits que contém uma posição para cada byte da memória
    # virtual, contendo 0 nos índices dos bytes que estão livres e 1 nos índices
    # dos bytes que estão ocupados.
    # 
    # Estamos representando o bitmap por baixo dos panos com um vetor contendo
    # um bit por página virtual em vez de um bit por byte de memória. A
    # justificativa para isso é que facilita a implementação dos algoritmos
    # de gerência. Já que o mínimo que é reservado para um processo é uma página
    # inteira, faz sentido manter um bit por página, pois haveria muitas
    # repetições de bits caso usássemos um bit por byte de memória.
    @@bitmap = BitArray.new(process_list.virtual / @@p)

    update_memory_files
  end

  def self.memory_management_mode=(value)
    @@memory_management_mode = value
  end

  def self.page_replacement_mode=(value)
    @@page_replacement_mode = value
  end

  def self.time_now=(value)
    @@time_now = value
  end

   def self.get_time_now()
    return @@time_now
  end

  def self.get_page_faults()
    return @@page_faults
  end

  def self.get_page_replacement_mode()
    return @@page_replacement_mode
  end

  # Reescreve os arquivos binários que representam as memórias virtual e física
  def self.update_memory_files
    # atualiza o arquivo de memória física
    print_format = @@physical_memory.map { |el| [el] * @@p }.flatten
    pack_argument = 'c' * print_format.size
    File.open("/tmp/ep2.mem", "wb") do |file|
      file << print_format.pack(pack_argument)
    end

    # atualiza o arquivo de memória virtual
    print_format = @@memory_pages_table.map { |el|
      [el.pid == -1 ? 255 : el.pid] * @@p
    }.flatten
    pack_argument = 'c' * print_format.size
    File.open("/tmp/ep2.vir", "wb") do |file|
      file << print_format.pack(pack_argument)
    end
  end

  # 
  # Atualiza o vetor memory_pages_table, escrevendo o PID do processo que cada
  # página está usando OU escrevendo -1 nas páginas que não estão mais sendo
  # usadas.
  # 
  def self.update_memory_pages_table(pid: nil, initial_page_position: nil,
                                     size_in_pages: nil, remove: false)
    i = initial_page_position
    size_in_pages.times do
      @@memory_pages_table[i].pid = remove ? -1 : pid
      i += 1
    end
  end

  #
  # Adiciona um processo na lista encadeada segmentos de memoria
  #
  def self.add_process(time_event)
    process = time_event.process
    initial_page_position = memory_management_algorithm(process.number_of_bytes)
    process.initial_page_position = initial_page_position

    i = initial_page_position
    size_in_pages = (1.0 * process.number_of_bytes / @@p).ceil
    size_in_pages.times do
      @@bitmap[i] = 1
      i += 1
    end

    update_memory_pages_table(pid: process.pid, size_in_pages: size_in_pages,
                              initial_page_position: initial_page_position)

    # insere no hash para sabermos qual a primeira pagina do processo
    @@process_initial_page_position[process.pid] = initial_page_position
  end

  #
  # Termina um processo, liberando o bitmap
  #
  def self.remove_process(time_event, pid_dictionary)
    process = time_event.process
    size_in_pages = (1.0 * process.number_of_bytes / @@p).ceil

    i = process.initial_page_position
    size_in_pages.times do
      @@bitmap[i] = 0
      i += 1
    end

    initial_page_position = process.initial_page_position

    pid_dictionary.delete(process.pid)
    update_memory_pages_table(initial_page_position: initial_page_position,
                              size_in_pages: size_in_pages, remove: true)
  end

  #
  # Algoritmo de gerência de espaco livre -> First Fit
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
    p "VOU RETORNAR NIL"
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

    best_found
  end

  def self.worst_fit(process_size)
    size = 0
    worst_found = index = -1
    worst_found_size = 0
    i = 0
    @@bitmap.each do |bit|
      if bit == 0
        index = i if size == 0
        size += 1
      else
        if size >= process_size and size > worst_found_size
          worst_found_size = size
          worst_found = index
        end
        index = -1
        size = 0
      end
      i += 1
    end
    
    if @@bitmap[i - 1] == 0
      if size >= process_size and size > worst_found_size
        worst_found_size = size
        worst_found = index
      end
    end

    worst_found
  end

  def self.build_optimal_queue(time_events_list)

    # pega todos os memory acess e coloca numa lista de hashs, 
    # indicando o pid do processo e uma lista com os acessos de memoria
    # a estrutura fica assim:
    # {
    #   pid: pid_processo
    #   memory_accesses: {
    #     pagina: [lista de instantes que a pagina eh acessada]
    #   }
    # }
    for i in 0..(time_events_list.keys.max) do
      time_events_list[i].each do |time_event|
        if time_event.mode == :memory_access
          if not @@optimal_access_list.any? {|h| h[:pid] == time_event.process.pid}

            # os memory access serao inseridos de forma que a chave eh a pagina
            # e o value seja os instantes em que ela sera acessada
            hash = {}
            time_event.process.memory_accesses.each do |memory_access|
              page_memory_access = (1.0 * memory_access[0] / @@p).floor

              # ainda nao temos essa memoria no nosso hash
              if hash[page_memory_access] == nil
                hash[page_memory_access] = [memory_access[1]]
              else
                # se ja tivermos temos que incluir no vetor
                hash[page_memory_access] << memory_access[1]
              end
            end
            @@optimal_access_list << {
              pid: time_event.process.pid,
              memory_accesses: hash
            }
          end
        end
      end
    end
  end


  #
  # Implementação do algortimo de substituicao de pagina -> Optimal

  # O algoritmo tem que verificar todos os elementos da memoria fisica, ver 
  # qual pagina sera acessada novamente no futuro, se nao for acessada, ela sera 
  # escolhida para sair da memoria fisica, se todas as paginas forem ser acessadas no futuro
  # escolhemos a que demorará mais tempo para ser acessada
  #
  def self.optimal(memory_page)
    index = @@physical_memory_page_reference.index(-1)
    next_to_get_out = 0
    index_for_getting_out = -1
    page_acesses = []


    if index.nil?
      # percorre todas as paginas na memoria e vamos verificar em @@optimal_access_list
      # qual sera o processo que esta na memoria e precisa sair, 
      # pois sera o ultimo que sera acessado entre eles
      for i in 0..@@physical_memory_page_reference.size do
        # primeiro precisamos nos certificar que a memoria que estamos acessando nao foi retirada
        # da tabela de paginas devido ao termino do processo
        if @@physical_memory_page_reference[i] != -1 and 
          @@physical_memory_page_reference[i] != nil and
          @@memory_pages_table[@@physical_memory_page_reference[i]].pid != -1 and
          @@memory_pages_table[@@physical_memory_page_reference[i]].pid != nil



          pid = @@memory_pages_table[@@physical_memory_page_reference[i]].pid

          # vamos primeiro pegar a posicao na tabela de paginas da memoria virtual da memoria
          # que estamos tentando acessar, alem da posicao da primeira pagina desse processo
          # assim temos o endereco local da pagina
          local_page_index = @@physical_memory_page_reference[i] - @@process_initial_page_position[pid]



          # vamos percorrer os acessos de memoria ate acharmos o PID e a pagina que 
          # desejamos investigar
          @@optimal_access_list.each do |process|
            if process[:pid] == pid
              page_acesses = process[:memory_accesses][local_page_index]
              
              # vamos verificar todos os instantes de tempo que essa pagina sera acessada
              for j in 0..page_acesses.size do

                if page_acesses[j] != nil and page_acesses[j] > @@time_now
                  # se a pagina que estamos olhando for demorar mais para ser acessada
                  # do que o next_to_get_out entao atualizamos a variavel
                  if page_acesses[j] > next_to_get_out
                    next_to_get_out = page_acesses[j]
                    index_for_getting_out = i
                  end
                  break
                end
              end
              # se a pagina nao vai mais ser acessada no futuro
              if j == page_acesses.size and page_acesses[j - 1] < @@time_now
                return i
              end

            end
          end
        end
      end
      return index_for_getting_out
    else
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
      @@fifo_queue << memory_page
      return elemento_mais_antigo.physical_index
    else
      @@fifo_queue << memory_page
      return index
    end
  end

   #
  # Implementação do algortimo de substituicao de pagina -> Clock
  #
  def self.clock(memory_page)
    # varre primeiramente a memoria fisica e verifica se existe algum espaco livre
    index = @@physical_memory_page_reference.index(-1)

    p @@circular_list, index

    # se nao tem nenhum espaco livre entao pegamos o elemento mais antigo e verificamos o bit R
    if index.nil?
      while @@circular_list[@@circular_list_last_reference].r == 1
        print "o bit r eh 1 last: ", @@circular_list_last_reference, "\n"
        @@circular_list[@@circular_list_last_reference].r = 0
        @@circular_list_last_reference = (@@circular_list_last_reference + 1 ) % @@circular_list.size
      end
      p "aqui o bit r eh zero ja", @@circular_list[@@circular_list_last_reference].r, "\n"
      elemento = @@circular_list[@@circular_list_last_reference]
      @@circular_list.delete_at(@@circular_list_last_reference)
      @@circular_list_last_reference = (@@circular_list_last_reference + 1 ) % @@circular_list.size
      print "o bit r e zero devolver ", elemento.physical_index, "\n"
      return elemento.physical_index
    else
      @@circular_list << memory_page
      return index
    end
  end

  # Lida com os acessos às posições de memória. Varre a memória física para
  # saber se a página solicitada está presente nela. Se não
  # estiver, é preciso usar um algoritmo de substituição de página
  def self.memory_access(time_event)
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
    @@page_faults += 1
    physical_index = page_replacement_algorithm(page)

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
  # Usa o algoritmo de gerência de memória livre selecionado
  # 
  def self.memory_management_algorithm(number_of_bytes)
    process_size = (1.0 * number_of_bytes / @@p).ceil
    case @@memory_management_mode
    when 1 then first_fit(process_size)
    when 2 then next_fit(process_size)
    when 3 then best_fit(process_size)
    when 4 then worst_fit(process_size)
    end
  end


  #
  # Usa o algoritmo de substituição de página selecionado
  # 
  def self.page_replacement_algorithm(memory_page)
    case @@page_replacement_mode
    when 1 then optimal(memory_page)
    when 2 then second_chance(memory_page)
    when 3 then clock(memory_page)
    end
  end

  # Transforma posição local da memória de um processo em índice página em que
  # ela está
  def self.page_index_of_memory_position(time_event)
    time_event.process.initial_page_position +
    (1.0 * time_event.memory_position / @@p).floor
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

    print "Bitmap:\n"
    print @@bitmap.to_s.split('').map { |c| "#{c} " * @@p }.join "\n"
    print "\n\n"
    
    print "Estado da memória virtual:\n"
    print @@memory_pages_table.map { |pg| "#{pg.pid}".rjust(4) * @@p }.join "\n"
    print "\n"

    print "Estado da memória física:\n"
    print "#{@@physical_memory.map { |n| n.to_s.rjust(4) * @@p }.join("\n")}\n"
    # TODO linha abaixo é só pra depuração - remover antes de entregar
    print @@physical_memory_page_reference.map { |n| n.to_s.rjust(4) }.join
    print "\n#{'-' * 100}\n"
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
