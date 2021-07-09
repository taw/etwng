class XMLBuilder
  def initialize(path)
    @stack = []
    path.open("w") do |fh|
      @output = fh
      yield(self)
    end
  end

  def out!(s)
    @output.puts("  " * @stack.size + s)
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

  def attrs_to_s(attrs={})
    attrs.to_a.map{|k,v| v.nil? ? "" : " #{k}=\"#{v.to_s.xml_escape}\""}.sort.join
  end
end
