require "lib/binary_stream"
require "lib/converter"

class RigidModelBoundsConverter < Converter
  def pack_data(data)
    stream.packed("ffffff", data)
  end
  
  def unpack_data
    stream.packed("ffffff")
  end
end
