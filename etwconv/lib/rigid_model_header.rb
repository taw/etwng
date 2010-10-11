require "lib/binary_stream"
require "lib/converter"

class RigidModelHeaderConverter < Converter
  def pack_data(data)
    stream.magic "\xBC\xEA\x0f\x00"
    stream.u4_ary(data) do |subdata|
      stream.opt(subdata[0]) do
        stream.u4 subdata[0]
      end
      stream.packed("VVffffff", subdata[1..-1])
    end
  end
  
  def unpack_data
    stream.magic "\xBC\xEA\x0f\x00"
    stream.u4_ary do
      [stream.opt{ stream.u4 }, *stream.packed("VVffffff")]
    end
  end
end
