require "lib/binary_stream"
require "lib/converter"

class LocConverter < Converter
  def pack_data(data)
    stream.magic "\xff\xfe"
    stream.magic "LOC\x00"
    stream.u4_ary(data) do |data1|
      stream.u4_ary(data1) do |data2|
        stream.str(data2[0])
        stream.str(data2[1])
        stream.bool(data2[2])
      end
    end
  end
  
  def unpack_data
    stream.magic "\xff\xfe"
    stream.magic "LOC\x00"
    stream.u4_ary do
      stream.u4_ary do
        [stream.str, stream.str, stream.bool]
      end
    end
  end
end
