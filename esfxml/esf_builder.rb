require "default_versions"

class EsfBuilder
  attr_reader :data
  attr_reader :type_codes
  def initialize
    @data             = ""
    @adjust_ofs       = []
    @adjust_children  = []
    @children         = []
    @type_codes       = Hash.new{|ht,k| raise "Unknown node name #{k.inspect}"}
    @node_types       = []
  end
  def add_str_index(str, idx)
    @str_table << [str, idx]
    @str_lookup[str] = idx
    @str_max = [@str_max, idx].max
  end
  def add_asc_index(str, idx)
    @asc_table << [str, idx]
    @asc_lookup[str] = idx
    @asc_max = [@asc_max, idx].max
  end
  def add_type_code(name)
    raise "Name already set: #{name}" if @type_codes.has_key?(name)
    @type_codes[name] = @type_codes.size
    @node_types << name
  end
  def put_yes
    @data << "\x01\x01"
  end
  def put_no
    @data << "\x01\x00"
  end
  def put_bool(val)
    @data << (val ? "\x01\x01" : "\x01\x00")
  end
  def put_v2(x,y)
    @data << [0x0c, x, y].pack("Cff")
  end
  def put_v3(x,y,z)
    @data << [0x0d, x, y, z].pack("Cfff")
  end
  def put_byte(val)
    @data << "\x06"
    @data << [val].pack("C")
  end
  def put_flt(val)
    @data << "\x0a"
    @data << [val].pack("f")
  end
  def put_fix(val)
    put_i((1048576.0 * val).round.to_i)
  end
  def put_i2(val)
    @data << "\x00"
    @data << [val].pack("v")
  end
  def put_u2(val)
    @data << "\x07"
    @data << [val].pack("v")
  end
  def put_u2x(val)
    @data << "\x10"
    @data << [val].pack("v")
  end
  def put_u2z(val)
    @data << "\x03"
    @data << [val].pack("v")
  end
  def put_i(val)
    @data << "\x04"
    @data << [val].pack("V")
  end
  def put_u(val)
    @data << "\x08"
    @data << [val].pack("V")
  end
  def asc_lookup(str)
    unless @asc_lookup[str]
      @asc_max += 1
      @asc_lookup[str] = @asc_max
      @asc_table << [str, @asc_max]
    end
    return @asc_lookup[str]
  end
  def str_lookup(str)
    unless @str_lookup[str]
      @str_max += 1
      @str_lookup[str] = @str_max
      @str_table << [str, @str_max]
    end
    return @str_lookup[str]
  end
  def put_s(str)
    if @abcf
      @data << "\x0e"
      @data << [str_lookup(str)].pack("V")
    else
      @data << "\x0e"
      uchars = str.unpack("U*")
      @data << [uchars.size, *uchars].pack("v*")
    end
  end
  def put_asc(str)
    if @abcf
      @data << "\x0f"
      @data << [asc_lookup(str)].pack("V")
    else
      @data << "\x0f"
      @data << [str.size].pack("v")
      @data << str
    end
  end
  def put_str_ary(strs)
    raise "Tag type <str_ary> requires ESF version ABCF (S2TW) or newer" unless @abcf
    @data << "\x4e"
    @data << [@data.size + 4 + strs.size*4].pack("V")
    @data << strs.map{|str| str_lookup(str)}.pack("V*")
  end
  def put_asc_ary(strs)
    raise "Tag type <asc_ary> requires ESF version ABCF (S2TW) or newer" unless @abcf
    @data << "\x4f"
    @data << [@data.size + 4 + strs.size*4].pack("V")
    @data << strs.map{|str| asc_lookup(str)}.pack("V*")
  end
  def put_4x(code, ary_data)
    @data << code
    @data << [@data.size + 4 + ary_data.size].pack("V")
    @data << ary_data
  end
  def put_u4_ary(elems)
    put_4x("\x48", elems.pack("V*"))
  end
  def put_i4_ary(elems)
    put_4x("\x44", elems.pack("V*"))
  end
  def put_i2_ary(elems)
    put_4x("\x40", elems.pack("v*"))
  end
  def put_u2_ary(elems)
    put_4x("\x47", elems.pack("v*"))
  end
  def put_u2z_ary(elems)
    put_4x("\x43", elems.pack("v*"))
  end
  def put_flt_ary(elems)
    put_4x("\x4a", elems.pack("f*"))
  end
  def put_v2_ary(elems) # Contrary to name, elems contains floats
    put_4x("\x4c", elems.pack("f*"))
  end
  def put_v3_ary(elems) # Contrary to name, elems contains floats
    put_4x("\x4d", elems.pack("f*"))
  end
  def put_bool_ary(elems) # Contrary to name, elems contains ints
    put_4x("\x41", elems.pack("C*"))
  end
  def start_rec(type_str, version_str)
    type_code = @type_codes[type_str]
    version = version_str ? version_str.to_i : DefaultVersions[type_str.to_sym]
    @data << [0x80, type_code, version].pack("CvC")
    push_marker_ofs
  end
  def end_rec
    pop_marker_ofs
  end
  def start_elem
    inc_children
    push_marker_ofs
  end
  def start_ary(type_str, version_str)
    type_code = @type_codes[type_str]
    version = version_str ? version_str.to_i : DefaultVersions[type_str.to_sym]
    @data << [0x81, type_code, version].pack("CvC")
    push_marker_ofs
    push_marker_children
  end
  def end_ary
    pop_marker_children
    pop_marker_ofs
  end
  def start_esf(magic)
    @data << magic.pack("V*")
    @abcf = (magic[0] == 0xabcf)
    @str_table  = []
    @str_lookup = {}
    @str_max    = -1
    @asc_table  = []
    @asc_lookup = {}
    @asc_max    = -1
    push_marker_ofs
  end
  def end_esf
    pop_marker_ofs
    @data << [@node_types.size].pack("v")
    @node_types.each do |nn|
      @data << [nn.size].pack("v")
      @data << nn
    end
    if @abcf
      @data << [@str_table.size].pack("V")
      @str_table.each do |str,i|
        uchars = str.unpack("U*")
        @data << [uchars.size].pack("v")
        @data << uchars.pack("v*")
        @data << [i].pack("V")
      end
      @data << [@asc_table.size].pack("V")
      @asc_table.each do |str,i|
        @data << [str.size].pack("v")
        @data << str
        @data << [i].pack("V")
      end
    end
  end

# private
  def inc_children
    @children[-1] += 1
  end
  def put(bytes)
    @data << bytes
  end
  def push_marker_ofs
    @adjust_ofs << @data.size
    @data << "\x00\x00\x00\x00"
  end
  def push_marker_children
    @adjust_children << @data.size
    @children << 0
    @data << "\x00\x00\x00\x00"
  end
  def pop_marker_ofs
    @data[@adjust_ofs.pop, 4] = [@data.size].pack("V")
  end
  def pop_marker_children
    @data[@adjust_children.pop, 4] = [@children.pop].pack("V")
  end
end
