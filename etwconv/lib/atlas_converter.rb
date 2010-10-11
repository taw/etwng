require "lib/binary_stream"
require "lib/converter"

class AtlasConverter < Converter
  def pack_data(data)
    stream.magic "\x01\x00\x00\x00"
    stream.magic "\x00\x00\x00\x00"
    stream.u4_ary(data) do |s1,s2,dat|
      stream.packed("Z512", [s1.to_utf16])
      stream.packed("Z512", [s2.to_utf16])
      stream.packed("ffffff", dat)
    end
  end
  
  def unpack_data
    stream.magic "\x01\x00\x00\x00"
    stream.magic "\x00\x00\x00\x00"
    stream.u4_ary do
      [
        stream.get(512).from_utf16.sub(/\x00*\z/, ""),
        stream.get(512).from_utf16.sub(/\x00*\z/, ""),
        stream.packed("ffffff"),
      ]
    end
  end
end
