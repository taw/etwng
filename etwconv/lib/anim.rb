require "lib/binary_stream"
require "lib/converter"

class AnimConverter < Converter
  def pack_data(data)
    stream.packed("ff", data[0])
    stream.u4_ary(data[1]) do |part|
      stream.str part[0]
      stream.i4 part[1]
    end
    stream.u4 data[2]

    data[3].each do |xxx|
      xxx.each do |yyy|
        stream.packed "ffffffffff", yyy
      end
    end

    stream.u4 data[4]
  end
  
  def unpack_data
    data = []
    data << stream.packed("ff")
    data << stream.u4_ary do
      [stream.str, stream.i4]
    end
    pieces = data[1].size
    
    data << (elems_per_piece = stream.u4)

    # Actually, any order is feasible
    # It's some 10xAxB but how exactly???
    data << (0...pieces).map{|i|
      (0...elems_per_piece).map{
        stream.packed("ffffffffff")
      }
    }

    data << stream.u4
    data
  end
end
