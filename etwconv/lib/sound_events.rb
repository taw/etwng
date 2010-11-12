require "lib/binary_stream"
require "lib/converter"

# Early attempt, broken
class SoundEventsConverter < Converter
  def pack_data(data)
    nil
  end
  
  def unpack_data
    pp stream.u4_ary { [stream.str, stream.flt] }
    pp stream.packed("V"*8)
    pp stream.packed("f"*11445)
    pp stream.u4
    415.times {|i|
      pp stream.packed("VV")
      pp stream.u4_ary { stream.str }
    }


    pp stream.packed("v"*16)
    pp stream.packed("v"*16)
    pp stream.packed("v"*16)
    pp stream.packed("v"*16)

    # pp stream.packed("f"*100)
    # pp stream.u4_ary{ stream.u4 }
    # pp stream.u4_ary{ stream.packed("fffffff") }
    out
  end
end
