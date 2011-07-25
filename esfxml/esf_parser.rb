class SemanticFail < Exception
end
class QuietSemanticFail < SemanticFail
end

class Float
  def pretty_single
    begin
      rv = (100_000.0 * self).round / 100_000.0
      return rv if self != rv and [self].pack("f") == [rv].pack("f")
      self
    rescue
      self
    end
  end
end

class String
  # Escape characters for output as XML attribute values (< > & ' ")
  def xml_escape
    replacements = {"<" => "&lt;", ">" => "&gt;", "&" => "&amp;", "\"" => "&quot;", "'" => "&apos;"}
    gsub(/([<>&\'\"])/) { replacements[$1] }
  end
  def to_hex_dump
    unpack("H2" * size).join(" ")
  end
  def to_flt_dump
    unpack("f*").map(&:pretty_single).join(" ")
  end
end

module EsfBasicBinaryOps
  def get_u
    rv = @data[@ofs,4].unpack("V")[0]
    @ofs += 4
    rv
  end
  def get_i
    rv = @data[@ofs,4].unpack("l")[0]
    @ofs += 4
    rv
  end
  def get_i2
    rv = @data[@ofs,2].unpack("s")[0]
    @ofs += 2
    rv
  end
  def get_flt
    rv = @data[@ofs,4].unpack("f")[0]
    @ofs += 4
    rv.pretty_single
  end
  def get_u2
    rv = @data[@ofs,2].unpack("v")[0]
    @ofs += 2
    rv
  end
  def get_angle
    raw = get_u2
    val = raw * 360.0 / 0x10000
    rounded = (val * 1000.0).round * 0.001
    reconv = (rounded * 0x10000 / 360.0).round.to_i
    if reconv == raw
      rounded
    else
      warn "BUG: Angle reconversion failure #{raw} #{val} #{rounded} #{reconv}"
      val
    end
  end
  def get_bytes(sz)
    rv = @data[@ofs, sz]
    @ofs += sz
    rv
  end
  def get_ascii
    get_bytes(get_u2)
  end
  def get_s
    get_bytes(get_u2*2).unpack("v*").pack("U*")
  end
  def lookahead_str
    end_ofs = @data[@ofs, 4].unpack("V")[0]
    la_ofs = @ofs + 4
    # Only single <rec> inside <rec>
    # Just ignore existence of container, and see what's inside
    if la_ofs < end_ofs and @data[la_ofs] == 0x80 and @data[la_ofs+4, 4].unpack("V")[0] == end_ofs
      la_ofs += 8
    end
    
    while la_ofs < end_ofs
      tag = @data[la_ofs]
      # puts "At #{la_ofs}, tag #{"%02x" % tag}"
      if tag == 0x0e
        if @abcf
          i, = @data[la_ofs+1, 4].unpack("V")
          return @str_lookup[i]
        else
          sz, = @data[la_ofs+1, 2].unpack("v")
          rv = @data[la_ofs+3, sz*2].unpack("v*").pack("U*")
          return nil if rv == ""
          if rv.size > 128
            puts "Warning: Too long name suggested for file name at #{@ofs}/#{la_ofs}: #{rv.inspect}"
            return nil
          end
          return rv
        end
      elsif tag <= 0x10
        sz = [3, 2, nil, 3, 5, nil, 2, 3, 5, nil, 5, nil, 9, 13, nil, nil, 3][tag]
        return nil unless sz
        la_ofs += sz
      elsif tag >= 0x40 and tag <= 0x4f
        la_ofs = @data[la_ofs+1, 4].unpack("V")[0]
      elsif tag == 0x80 or tag == 0x81
        la_ofs = @data[la_ofs+4, 4].unpack("V")[0]
      else
        return nil
      end
    end
    return nil
  end
  def get_byte
    rv = @data[@ofs]
    @ofs += 1
    rv
  end
  def get_bool
    case b = get_byte
    when 1
      true
    when 0
      false
    else
      warn "Weird boolean value: #{b}"
      true
    end
  end    
  def parse_magic
    case magic = get_u
    when 0xABCD
      @abcf = false
      @magic = [0xABCD]
    when 0xABCE
      @abcf = false
      a = get_u
      b = get_u
      raise "Incorrect ESF magic followup" unless a == 0
      @magic = [0xABCE, a, b]
    when 0xABCF
      @abcf = true
      a = get_u
      b = get_u
      raise "Incorrect ESF magic followup" unless a == 0
      @magic = [0xABCF, a, b]
    else
      raise "Incorrect ESF magic: %X" % magic
    end
  end
  def parse_node_types
    @node_types = (0...get_u2).map{ get_ascii.to_sym }
    if @abcf
      @str_table  = []
      @str_lookup = {}
      get_u.times do
        s = get_s
        i = get_u
        @str_lookup[i] = s
        @str_table << [s,i]
      end
      @asc_table  = []
      @asc_lookup = {}
      get_u.times do
        s = get_ascii
        i = get_u
        @asc_lookup[i] = s
        @asc_table << [s,i]
      end
    else
      @str_table = nil
      @asc_table = nil
    end
    raise "Extra data past end of file" if @ofs != @data.size
  end
  def get_ofs_bytes
    get_bytes(get_u - @ofs)
  end
  def get_node_type_and_version
    node_type = @node_types[get_u2]
    version   = get_byte
    version   = nil if version == DefaultVersions[node_type]
    [node_type, version]
  end
  def size
    @data.size
  end
end

module EsfGetData
  def get_01!
    [:bool, get_bool]
  end
  def get_03!
    [:i2, get_i2]
  end
  def get_04!
    [:i, get_i]
  end
  def get_06!
    [:byte, get_byte]
  end
  def get_07!
    [:u2, get_u2]
  end
  def get_08!
    [:u, get_u]
  end
  def get_0a!
    [:flt, get_flt]
  end
  def get_0c!
    [:v2, [get_flt, get_flt]]
  end
  def get_0d!
    [:v3, [get_flt, get_flt, get_flt]]
  end
  def get_0e!
    if @abcf
      [:s, @str_lookup[get_u]]
    else
      [:s, get_s]
    end
  end
  def get_0f!
    if @abcf
      [:asc, @asc_lookup[get_u]]
    else
      [:asc, get_ascii]
    end
  end
  def get_10!
    [:angle, get_angle]
  end
  def get_40!
    [:bin0, get_ofs_bytes]
  end
  def get_41!
    [:bin1, get_ofs_bytes]
  end
  def get_42!
    [:bin2, get_ofs_bytes]
  end
  def get_43!
    [:bin3, get_ofs_bytes]
  end
  def get_44!
    [:bin4, get_ofs_bytes]
  end
  def get_45!
    [:bin5, get_ofs_bytes]
  end
  def get_46!
    [:bin6, get_ofs_bytes]
  end
  def get_47!
    [:bin7, get_ofs_bytes]
  end
  def get_48!
    [:bin8, get_ofs_bytes]
  end
  def get_4a!
    [:flt_ary, get_ofs_bytes]
  end
  def get_4c!
    [:v2_ary, get_ofs_bytes]
  end
  def get_4d!
    [:v3_ary, get_ofs_bytes]
  end
  def get_4e!
    [:str_ary, get_ofs_bytes]
  end
  def get_4f!
    [:asc_ary, get_ofs_bytes]
  end
end

module EsfParserSemantic
  def get_rec_contents_dynamic
    types   = []
    data    = []
    end_ofs = get_u
    while @ofs < end_ofs
      t, d = send(@esf_type_handlers_get[get_byte])
      types << t
      data  << d
    end
    [types, data]
  end
  
  def get_value!
    send(@esf_type_handlers_get[get_byte])
  end
  
  def get_rec_contents(*expect_types)
    data    = []
    end_ofs = get_u
    while @ofs < end_ofs
      t, d = send(@esf_type_handlers_get[get_byte])
      raise SemanticFail.new unless t == expect_types.shift
      data << d
    end
    data
  end
  
  def get_81!
    node_type, version = get_node_type_and_version
    ofs_end, count = get_u, get_u
    [[:ary, node_type, version], (0...count).map{ get_rec_contents_dynamic }]
  end

  def get_80!
    node_type, version = get_node_type_and_version
    [[:rec, node_type, version], get_rec_contents_dynamic]
  end

  def get_ary_contents(*expect_types)
    data = []
    ofs_end, count = get_u, get_u
    data.push get_rec_contents(*expect_types) while @ofs < ofs_end
    data
  end

  def get_ary_contents_dynamic
    data = []
    ofs_end, count = get_u, get_u
    data.push get_rec_contents_dynamic while @ofs < ofs_end
    data
  end
  
  def try_semantic(node_type)
    begin
      save_ofs = @ofs
      yield
    rescue QuietSemanticFail
      # Simple fall-through, used for some lookahead
      @ofs = save_ofs
    rescue SemanticFail
      # This is debug only, it's normally perfectly safe
      puts "Semantic conversion of #{node_type}(#{save_ofs}..#{@ofs}) failed, falling back to low-level conversion"
      @ofs = save_ofs
    end
  end
end

class EsfParser
  include EsfBasicBinaryOps
  include EsfGetData
  include EsfParserSemantic

  attr_accessor :ofs
  attr_reader :magic, :node_types

  def with_temp_ofs(tmp)
    orig = @ofs
    begin
      @ofs = tmp
      yield
    ensure
      @ofs = orig
    end
  end

  def percent_done
    (100.0 * @ofs.to_f / @data.size)
  end
  
  def initialize(esf_fh)
    @data       = esf_fh.read
    @ofs        = 0
    parse_magic
    with_temp_ofs(get_u) { parse_node_types }
    @esf_type_handlers_get = setup_esf_type_handlers_get
  end

  def setup_esf_type_handlers_get
    out = Hash.new{|ht,node_type| raise "Unknown type 0x%02x at %d" % [node_type, ofs] }
    (0..255).each{|i|
      name = ("get_%02x!" % i).to_sym
      out[i] = name if respond_to?(name)
    }
    out
  end
end
