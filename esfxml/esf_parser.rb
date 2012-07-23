class SemanticFail < Exception
end
class QuietSemanticFail < SemanticFail
end

class Float
  def pretty_single
    return self if nan?
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
  def get_ofs_end
    if @abca
      rv = 0
      while true
        b = @data[@ofs]
        rv = (rv << 7) + (b & 0x7f)
        @ofs += 1
        break if b & 0x80 == 0
      end
      @ofs + rv
    else
      get_u
    end
  end
  def get_item_count
    rv = 0
    while true
      b = @data[@ofs]
      rv = (rv << 7) + (b & 0x7f)
      @ofs += 1
      break if b & 0x80 == 0
    end
    rv
  end
  def get_ofs_end_and_item_count
    if @abca
      # Position of ofs_end is relative to end of item_count
      # which is a weird way to encode things
      ofs_end = get_item_count
      item_count = get_item_count
      [ofs_end + @ofs, item_count]
    else
      [get_u, get_u]
    end
  end
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
  def get_i8
    rv = @data[@ofs,8].unpack("q")[0]
    @ofs += 8
    rv
  end
  def get_u8
    rv = @data[@ofs,8].unpack("Q")[0]
    @ofs += 8
    rv
  end
  def get_i2
    rv = @data[@ofs,2].unpack("s")[0]
    @ofs += 2
    rv
  end
  def get_flt
    rv = @data[@ofs,4].unpack("f")[0].pretty_single
    @ofs += 4
    rv
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
  LookaheadTypeTable = [
    nil, :bool, :i1, :i2, :i, :i8, :byte, :u2,    # 00 - 07
    :u, :u8, :flt, :double, :v2, :v3, :s, :asc,   # 08 - 0f
    :angle, nil, :bool, :bool, :u, :u, :u, :u,    # 10 - 17
    :u, :i, :i, :i, :i, :flt, nil, nil,           # 18 - 1f
    nil, nil, nil, nil, nil, nil, nil, nil,       # 20 - 27
    nil, nil, nil, nil, nil, nil, nil, nil,       # 28 - 2f
    nil, nil, nil, nil, nil, nil, nil, nil,       # 30 - 37
    nil, nil, nil, nil, nil, nil, nil, nil,       # 38 - 3f

    # These don't necessarily convert well yet, especially 50+... 
    nil, :bool_ary, :i1_ary, :i2_ary, :i_ary, :i8_ary, :byte_ary, :u2_ary,      # 40 - 47
    :u_ary, :u8_ary, :flt_ary, :double_ary, :v2_ary, :v3_ary, :s_ary, :asc_ary, # 48 - 4f
    :angle_ary, nil, :bool_ary, :bool_ary, :u_ary, :u_ary, :u_ary, :u_ary,      # 40 - 47
    :u_ary, :i_ary, :i_ary, :i_ary, :i_ary, :flt_ary, nil, nil,                 # 48 - 4f
  ]
  def lookahead_type
    LookaheadTypeTable[@data[@ofs]]
  end
  def lookahead_str
    save_ofs = @ofs
    ofs_end = get_ofs_end
  
    # Only single <rec> inside <rec>
    # Just ignore existence of container, and see what's inside
    if @ofs < ofs_end
      if @abca
        if @data[@ofs] >= 0x80 and @data[@ofs] <= 0xbf
          save_ofs2 = @ofs
          get_rec_header!
          @ofs = save_ofs2 unless ofs_end == get_ofs_end
        end
      else
        if @data[@ofs] == 0x80 and @data[@ofs+4, 4].unpack("V")[0] == ofs_end
          @ofs += 8
        end
      end
    end
    
    while @ofs < ofs_end
      tag = get_byte
      if tag == 0x0e
        if @abcf
          return @str_lookup[get_u]
        else
          rv = get_s
          return nil if rv == ""
          if rv.size > 128
            puts "Warning: Too long name suggested for file name at #{save_ofs}/#{@ofs}: #{rv.inspect}"
            return nil
          end
          return rv
        end
      elsif tag <= 0x20
        sz = [
          nil, 1, 0, 2, 4, 8, 1, 2,
          4, 8, 4, 8, 8, 12, nil, nil,
          2, nil, 0, 0, 0, 0, 1, 2, 3,
          0, 1, 2, 3, 0,
        ][tag]
        return nil unless sz
        @ofs += sz
      elsif tag >= 0x40 and tag <= 0x5f
        @ofs = get_ofs_end 
      elsif !@abca and (tag == 0x80 or tag == 0x81)
        @ofs += 3
        @ofs = get_ofs_end
      elsif @abca and (tag >= 0x80 and tag <= 0xbf)
        @ofs -= 1
        get_rec_header!
        @ofs = get_ofs_end
      elsif @abca and (tag >= 0xc0 and tag <= 0xff)
        @ofs -= 1
        get_ary_header!
        @ofs = get_ofs_end_and_item_count[0]
      else
        warn "str_lookup_fail %02x" % tag
        return nil
      end
    end
    return nil
  ensure
    @ofs = save_ofs
  end
  def get_byte
    rv = @data[@ofs]
    @ofs += 1
    rv
  end
  alias_method :get_u1, :get_byte
  def get_i1
    rv = @data[@ofs,1].unpack("c")[0]
    @ofs += 1
    rv
  end
  def get_u3
    rv = ("\x00"+@data[@ofs,3]).unpack("N")[0]
    # warn "Not tested U:#{@data[@ofs,3].unpack("C*")*' '} U:#{rv}"
    @ofs += 3
    rv
  end
  def get_i3
    # "l>" "l<" only work in 1.9, not 1.8.7
    if @data[@ofs] >= 128
      rv = ("\xFF"+@data[@ofs,3]).unpack("N")[0] - 0x1_0000_0000
    else
      rv = ("\x00"+@data[@ofs,3]).unpack("N")[0]
    end
    # warn "Not tested I:#{@data[@ofs,3].unpack("C*")*' '} I:#{rv}"
    @ofs += 3
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
    when 0xABCA
      @abcf = true
      @abca = true
      a = get_u
      b = get_u
      raise "Incorrect ESF magic followup" unless a == 0
      @magic = [0xABCA, a, b]
    else
      raise "Incorrect ESF magic: %X" % magic
    end
  end
  def parse_node_types
    @node_types = (0...get_u2).map{ get_ascii.to_sym }
    @padding = nil
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
    if @ofs != @data.size
      padding = get_bytes(@data.size - @ofs)
      if padding == "\x00" * padding.size
        @padding = padding.size
      else
        raise "Extra non-zero data past end of file"
      end
    end
  end
  def get_ofs_bytes
    if @abca
      get_bytes(get_item_count)
    else
      get_bytes(get_u - @ofs)
    end
  end
  def get_node_type_and_version
    node_type = @node_types[get_u2]
    version   = get_byte
    version   = nil if version == DefaultVersions[node_type]
    [node_type, version]
  end
  # PRECONDITION: ofs one byte after where it should be !!!
  def get_node_type_and_version_abca
    # Yes, it's reverse endian
    a, = @data[@ofs-1, 2].unpack("n")
    @ofs += 1
    version = (a >> 9) & 0x0f
    node_type = @node_types[a & 0x1ff]
    version   = nil if version == DefaultVersions[node_type]
    [node_type, version]
  end
  def size
    @data.size
  end
  
  ### May as well go to String#unpack
  def unpack_u3be_ary(str)
    rv = []
    xofs = 0
    while xofs < str.size
      rv << ("\x00"+str[xofs,3]).unpack("N")[0]
      xofs += 3
    end
    rv
  end
   
  def unpack_i3be_ary(str)
    rv = []
    xofs = 0
    while xofs < str.size
      if str[xofs] >= 128
        rv << ("\xFF"+str[xofs,3]).unpack("N")[0] - 0x1_0000_0000
      else
        rv << ("\x00"+str[xofs,3]).unpack("N")[0]
      end
      xofs += 3
    end
    rv
  end
end

module EsfGetData
  def get_01!
    [:bool, get_bool]
  end
  def get_02!
    [:i1, get_i1]
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
  def get_12!
    [:bool, true]
  end
  def get_13!
    [:bool, false]
  end
  def get_14!
    [:u, 0]
  end
  def get_15!
    [:u, 1]
  end
  def get_16!
    [:u, get_u1]
  end
  def get_17!
    [:u, get_u2]
  end
  def get_18!
    [:u, get_u3]
  end
  def get_19!
    [:i, 0]
  end
  def get_1a!
    [:i, get_i1]
  end
  def get_1b!
    [:i, get_i2]
  end
  def get_1c!
    [:i, get_i3]
  end
  def get_1d!
    [:flt, 0.0]
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
  def get_50!
    [:bin10, get_ofs_bytes]
  end
  def get_51!
    [:bin11, get_ofs_bytes]
  end
  def get_52!
    [:bin12, get_ofs_bytes]
  end
  def get_53!
    [:bin13, get_ofs_bytes]
  end
  def get_54!
    [:bin14, get_ofs_bytes]
  end
  def get_55!
    [:bin15, get_ofs_bytes]
  end
  def get_56!
    [:bin16, get_ofs_bytes]
  end
  def get_57!
    [:bin17, get_ofs_bytes]
  end
  def get_58!
    [:bin18, get_ofs_bytes]
  end
  def get_59!
    [:bin19, get_ofs_bytes]
  end
  def get_5a!
    [:bin1a, get_ofs_bytes]
  end
  def get_5b!
    [:bin1b, get_ofs_bytes]
  end
  def get_5c!
    [:bin1c, get_ofs_bytes]
  end
  def get_5d!
    [:bin1d, get_ofs_bytes]
  end
  def get_5e!
    [:bin1e, get_ofs_bytes]
  end
  def get_5f!
    [:bin1f, get_ofs_bytes]
  end
end

module EsfParserSemantic
  def get_rec_contents_dynamic
    types   = []
    data    = []
    ofs_end = get_ofs_end
    while @ofs < ofs_end
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
    ofs_end = get_ofs_end
    while @ofs < ofs_end
      t, d = send(@esf_type_handlers_get[get_byte])
      raise SemanticFail.new unless t == expect_types.shift
      data << d
    end
    data
  end
  
  # Disabled in ABCA mode
  def get_81!
    raise "This code is supposed to be disabled in ABCA mode" if @abca
    node_type, version = get_node_type_and_version
    ofs_end, count = get_u, get_u
    [[:ary, node_type, version], (0...count).map{ get_rec_contents_dynamic }]
  end

  # Disabled in ABCA mode
  def get_80!
    raise "This code is supposed to be disabled in ABCA mode" if @abca
    node_type, version = get_node_type_and_version
    [[:rec, node_type, version], get_rec_contents_dynamic]
  end

  # Low level function to parse record header without parsing record itself
  # Returns [node_type, version] or [nil, nil] if not a record
  # This API is pretty awful, but it's only used by lookahead_faction_ids and lookahead_str
  # @ofs at first byte of header (0x80)!
  def get_rec_header!
    if @abca
      return [nil, nil] unless get_byte.between?(0x80, 0xbf)
      if @ofs == 0x11 or @data[@ofs-1] & 0x20 != 0
        get_node_type_and_version
      else
        get_node_type_and_version_abca
      end
    else
      return [nil, nil] unless get_byte == 0x80
      get_node_type_and_version
    end
  end

  # Another ridiculous API
  # @ofs at first byte of header (0x81/0xc0)!
  def get_ary_header!
    if @abca
      return [nil, nil] unless get_byte.between?(0xc0, 0xff)
      if @data[@ofs-1] & 0x20 != 0
        node_type, version = get_node_type_and_version
      else
        node_type, version = get_node_type_and_version_abca
      end
    else
      return [nil, nil] unless get_byte == 0x81
      get_node_type_and_version
    end
  end


  def get_abca_ary!
    if @data[@ofs-1] & 0x20 != 0
      node_type, version = get_node_type_and_version
    else
      node_type, version = get_node_type_and_version_abca
    end
    ofs_end, count = get_ofs_end_and_item_count
    [[:ary, node_type, version], (0...count).map{ get_rec_contents_dynamic }]
  end
  
  def get_abca_rec!
    # Special case root node, since it follows the old style for some reason
    if @ofs == 0x11 or @data[@ofs-1] & 0x20 != 0
      node_type, version = get_node_type_and_version
    else
      node_type, version = get_node_type_and_version_abca
    end
    [[:rec, node_type, version], get_rec_contents_dynamic]
  end

  def get_ary_contents(*expect_types)
    data = []
    ofs_end, count = get_ofs_end_and_item_count
    data.push get_rec_contents(*expect_types) while @ofs < ofs_end
    data
  end

  def get_ary_contents_dynamic
    data = []
    ofs_end, count = get_ofs_end_and_item_count
    data.push get_rec_contents_dynamic while @ofs < ofs_end
    data
  end
  
  def try_semantic(node_type)
    @semantic_stats[node_type][0] += 1
    begin
      save_ofs = @ofs
      yield
    rescue QuietSemanticFail
      # Simple fall-through, used for some lookahead
      @semantic_stats[node_type][1] += 1
      @ofs = save_ofs
    rescue SemanticFail
      # This is debug only, it's normally perfectly safe
      # puts "Semantic conversion of #{node_type}(#{save_ofs}..#{@ofs}) failed, falling back to low-level conversion"
      @semantic_stats[node_type][2] += 1
      @ofs = save_ofs
    end
  end
end

class EsfParser
  include EsfBasicBinaryOps
  include EsfGetData
  include EsfParserSemantic

  attr_accessor :ofs
  attr_reader :magic, :padding, :node_types

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
    @semantic_stats = Hash.new{|ht,k| ht[k] = [0,0,0]}
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
    if @abca
      (0x80..0xbf).each{|i|
        out[i] = :get_abca_rec!
      }
      (0xc0..0xff).each{|i|
        out[i] = :get_abca_ary!
      }
    end
    out
  end
end
