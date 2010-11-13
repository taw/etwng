require "lib/binary_stream"
require "lib/converter"

# Early attempt, broken
class MarkersConverter < Converter
  def pack_data(data)
    data.each{|s,*d|
      stream.str(s)
      stream.packed("f"*16, d)
    }
  end
  
  def unpack_data
    out = []
    until stream.eof?
      out << [stream.str, *stream.packed("f"*16).map(&:pretty_single)]
      p out[-1]
    end
    out
  end
end
