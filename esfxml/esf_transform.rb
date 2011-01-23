require "esf_parser"
require "esf_builder"

class EsfTransform < EsfParser
  attr_reader :esfout
  
  def initialize(file_in)
    super(file_in)
    @esfout = EsfBuilder.new
    @esfout.start_esf @magic
    node_types.each{|name|
      @esfout.add_type_code(name.to_s)
    }
    @esf_type_handlers_copy = setup_esf_type_handlers_copy
  end
  def setup_esf_type_handlers_copy
    out = Hash.new{|ht,node_type| raise "Unknown type 0x%02x at %d" % [node_type, ofs] }
    (0..255).each{|i|
      name = ("copy_%02x!" % i).to_sym
      out[i] = name if respond_to?(name)
    }
    out
  end
  def copy_00!
    @esfout.data << get_bytes(2)
  end
  def copy_01!
    @esfout.data << get_bytes(1)
  end
  def copy_04!
    @esfout.data << get_bytes(4)
  end
  def copy_06!
    @esfout.data << get_bytes(1)
  end
  def copy_07!
    @esfout.data << get_bytes(2)
  end
  def copy_08!
    @esfout.data << get_bytes(4)
  end
  def copy_0a!
    @esfout.data << get_bytes(4)
  end
  def copy_0c!
    @esfout.data << get_bytes(8)
  end
  def copy_0d!
    @esfout.data << get_bytes(12)
  end
  def copy_0e!
    szbuf = get_bytes(2)
    sz = szbuf.unpack("v")[0]
    @esfout.data << szbuf << get_bytes(sz * 2)
  end
  def copy_0f!
    szbuf = get_bytes(2)
    sz = szbuf.unpack("v")[0]
    @esfout.data << szbuf << get_bytes(sz)
  end
  def copy_10!
    @esfout.data << get_bytes(2)
  end

  def copy_40!
    @esfout.put_4x('', get_ofs_bytes)
  end
  def copy_41!
    @esfout.put_4x('', get_ofs_bytes)
  end
  def copy_42!
    @esfout.put_4x('', get_ofs_bytes)
  end
  def copy_43!
    @esfout.put_4x('', get_ofs_bytes)
  end
  def copy_44!
    @esfout.put_4x('', get_ofs_bytes)
  end
  def copy_45!
    @esfout.put_4x('', get_ofs_bytes)
  end
  def copy_46!
    @esfout.put_4x('', get_ofs_bytes)
  end
  def copy_47!
    @esfout.put_4x('', get_ofs_bytes)
  end
  def copy_48!
    @esfout.put_4x('', get_ofs_bytes)
  end
  def copy_49!
    @esfout.put_4x('', get_ofs_bytes)
  end
  def copy_4a!
    @esfout.put_4x('', get_ofs_bytes)
  end
  def copy_4b!
    @esfout.put_4x('', get_ofs_bytes)
  end
  def copy_4c!
    @esfout.put_4x('', get_ofs_bytes)
  end
  def copy_4d!
    @esfout.put_4x('', get_ofs_bytes)
  end

  def copy_80!
    node_type_and_version_buf = get_bytes(3)
    @esfout.data << node_type_and_version_buf
    ofs_end = get_u4
    @esfout.push_marker_ofs
    copy_value! while @ofs < ofs_end
    @esfout.pop_marker_ofs
  end
  def copy_81!
    node_type_and_version_buf = get_bytes(3)
    @esfout.data << node_type_and_version_buf
    ofs_end   = get_u4
    count     = get_u4
    @esfout.push_marker_ofs
    @esfout.push_marker_children
    count.times{
      @esfout.inc_children
      @esfout.push_marker_ofs
      ofs_end_elem = get_u4
      copy_value! while @ofs < ofs_end_elem
      @esfout.pop_marker_ofs
    }
    @esfout.pop_marker_children
    @esfout.pop_marker_ofs
  end
  def copy_value!
    tagbuf = get_bytes(1)
    @esfout.data << tagbuf
    send(@esf_type_handlers_copy[tagbuf.unpack("C")[0]])
  end
  def transform!
    copy_value!
    @esfout.end_esf
  end
end
