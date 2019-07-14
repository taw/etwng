require "pgm"
require "default_versions"
require "xml_split"
require "esf_parser"
require "dir_builder"
require "esf_semantic_converter"

module EsfConvertBasic
  def convert_01!
    out!(get_bool ? "<yes/>" : "<no/>")
  end
  def convert_02!
    out!("<i1>#{get_i1}</i1>")
  end
  def convert_03!
    out!("<i2>#{get_u2}</i2>")
  end
  def convert_04!
    out!("<i>#{get_i}</i>")
  end
  def convert_05!
    out!("<int64>#{get_u8}</int64>")
  end
  def convert_06!
    out!("<byte>#{get_byte}</byte>")
  end
  def convert_07!
    out!("<u2>#{get_u2}</u2>")
  end
  def convert_08!
    out!("<u>#{get_u}</u>")
  end
  def convert_09!
    out!("<uint64>#{get_u8}</uint64>")
  end
  def convert_0a!
    val = get_flt
    if val.nan?
      out!("<fltnan>%08X</fltnan>" % [val].pack("f").unpack("V"))
    else
      out!("<flt>#{val}</flt>")
    end
  end
  def convert_0c!
    out!("<v2 x=\"#{get_flt}\" y=\"#{get_flt}\"/>")
  end
  def convert_0d!
    out!("<v3 x=\"#{get_flt}\" y=\"#{get_flt}\" z=\"#{get_flt}\"/>")
  end
  def convert_0e!
    if @abcf
      str = @str_lookup[get_u]
    else
      str = get_s
    end
    if str.empty?
      out!("<s/>")
    else
      out!("<s>#{str.xml_escape}</s>")
    end
  end
  def convert_0f!
    if @abcf
      str = @asc_lookup[get_u]
    else
      str = get_ascii
    end
    if str.empty?
      out!("<asc/>")
    else
      out!("<asc>#{str.xml_escape}</asc>")
    end
  end
  def convert_10!
    out!("<angle>#{get_angle}</angle>")
  end
  def convert_12!
    out!("<yes/>")
  end
  def convert_13!
    out!("<no/>")
  end
  def convert_14!
    out!("<u>0</u>")
  end
  def convert_15!
    out!("<u>1</u>")
  end
  def convert_16!
    out!("<u>#{get_u1}</u>")
  end
  def convert_17!
    out!("<u>#{get_u2}</u>")
  end
  def convert_18!
    out!("<u>#{get_u3}</u>")
  end
  def convert_19!
    out!("<i>0</i>")
  end
  def convert_1a!
    out!("<i>#{get_i1}</i>")
  end
  def convert_1b!
    out!("<i>#{get_i2}</i>")
  end
  def convert_1c!
    out!("<i>#{get_i3}</i>")
  end
  def convert_1d!
    out!("<flt>0.0</flt>")
  end
  def convert_21!
    out!("<x21>#{get_u}</x21>")
  end
  def convert_23!
    out!("<x23>#{get_u1}</x23>")
  end
  def convert_24!
    out!("<x24>#{get_u2}</x24>")
  end
  def convert_25!
    out!("<x25>#{get_u}</x25>")
  end
  def convert_4x!(tag)
    data = get_ofs_bytes
    if data.empty?
      out!("<#{tag}/>")
    else
      out!("<#{tag}>#{yield(data)}</#{tag}>")
    end
  end
  def convert_40!
    convert_4x!("bin0", &:to_hex_dump) # INVALID, no such type
  end
  def convert_41!
    convert_4x!("bool_ary"){|data| data.unpack("C*").join(" ")}
  end
  def convert_42!
    convert_4x!("i1_ary"){|data| data.unpack("c*").join(" ")}
  end
  def convert_43!
    convert_4x!("i2_ary"){|data| data.unpack("s*").join(" ")}
  end
  def convert_44!
    convert_4x!("i4_ary"){|data| data.unpack("l*").join(" ")}
  end
  def convert_45!
    convert_4x!("bin5", &:to_hex_dump) # 64-bit signed integer
  end
  def convert_46!
    convert_4x!("bin6", &:to_hex_dump) # 8-bit unsigned integer
  end
  def convert_47!
    convert_4x!("u2_ary"){|data| data.unpack("v*").join(" ")}
  end
  def convert_48!
    convert_4x!("u4_ary"){|data| data.unpack("V*").join(" ")}
  end
  def convert_49!
    convert_4x!("bin9", &:to_hex_dump) # 64-bit unsigned integer
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
      out!("<v2_ary/>")
    else
      out!("<v2_ary>")
      out!(" #{data.shift},#{data.shift}") until data.empty?
      out!("</v2_ary>")
    end
  end
  def convert_4d!
    data = get_ofs_bytes.unpack("f*").map(&:pretty_single)
    if data.empty?
      out!("<v3_ary/>")
    else
      out!("<v3_ary>")
      out!(" #{data.shift},#{data.shift},#{data.shift}") until data.empty?
      out!("</v3_ary>")
    end
  end
  def convert_4e!
    if @abcf
      data = get_ofs_bytes.unpack("V*").map{|i| @str_lookup[i]}
      if data.empty?
        out!("<str_ary/>")
      else
        out!("<str_ary>")
        data.each do |str|
          if str.empty?
            out!(" <s/>")
          else
            out!(" <s>#{str}</s>")
          end
        end
        out!("</str_ary>")
      end
    else
      convert_4x!("binE", &:to_hex_dump)
    end
  end
  def convert_4f!
    if @abcf
      data = get_ofs_bytes.unpack("V*").map{|i| @asc_lookup[i]}
      if data.empty?
        out!("<asc_ary/>")
      else
        out!("<asc_ary>")
        data.each do |str|
          if str.empty?
            out!(" <asc/>")
          else
            out!(" <asc>#{str}</asc>")
          end
        end
        out!("</asc_ary>")
      end
    else
      convert_4x!("binF", &:to_hex_dump)
    end
  end
  def convert_50!
    convert_4x!("bin10", &:to_hex_dump)
  end
  def convert_51!
    convert_4x!("bin11", &:to_hex_dump)
  end
  def convert_52!
    convert_4x!("bin12", &:to_hex_dump)
  end
  def convert_53!
    convert_4x!("bin13", &:to_hex_dump)
  end
  def convert_54!
    convert_4x!("bin14", &:to_hex_dump)
  end
  def convert_55!
    convert_4x!("bin15", &:to_hex_dump)
  end
  def convert_56!
    convert_4x!("u4_ary"){|data| data.unpack("C*").join(" ")}
  end
  def convert_57!
    convert_4x!("u4_ary"){|data| data.unpack("v*").join(" ")}
  end
  def convert_58!
    convert_4x!("u4_ary"){|data| unpack_u3be_ary(data).join(" ")}
  end
  def convert_59!
    convert_4x!("bin19", &:to_hex_dump)
  end
  def convert_5a!
    convert_4x!("i4_ary"){|data| data.unpack("c*").join(" ")}
  end
  def convert_5b!
    convert_4x!("i4_ary"){|data| data.unpack("s*").join(" ")}
  end
  def convert_5c!
    convert_4x!("i4_ary"){|data| unpack_i3be_ary(data).join(" ")}
  end
  def convert_5d!
    convert_4x!("bin1d", &:to_hex_dump)
  end
end

class EsfConverter < EsfParser
  include EsfConvertBasic
  include EsfSemanticConverter

  attr_reader :dir_builder

  def initialize(in_file, out_dir)
    @dir_builder = DirBuilder.new(out_dir)
    super(in_file)
    @esf_type_handlers = setup_esf_type_handlers
  end

  def setup_esf_type_handlers
    out = Hash.new{|ht,node_type| raise "Unknown type 0x%02x at %d" % [node_type, ofs] }
    (0..255).each{|i|
      name = ("convert_%02x!" % i).to_sym
      out[i] = name if respond_to?(name)
    }
    if @abca
      (0x80..0xbf).each{|i|
        out[i] = :convert_abca_rec!
      }
      (0xc0..0xff).each{|i|
        out[i] = :convert_abca_ary!
      }
    end
    out
  end

  def convert_rec_basic!(node_type, version)
    csr = ConvertSemanticRec[version][node_type]
    try_semantic(node_type){ return send(csr) } if csr
    tag!("rec", :type=>node_type, :version=>version) do
      if @abca
        ofs_end = get_ofs_end
      else
        ofs_end = get_u
      end
      send(@esf_type_handlers[get_byte]) while @ofs < ofs_end
    end
  end

  def convert_rec!(node_type, version)
    xmls = XmlSplit[node_type]
    if xmls
      rel_path = @dir_builder.open_nested_xml(xmls, lookahead_str) do
        convert_rec_basic!(node_type, version)
      end
      out!("<xml_include path=\"#{rel_path.xml_escape}\"/>")
    else
      convert_rec_basic!(node_type, version)
    end
  end

  def convert_until_ofs!(ofs_end)
    send(@esf_type_handlers[get_byte]) while @ofs < ofs_end
  end

  # Disabled in ABCA mode
  def convert_80!
    convert_rec!(*get_node_type_and_version)
  end

  def convert_abca_rec!
    # Special case root node, since it follows the old style for some reason
    if @ofs == 0x11 or @data[@ofs-1].ord & 0x20 != 0
      convert_rec!(*get_node_type_and_version)
    else
      convert_rec!(*get_node_type_and_version_abca)
    end
  end

  # Disabled in ABCA bode
  def convert_81!
    node_type, version = get_node_type_and_version
    csa = ConvertSemanticAry[version][node_type]
    try_semantic(node_type){ return send(csa) } if csa
    ofs_end, count = get_u, get_u
    if count == 0
      tag!("ary", :type=>node_type, :version=>version)
    else
      tag!("ary", :type=>node_type, :version=>version) do
        count.times do
          convert_rec!(node_type, nil)
        end
      end
    end
  end

  def convert_abca_ary!
    if @data[@ofs-1].ord & 0x20 != 0
      node_type, version = get_node_type_and_version
    else
      node_type, version = get_node_type_and_version_abca
    end
    csa = ConvertSemanticAry[version][node_type]
    try_semantic(node_type){ return send(csa) } if csa
    ofs_end, count = get_ofs_end_and_item_count
    if count == 0
      tag!("ary", :type=>node_type, :version=>version)
    else
      tag!("ary", :type=>node_type, :version=>version) do
        count.times do
          convert_rec!(node_type, nil)
        end
      end
    end
  end

  def put_node_types!
    tag!("node_types") do
      node_types.each do |n|
        out!("<node_type name=\"#{n.to_s.xml_escape}\"/>")
      end
      if @abcf
        @str_table.each do |str, idx|
          out!(%Q[<str_index idx="#{idx}">#{str.xml_escape}</str_index>])
        end
        @asc_table.each do |str, idx|
          out!(%Q[<asc_index idx="#{idx}">#{str.xml_escape}</asc_index>])
        end
      end
    end
  end

  def report_semantic_failures!
    failures = @semantic_stats.to_a.map{|key, (all,quiet,fails)|
      if fails == 0
        nil
      else
        [key.to_s, all, quiet, fails]
      end
    }.compact.sort
    return if failures.empty?
    STDERR.puts "Warning: Semantic conversion failures (low level conversion performed instead)"
    STDERR.puts "(this is OK if converting ESFs for game newer than Empire):"
    failures.each do |key, all, quiet, fails|
       puts "* #{key}: (#{all} records, #{fails} failures, #{quiet} quiet failures)"
    end
  end

  def convert!
    @done = false
    @dir_builder.open_main_xml do
      tag!("esf", :magic => magic.join(" "), :padding => padding) do
        put_node_types!
        send(@esf_type_handlers[get_byte])
      end
    end
    report_semantic_failures!
    @done = true
  end

  def progressbar_thread
    Thread.new do
      begin
        puts "Done: %0.1f%%" % percent_done
        5.times do
          sleep 1
          break if @done
        end
      end until @done
    end
  end

  # Forward to @dir_builder.xml_printer
  def tag!(*attrs, &blk)
    @dir_builder.xml_printer.tag!(*attrs, &blk)
  end
  def out!(str)
    @dir_builder.xml_printer.out!(str)
  end
  def out_ary!(tag, attrs, data)
    @dir_builder.xml_printer.out_ary!(tag, attrs, data)
  end
end
