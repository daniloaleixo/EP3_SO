class SimulatedFile
  attr_accessor :name, :size, :time_created, :time_modified, :time_accessed, :first_block

  def initialize(opts={})
    @name = opts[:name] unless opts[:name].nil?
    @size = opts[:size] unless opts[:size].nil?
    @time_created = opts[:time_created] unless opts[:time_created].nil?
    @time_modified = opts[:time_modified] unless opts[:time_modified].nil?
    @time_accessed = opts[:time_accessed] unless opts[:time_accessed].nil?
    @first_block = opts[:first_block] unless opts[:first_block].nil?
  end

  def parse
    name_chars = @name.rjust(16, " ").chars.map{ |el| el.ord }
    (name_chars + [@size, @time_created.to_i, @time_modified.to_i,
                   @time_accessed.to_i, @first_block]).pack('c' * 16 + 'I' * 5)
  end
end
