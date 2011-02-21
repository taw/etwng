require "pgm"
require "default_versions"
require "xml_split"
require "esf_parser"
require "dir_builder"
require "esf_semantic_converter"

module EsfConvertBasic
  def convert_00!
    out!("<i2>#{get_i2}</i2>")
  end
  def convert_01!
    out!(get_bool ? "<yes/>" : "<no/>")
  end
  def convert_04!
    out!("<i>#{get_i}</i>")
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
  def convert_0a!
    out!("<flt>#{get_flt}</flt>")
  end
  def convert_0c!
    out!("<v2 x=\"#{get_flt}\" y=\"#{get_flt}\"/>")
  end
  def convert_0d!
    out!("<v3 x=\"#{get_flt}\" y=\"#{get_flt}\" z=\"#{get_flt}\"/>")
  end
  def convert_0e!
    str = get_s
    if str.empty?
      out!("<s/>")
    else
      out!("<s>#{str.xml_escape}</s>")
    end
  end
  def convert_0f!
    str = get_ascii
    if str.empty?
      out!("<asc/>")
    else
      out!("<asc>#{str.xml_escape}</asc>")
    end
  end
  def convert_10!
    out!("<u2x>#{get_u2}</u2x>")
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
    convert_4x!("bin0", &:to_hex_dump)
  end
  def convert_41!
    convert_4x!("bool_ary"){|data| data.unpack("C*").join(" ")}
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
    convert_4x!("binE", &:to_hex_dump)
  end
  def convert_4f!
    convert_4x!("binF", &:to_hex_dump)
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
    out
  end

  def convert_rec!(node_type, version)
    if version.nil? && ConvertSemanticRec[node_type]
      try_semantic(node_type) do
        return send(ConvertSemanticRec[node_type]) 
      end
    end
    if XmlSplit[node_type]
      rel_path = @dir_builder.open_nested_xml(XmlSplit[node_type], lookahead_str) do
        tag!("rec", :type=>node_type, :version=>version) do
          convert_until_ofs!(get_u)
        end
      end
      out!("<xml_include path=\"#{rel_path.xml_escape}\"/>")
    else
      tag!("rec", :type=>node_type, :version=>version) do
        convert_until_ofs!(get_u)
      end
    end
  end

  def convert_until_ofs!(ofs_end)
    send(@esf_type_handlers[get_byte]) while @ofs < ofs_end
  end

  def convert_80!
    node_type, version = get_node_type_and_version
    convert_rec!(node_type, version)
  end

  def convert_81!
    node_type, version = get_node_type_and_version
    if version.nil? && ConvertSemanticAry[node_type]
      try_semantic(node_type) do
        return send(ConvertSemanticAry[node_type]) 
      end
    end
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

  def put_node_types!
    tag!("node_types") do
      node_types.each do |n|
        out!("<node_type name=\"#{n.to_s.xml_escape}\"/>")
      end
    end
  end
  
  def convert!
    @done = false
    @dir_builder.open_main_xml do
      tag!("esf", :magic => magic.join(" ")) do
        put_node_types!
        send(@esf_type_handlers[get_byte])
      end
    end
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
