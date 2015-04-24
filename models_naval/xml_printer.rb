# Printer for a single XML output

class XMLPrinter
  attr_reader :out_buf, :rel_path
  def initialize(out_path, rel_path)
    @rel_path = rel_path
    @out_fh   = File.open(out_path, 'wb')
    # @out_fh.sync = true # for easier debugging
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
  def tag!(name, attrs=nil)
    attrs = attrs_to_s(attrs) if attrs
    if block_given?
      out! "<#{name}#{attrs}>"
      @stack << name
      yield
      @stack.pop
      out! "</#{name}>"
    else
      out! "<#{name}#{attrs}/>"
    end
  end
  def out!(str)
    @out_buf << @indent[@stack.size] << str << "\n"
    flush! if @out_buf.size > 1_000_000
    # flush! # for easier debugging
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
    attrs.to_a.map{|k,v| v.nil? ? "" : " #{k}=\"#{v.to_s.xml_escape}\""}.sort.join
  end
end
