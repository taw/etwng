require "default_versions"

class EsfBuilder
  attr_reader :data
  attr_reader :type_codes
  def initialize
    @data             = ""
    @adjust_ofs       = []
    @adjust_children  = []
    @children         = []
    @type_codes       = Hash.new{|ht,k|
      # warn "Unknown node name #{k.inspect}"
      add_type_code(k)
    }
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
    rv = @type_codes[name] = @type_codes.size
    @node_types << name
    rv
  end
  def put_yes
    if @abca
      @data << "\x12"
    else
      @data << "\x01\x01"
    end
  end
  def put_no
    if @abca
      @data << "\x13"
    else
      @data << "\x01\x00"
    end
  end
  def put_bool(val)
    if @abca
      @data << (val ? "\x12" : "\x13")
    else
      @data << (val ? "\x01\x01" : "\x01\x00")
    end
  end
  def put_v2(x,y)
    @data << [0x0c, x, y].pack("Cff")
  end
  def put_v3(x,y,z)
    @data << [0x0d, x, y, z].pack("Cfff")
  end
  def put_byte(val)
    @data << "\x06" << [val].pack("C")
  end
  def put_flt(val)
    if @abca
      v = [val].pack("f")
      if v == "\x00\x00\x00\x00" # remember about negative -0.0
        @data << "\x1d"
      else
        @data << "\x0a" << v
      end
    else
      @data << "\x0a" << [val].pack("f")
    end
  end
  def put_fix(val)
    put_i((1048576.0 * val).round.to_i)
  end
  def put_i2(val)
    @data << "\x03" << [val].pack("v")
  end
  def put_i8(val)
    @data << "\x05" << [val].pack("q")
  end
  def put_u8(val)
    @data << "\x09" << [val].pack("Q")
  end
  def put_u2(val)
    @data << "\x07" << [val].pack("v")
  end
  def put_u2angle(val)
    @data << "\x10" << [val].pack("v")
  end
  def put_angle(val)
    put_u2angle((val * 0x10000 / 360.0).round.to_i)
  end
  def put_i(val)
    if @abca
      if val == 0
        @data << "\x19"
      elsif val <= 127 and val >= -128
        @data << "\x1a" << [val].pack("c")
      elsif val <= 0x7fff and val >= -0x8000
        @data << "\x1b" << [val].pack("v")
      else
        # FIXME: 3 byte encoding \x1c
        @data << "\x04" << [val].pack("V")
      end
    else
      @data << "\x04" << [val].pack("V")
    end
  end
  def put_u(val)
    if @abca
      if val == 0
        @data << "\x14"
      elsif val == 1
        @data << "\x15"
      elsif val <= 255
        @data << "\x16" << [val].pack("C")
      elsif val <= 0xffff
        @data << "\x17" << [val].pack("v")
      else
        # FIXME: 3 byte encoding \x18
        @data << "\x08" << [val].pack("V")
      end
    else
      @data << "\x08" << [val].pack("V")
    end
  end
  # ABCA only!
  def put_number(val)
    r = [val & 0x7f]
    val >>= 7
    while val != 0
      r << ((val & 0x7f) | 0x80)
      val >>= 7
    end
    @data << r.reverse.pack("C*")
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
    if @abca
      put_number(strs.size*4)
    else
      @data << [@data.size + 4 + strs.size*4].pack("V")
    end
    @data << strs.map{|str| str_lookup(str)}.pack("V*")
  end
  def put_asc_ary(strs)
    raise "Tag type <asc_ary> requires ESF version ABCF (S2TW) or newer" unless @abcf
    @data << "\x4f"
    if @abca
      put_number(strs.size*4)
    else
      @data << [@data.size + 4 + strs.size*4].pack("V")
    end
    @data << strs.map{|str| asc_lookup(str)}.pack("V*")
  end
  def put_4x(code, ary_data)
    @data << code
    if @abca
      put_number(ary_data.size)
    else
      @data << [@data.size + 4 + ary_data.size].pack("V")
    end
    @data << ary_data
  end
  def put_u4_ary(elems)
    put_4x("\x48", elems.pack("V*"))
  end
  def put_i4_ary(elems)
    put_4x("\x44", elems.pack("V*"))
  end
  def put_i2_ary(elems)
    put_4x("\x43", elems.pack("v*"))
  end
  def put_i1_ary(elems)
    put_4x("\x42", elems.pack("c*"))
  end
  def put_u2_ary(elems)
    put_4x("\x47", elems.pack("v*"))
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
    if @abca and @data.size != 16 # root node is somehow not following new rules
      raise "No idea how to encode that: #{type_code} #{version}" if type_code > 511 or version > 15
      @data << [0x8000 + (version << 9) + type_code].pack("n")
    else
      @data << [0x80, type_code, version].pack("CvC")
    end
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
    if @abca
      raise "No idea how to encode that: #{type_code} #{version}" if type_code > 511 or version > 15
      @data << [0xc000 + (version << 9) + type_code].pack("n")
    else
      @data << [0x81, type_code, version].pack("CvC")
    end
    push_marker_ofs
    push_marker_children
  end
  def end_ary
    pop_marker_children
    pop_marker_ofs
  end
  def start_esf(magic)
    @data << magic.pack("V*")
    @abcf = (magic[0] == 0xabcf or magic[0] == 0xabca)
    @abca = (magic[0] == 0xabca)
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
  # This is full of fail
  def encode_number_as_4_bytes(val)
    raise "Number too big to encode as 4 bytes - #{val}" if val > 0x0fffffff
    rv = [((val >> 21) & 0x7f) | 0x80, ((val >> 14) & 0x7f) | 0x80, ((val >> 7) & 0x7f) | 0x80, val & 0x7f].pack("C*")
  end
  def pop_marker_ofs
    if @abca and @adjust_ofs.size != 1 # root market works old style
      at = @adjust_ofs.pop
      @data[at, 4] = encode_number_as_4_bytes(@data.size - at - 4)
    else
      @data[@adjust_ofs.pop, 4] = [@data.size].pack("V")
    end
  end
  def pop_marker_children
    if @abca
      @data[@adjust_children.pop, 4] = encode_number_as_4_bytes(@children.pop)
    else
      @data[@adjust_children.pop, 4] = [@children.pop].pack("V")
    end
  end
end
