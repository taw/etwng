class SemanticFail < Exception
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
  def get_u4
    rv = @data[@ofs,4].unpack("V")[0]
    @ofs += 4
    rv
  end
  def get_i4
    rv = @data[@ofs,4].unpack("l")[0]
    @ofs += 4
    rv
  end
  def get_i2
    rv = @data[@ofs,2].unpack("s")[0]
    @ofs += 2
    rv
  end
  def get_float
    rv = @data[@ofs,4].unpack("f")[0]
    @ofs += 4
    rv.pretty_single
  end
  def get_u2
    rv = @data[@ofs,2].unpack("v")[0]
    @ofs += 2
    rv
  end
  def get_bytes(sz)
    rv = @data[@ofs, sz]
    @ofs += sz
    rv
  end
  def get_ascii
    get_bytes(get_u2)
  end
  def get_str
    get_bytes(get_u2*2).unpack("v*").pack("U*")
  end
  def lookahead_str
    end_ofs = @data[@ofs, 4].unpack("V")[0]
    la_ofs = @ofs + 4
    # puts "Lookahead until #{end_ofs}"
    while la_ofs < end_ofs
      tag = @data[la_ofs, 1].unpack("C")[0]
      # puts "At #{la_ofs}, tag #{"%02x" % tag}"
      if tag == 0x0e
        sz, = @data[la_ofs+1, 2].unpack("v")
        rv = @data[la_ofs+3, sz*2].unpack("v*").pack("U*")
        return nil if rv == ""
        return rv
      elsif tag <= 0x10
        sz = [3, 2, nil, nil, 5, nil, 2, 3, 5, nil, 5, nil, 9, 13, nil, nil, 3][tag]
        return nil unless sz
        la_ofs += sz
      elsif tag >= 0x40 and tag <= 0x4f
        la_ofs = @data[la_ofs, 4].unpack("V")[0]
      elsif tag == 0x80
        la_ofs = @data[la_ofs+4, 4].unpack("V")[0]
      elsif tag == 0x81
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
  def get_magic
    case magic = get_u4
    when 0xABCD
      [0xABCD]
    when 0xABCE
      a = get_u4
      b = get_u4
      raise "Incorrect ESF magic followup" unless a == 0
      [0xABCE, a, b]
    else
      raise "Incorrect ESF magic: %X" % magic
    end
  end
  def get_node_types
    (0...get_u2()).map{ get_ascii.to_sym }
  end
  def get_ofs_bytes
    get_bytes(get_u4 - @ofs)
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
  def get_00!
    [:i2, get_i2]
  end
  def get_01!
    [:bool, get_bool]
  end
  def get_04!
    [:i4, get_i4]
  end
  def get_06!
    [:byte, get_byte]
  end
  def get_07!
    [:u2, get_u2]
  end
  def get_08!
    [:u4, get_u4]
  end
  def get_0a!
    [:flt, get_float]
  end
  def get_0c!
    [:v2, get_float, get_float]
  end
  def get_0d!
    [:v3, get_float, get_float, get_float]
  end
  def get_0e!
    [:s, get_str]
  end
  def get_0f!
    [:asc, get_ascii]
  end
  def get_10!
    [:u2x, get_u2]
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
end

module EsfParserSemantic
  def get_rec_contents_dynamic
    out     = []
    end_ofs = get_u4
    while @ofs < end_ofs
      out.push send(@esf_type_handlers_get[get_byte])
    end
    out
  end
  
  def get_value!
    send(@esf_type_handlers_get[get_byte])
  end

  def get_rec_contents(*expect_types)
    out     = []
    end_ofs = get_u4
    while @ofs < end_ofs
      t, *v = send(@esf_type_handlers_get[get_byte])
      raise SemanticFail.new unless t == expect_types.shift
      out.push *v
    end
    out
  end
  def get_81!
    node_type, version = get_node_type_and_version
    ofs_end   = get_u4
    count     = get_u4
    [[:ary, node_type, version], *(0...count).map{ get_rec_contents_dynamic }]
  end

  def get_80!
    node_type, version = get_node_type_and_version
    [[:rec, node_type, version], *get_rec_contents_dynamic]
  end

  def get_ary_contents(*expect_types)
    data = []
    ofs_end   = get_u4
    count     = get_u4
    data.push get_rec_contents(*expect_types) while @ofs < ofs_end
    data
  end

  def get_ary_contents_dynamic
    data = []
    ofs_end   = get_u4
    count     = get_u4
    data.push get_rec_contents_dynamic while @ofs < ofs_end
    data
  end
  
  def try_semantic(node_type)
    begin
      save_ofs = @ofs
      yield
    rescue SemanticFail
      pp [:semantic_rollback, @ofs, save_ofs, node_type]
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
    @magic      = get_magic
    @node_types = with_temp_ofs(get_u4) { get_node_types }
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
