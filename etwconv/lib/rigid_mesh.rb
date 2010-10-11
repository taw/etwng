require "lib/binary_stream"
require "lib/converter"

class RigidMeshConverter < Converter
  def pack_mesh(data)
    stream.magic "\x78\x56\x34\x12"
    stream.u4_ary(data[0]) do |data2|
      stream.bool data2[0]
      stream.str data2[1]
    end
    stream.u4(data[1])
    stream.u4_ary(data[2]){|xx|
      stream.packed("f"*20, xx)
    }
    stream.u4_ary(data[3]){|xx|
      stream.u4(xx)
    }
  end

  def unpack_mesh
    stream.magic "\x78\x56\x34\x12"
    data = []
    data << stream.u4_ary do
      [stream.bool, stream.str]
    end
    data << stream.u4
    stream.error!("I think it should be 0") unless data[-1] == 0
    data << stream.u4_ary {
      stream.packed("f"*20)
    }
    data << stream.u4_ary{
      stream.u4
    }
    data
  end

  def pack_data(data)
    pack_mesh(data)
  end
  
  def unpack_data
    unpack_mesh
  end
end
