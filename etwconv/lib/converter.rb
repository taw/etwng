require "lib/binary_stream"

class Converter
  def pack(data)
    BinaryStreamWriter.open do |stream|
      pack_data(stream, data)
    end
  end

  def unpack(data)
    BinaryStreamReader.open(data) do |stream|
      unpack_data(stream)
    end
  end
end
