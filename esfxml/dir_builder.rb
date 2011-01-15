# Allocate file names for the entire directory
class DirBuilder
  attr_reader :xml_printer
  
  def initialize(out_dir)
    @out_dir = out_dir
    @path_allocator = Hash.new(1)
    @xml_printer = nil
    FileUtils.mkdir_p @out_dir
  end

  def save_binfile(base_name, semantic_name, ext, data)
    path, rel_path = alloc_new_path(base_name, semantic_name, ext)
    File.open(path, 'wb'){|fh| fh.write data}
    rel_path
  end
  
  def open_xml(new_xml_printer)
    prev_printer = @xml_printer
    @xml_printer = new_xml_printer
    yield
    @xml_printer.close
    @xml_printer = prev_printer
    new_xml_printer.rel_path
  end
  
  def open_main_xml(&blk)
    open_xml(XMLPrinter.new(File.join(@out_dir, 'esf.xml'), 'esf.xml'), &blk)
  end

  def open_nested_xml(base_name, semantic_name, &blk)
    open_xml(XMLPrinter.new(*alloc_new_path(base_name, semantic_name, ".xml")), &blk)
  end

  def alloc_new_path(base_name, semantic_name, ext)
    alloc_key = [base_name, semantic_name, ext]
    name = base_name
    name += "-" unless name =~ /[-\/]\z/
    name += "#{semantic_name}-" if semantic_name
    while true
      rel_path = "%s%04d%s" % [name, @path_allocator[alloc_key], ext]
      path     = File.join(@out_dir, rel_path)
      FileUtils.mkdir_p File.dirname(path)
      return [path, rel_path] unless File.exist?(path)
      @path_allocator[alloc_key] += 1
    end
  end
end

# Printer for a single XML output
class XMLPrinter
  attr_reader :out_buf, :rel_path
  def initialize(out_path, rel_path)
    @rel_path = rel_path
    @out_fh   = File.open(out_path, 'wb')
    @out_buf  = ""
    @stack    = []
    @indent   = Hash.new{|ht,k| ht[k]=" "*k}
  end
  def flush!
    @out_fh.write @out_buf
    @out_buf = ""
  end
  def close
    flush!
    @out_fh.close
  end
  def tag!(name, *args)
    raise ArgumentError.new("Too many arguments") if args.size > 2
    attrs_s = ""
    cnt = nil
    if args.size == 2
      attrs_s = attrs_to_s(args[0])
      cnt = args[1]
    elsif args.size == 1
      if args[0].is_a?(Hash)
        attrs_s = attrs_to_s(args[0])
      else
        cnt = args[0]
      end
    end
    cnt = nil if cnt == ""
    if block_given?
      raise ArgumentError.new("Cannot use content argument and bolck at the same time") if cnt
      out! "<#{name}#{attrs_s}>"
      @stack << name
      yield
      @stack.pop
      out! "</#{name}>"
    elsif cnt.nil?
      out! "<#{name}#{attrs_s}/>"
    else
      out! "<#{name}#{attrs_s}>#{cnt}</#{name}>"
    end
  end
  def out!(str)
    @out_buf << @indent[@stack.size] << str << "\n"
    flush! if @out_buf.size > 1_000_000
  end
  def out_ary!(tag, attrs, data)
    if data.empty?
      out! "<#{tag}#{attrs}/>"
    else
      out! "<#{tag}#{attrs}>"
      data.each{|line| out! line}
      out! "</#{tag}>"
    end
  end
  private
  def attrs_to_s(attrs={})
    attrs.to_a.map{|k,v| v.nil? ? "" : " #{k}='#{v.to_s.xml_escape}'"}.join
  end
end
