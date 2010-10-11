require "lib/binary_stream"
require "lib/converter"

# This is of course useless converter...
class EsfFile < Converter
  def pack_data(stream, data)
    # stream.magic "\xCE\xAB\x00\x00"
    stream.packed("VVVV", data[:abc])
    stream.put data[:item]
    stream.esf_nodenames(data[:ids])
  end
  
  def unpack_data(stream)
    # stream.magic "\xCE\xAB\x00\x00"
    m,a,b,c = stream.packed("VVVV")
    item = stream.get(c-16)
    ids = stream.esf_nodenames
    return {:ids => ids, :abc => [m,a,b,c], :item => item}
  end
end
