require "lib/binary_stream"

class FarmFieldsTileTextureConverter
  def pack(filepairs)
    headers = [filepairs.size]
    data = []
    ofs = 8 + 4 * filepairs.size
    filepairs.each{|data_a,data_b|
      headers << ofs
      ofs += 8 + data_a.size + data_b.size
      data << [data_a.size, data_b.size].pack("VV")
      data << data_a
      data << data_b
    }
    headers << ofs
    return headers.pack("V*") + data.join
  end
  
  def unpack(data)
    stream = BinaryStream.new(data)
    pair_count   = stream.get_u4
    pair_offsets = stream.get_unpack(4*pair_count, "V"*pair_count)
    file_size    = stream.get_u4
    stream.ensure_file_size!(file_size)
    results = pair_offsets.map{|ofs|
      stream.ensure_offset! ofs
      size_a, size_b = stream.get_unpack(8, "VV")
      [stream.get_bytes(size_a), stream.get_bytes(size_b)]
    }
    stream.ensure_eof!
    results
  end
end
