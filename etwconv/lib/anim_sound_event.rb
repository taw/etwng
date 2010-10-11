require "lib/binary_stream"
require "lib/converter"

class AnimSoundEventConverter < Converter
  def pack_data(data)
    stream.u4_ary(data) do |subdata|
      stream.u4_ary(subdata) do |sample|
        stream.packed("fV", sample)
      end
    end
  end
  
  def unpack_data
    stream.u4_ary do
      stream.u4_ary do
        stream.packed("fV")
      end
    end
  end
end
