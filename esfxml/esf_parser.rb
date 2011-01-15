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
    return nil unless @data[@ofs+4, 1] == "\x0e"
    sz, = @data[@ofs+5, 2].unpack("v")
    @data[@ofs+7, sz*2].unpack("v*").pack("U*")
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
  def get_node_types
    (0...get_u2()).map{ get_ascii.to_sym }
  end
  def with_temp_ofs(tmp)
    orig = @ofs
    begin
      @ofs = tmp
      yield
    ensure
      @ofs = orig
    end
  end
  def get_ofs_bytes
    get_bytes(get_u4 - @ofs)
  end
  def size
    @data.size
  end
end

module EsfDefaultConvert
  def convert_00!
    @xmlout.out!("<i2>#{get_i2}</i2>")
  end
  def convert_01!
    @xmlout.out!(get_bool ? "<yes/>" : "<no/>")
  end
  def convert_04!
    @xmlout.out!("<i>#{get_i4}</i>")
  end
  def convert_06!
    @xmlout.out!("<byte>#{get_byte}</byte>")
  end
  def convert_07!
    @xmlout.out!("<u2>#{get_u2}</u2>")
  end
  def convert_08!
    @xmlout.out!("<u>#{get_u4}</u>")
  end
  def convert_0a!
    @xmlout.out!("<flt>#{get_float.pretty_single}</flt>")
  end
  def convert_0c!
    @xmlout.out!("<v2 x='#{get_float.pretty_single}' y='#{get_float.pretty_single}'/>")
  end
  def convert_0d!
    @xmlout.out!("<v3 x='#{get_float.pretty_single}' y='#{get_float.pretty_single}' z='#{get_float.pretty_single}'/>")
  end
  def convert_0e!
    @xmlout.out!("<s>#{get_str.xml_escape}</s>")
  end
  def convert_0f!
    @xmlout.out!("<asc>#{get_ascii.xml_escape}</asc>")
  end
  def convert_10!
    @xmlout.out!("<u2x>#{get_u2}</u2x>")
  end
  def convert_4x!(tag)
    data = get_ofs_bytes
    if data.empty?
      @xmlout.out!("<#{tag}/>")
    else
      @xmlout.out!("<#{tag}>#{yield(data)}</#{tag}>")
    end
  end
  def convert_40!
    convert_4x!("bin0", &:to_hex_dump)
  end
  def convert_41!
    convert_4x!("bin1", &:to_hex_dump)
  end
  def convert_42!
    convert_4x!("bin2", &:to_hex_dump)
  end
  def convert_43!
    convert_4x!("bin3", &:to_hex_dump)
  end
  def convert_44!
    convert_4x!("i4_ary"){|data| data.unpack("l*").join(" ")}
  end
  def convert_45!
    convert_4x!("bin5", &:to_hex_dump)
  end
  def convert_46!
    convert_4x!("bin6", &:to_hex_dump)
  end
  def convert_47!
    convert_4x!("u2_ary"){|data| data.unpack("v*").join(" ")}
  end
  def convert_48!
    convert_4x!("u4_ary"){|data| data.unpack("V*").join(" ")}
  end
  def convert_49!
    convert_4x!("bin9", &:to_hex_dump)
  end
  def convert_4a!
    convert_4x!("flt_ary", &:to_flt_dump)
  end
  def convert_4b!
    convert_4x!("binB", &:to_hex_dump)
  end
  def convert_4c!
    data = get_ofs_bytes.unpack("f*").map(&:pretty_single)
    if data.empty?
      @xmlout.out!("<v2_ary/>")
    else
      @xmlout.out!("<v2_ary>")
      @xmlout.out!(" #{data.shift},#{data.shift}") until data.empty?
      @xmlout.out!("</v2_ary>")
    end
  end
  def convert_4d!
    data = get_ofs_bytes.unpack("f*").map(&:pretty_single)
    if data.empty?
      @xmlout.out!("<v3_ary/>")
    else
      @xmlout.out!("<v3_ary>")
      @xmlout.out!(" #{data.shift},#{data.shift},#{data.shift}") until data.empty?
      @xmlout.out!("</v3_ary>")
    end
  end
  def convert_4e!
    convert_4x!("binE", &:to_hex_dump)
  end
  def convert_4f!
    convert_4x!("binF", &:to_hex_dump)
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
