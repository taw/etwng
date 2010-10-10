require "lib/platform"

class BinaryStream
  attr_reader :data, :ofs
  
  def initialize(data)
    @data     = data
    @ofs      = 0
  end

  def size
    @data.size
  end
  
  def eof?
    @data.size == @ofs
  end

  # Deal with error in formats
  def ensure_available!(bytes)
    raise BinaryStreamException.new("#{bytes} bytes requested but only #{@data.size-@ofs} available") if @data.size-@ofs < bytes
  end
  
  def ensure_file_size!(sz)
    raise BinaryStreamException.new("Expected file size #{sz} bytes, but actual is #{@data.size} bytes") unless sz == @data.size
  end

  def ensure_offset!(expected_ofs)
    raise BinaryStreamException.new("Expected file offset #{expected_ofs}, but actual is #{@ofs}") unless expected_ofs == @ofs
  end

  def ensure_eof!
    raise BinaryStreamException.new("Expected file offset #{@data.size} (EOF), but actual is #{@ofs}") unless @data.size == @ofs
  end
  
  def get_unpack(fmt)
    get(FmtSizes[fmt]).unpack(fmt)
  end

  def put_pack(fmt, data)
    @data << data.pack(fmt)
  end

  def get(bytes)
    ensure_available!(bytes)
    rv, @ofs = @data[@ofs, bytes], @ofs+bytes
    rv
  end

  def put(x)
    @data << x
  end

  def <<(x)
    @data << x
  end

  # Getting and putting data - convenient wrappers for most common functions
  # These functions should be verified by PlatformTest
  FmtNames.each{|name,fmt| 
     eval %Q[def get_#{name}; get(#{FmtSizes[fmt]}).unpack(#{fmt.inspect})[0]; end]
     eval %Q[def put_#{name}(arg); @data << [arg].pack(#{fmt.inspect}); end]
  }
end

class BinaryStreamException < Exception
end
