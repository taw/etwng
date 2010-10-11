require "lib/binary_stream"
require "lib/converter"

class SplnConverter < Converter
  def pack_data(stream, data)
    stream.magic "SPLN"
    stream.u4_ary(data) do |a,b,c,d|
      stream.u4(a)
      stream.str(b)
      stream.u4(c)
      stream.u4_ary(d) do |e|
        stream.packed("fff", e)
      end
    end
  end
  
  def unpack_data(stream)
    stream.magic "SPLN"
    stream.u4_ary do
      [stream.u4, stream.str, stream.u4, stream.u4_ary{ stream.packed("fff") } ]
    end
  end
end
