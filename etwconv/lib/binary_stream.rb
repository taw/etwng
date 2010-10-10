class BinaryStream
  attr_reader :data, :ofs
  
  def initialize(data)
    @data = data
    @ofs  = 0
  end

  def size
    @data.size
  end
  
  def eof?
    @data.size == @ofs
  end
  

  # Getting data
  # These functions should be verified by PlatformTest

  def get_byte
    get_unpack(1, "C")[0]
  end

  def get_u2
    get_unpack(2, "v")[0]
  end
  
  def get_u4
    get_unpack(4, "V")[0]
  end

  def get_f
    get_unpack(4, "f")[0]
  end

  def get_unpack(bytes, fmt)
    get_bytes(bytes).unpack(fmt)
  end

  def get_bytes(bytes)
    ensure_available!(bytes)
    rv, @ofs = @data[@ofs, bytes], @ofs+bytes
    rv
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
end

class BinaryStreamException < Exception
end
