require "lib/binary_stream"
require "lib/converter"

class DescModelConverter < Converter
  def pack_data(stream, data)
    stream.u4_ary(data) do |name, flts|
      stream.str(name)
      stream.packed("f"*16, flts)
    end
  end
  
  def unpack_data(stream)
    stream.u4_ary do
      [stream.str, stream.packed("f"*16)]
    end
  end
end
