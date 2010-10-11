require "lib/binary_stream"
require "lib/converter"

# TODO: Refactor to take advantage of Converter/Stream features
class FarmFieldsTileTextureConverter < Converter
  def pack_data(stream, data)
    vers, data = data
    
    ofs = 8 + vers.size + 4 * data.size
    stream << vers
    stream.u4_ary(data) do |data_a, data_b|
      stream.u4 ofs
      ofs += 8 + data_a.size + data_b.size
    end
    stream.u4 ofs

    data.each do |data_a, data_b|
      stream.u4 data_a.size
      stream.u4 data_b.size
      stream << data_a
      stream << data_b
    end
  end

  def unpack_data(stream)
    begin
      pair_offsets = stream.u4_ary{ stream.u4 }
      file_size    = stream.u4
      stream.ensure_file_size!(file_size)
      vers = ""
    rescue BinaryStreamException
      stream.ofs = 0
      vers = stream.get(1)
      pair_offsets = stream.u4_ary{ stream.u4 }
      file_size    = stream.u4
      stream.ensure_file_size!(file_size)
    end
    
    data = pair_offsets.map{|ofs|
      stream.ensure_offset! ofs
      size_a = stream.u4
      size_b = stream.u4
      data_a = stream.get(size_a)
      data_b = stream.get(size_b)
      [data_a, data_b]
    }
    [vers, data]
  end
end
