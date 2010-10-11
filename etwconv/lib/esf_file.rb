require "lib/binary_stream"
require "lib/converter"
require "lib/esf_basic_types"




# This is of course useless converter...
class EsfFile < Converter
  def initialize(stream)
    @stream = stream
    @tag_converters = Hash.new{|ht,k| raise "Bad ESF tag %02X" % k}.merge({
      0x00 => EsfConv00.new(stream),
      0x01 => EsfConv01.new(stream),
      0x04 => EsfConv04.new(stream),
      0x06 => EsfConv06.new(stream),
      0x07 => EsfConv07.new(stream),
      0x08 => EsfConv08.new(stream),
      0x0a => EsfConv0a.new(stream),
      0x0c => EsfConv0c.new(stream),
      0x0d => EsfConv0d.new(stream),
      0x0e => EsfConv0e.new(stream),
      0x0f => EsfConv0f.new(stream),
      0x10 => EsfConv10.new(stream),
      
    })
  end
  
  def pack_data(data)
    # stream.magic "\xCE\xAB\x00\x00"
    stream.put data[:magic].pack("V*")
    sz_ofs = stream.size
    stream.put "\x00\x00\x00\x00"
    stream.put data[:data]
    stream.data[sz_ofs, 4] = [stream.size].pack("V")

    stream.esf_nodenames(data[:nodenames])
  end

  # It would be an understatement to call it a horrible mess...
  def unpack_data
    magic = get_esf_magic
    nodenames_ofs = stream.u4
    data_ofs = stream.ofs
    
    stream.ofs = nodenames_ofs
    nodenames = stream.esf_nodenames
    stream.ensure_eof!
    
    stream.ofs = data_ofs

    data = get_values_until(stream, nodenames_ofs)

    stream.ensure_offset!(nodenames_ofs)
    stream.ofs = stream.size
    
    return {:magic => magic, :data => data, :nodenames => nodenames}
  end

  def get_value_as_xml
    @tag_converters[@stream.byte].to_xml
  end

  def get_value
    @tag_converters[@stream.byte].to_ruby
  end

  def get_values_until(stream, end_ofs)
    stream.get(end_ofs - stream.ofs)
  end
  
  def get_esf_magic
    m0 = stream.u4
    if m0 == 0xABCD
      [m0]
    elsif m0 == 0xABCE
      [m0, stream.u4, stream.u4]
    else
      raise BinaryStreamException.new("Incorrect ESF magic number: %08X" % m0)
    end
  end
end
