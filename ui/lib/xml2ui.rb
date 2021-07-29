require "nokogiri"

module XmlTagHandlers
  ## Basic low leveldata types
  def on_text_node_u(attributes, buf, ctx)
    @ui.put_u buf.to_i
  end

  def on_text_node_i(attributes, buf, ctx)
    @ui.put_i buf.to_i
  end

  def on_text_node_u2(attributes, buf, ctx)
    @ui.put_u2 buf.to_i
  end

  def on_text_node_i2(attributes, buf, ctx)
    @ui.put_i2 buf.to_i
  end

  def on_text_node_byte(attributes, buf, ctx)
    @ui.put_byte buf.to_i
  end

  def on_text_node_flt(attributes, buf, ctx)
    @ui.put_flt buf.to_f
  end

  def on_empty_node_yes(attributes, buf, ctx)
    @ui.put_yes
  end

  def on_empty_node_no(attributes, buf, ctx)
    @ui.put_no
  end

  def on_text_node_s(attributes, buf, ctx)
    @ui.put_str buf
  end

  def on_text_node_unicode(attributes, buf, ctx)
    @ui.put_unicode buf
  end

  def on_text_node_data(attributes, buf, ctx)
    buf.strip.split.each do |x|
      @ui.put_byte x.to_i(16)
    end
  end

  def on_text_node_uuid(attributes, buf, ctx)
    data = buf.strip.tr("-", "")
    raise "Bad uuid: #{data}" unless data.size == 32 and data =~ /\A[0-9a-f]{32}\z/i
    data.scan(/../).each do |x|
      @ui.put_byte x.to_i(16)
    end
  end

  ## Top level file type nodes
  def on_start_node_cml(attributes)
    @ui.put_version attributes[:version].to_i(10)
  end

  def on_end_node_cml(attributes, buf, ctx)
  end

  def on_start_node_fc(attributes)
    @ui.put_version attributes[:version].to_i(10)
  end

  def on_end_node_fc(attributes, buf, ctx)
  end

  def on_start_node_twui_images(attributes)
    @ui.put_version attributes[:version].to_i(10)
  end

  def on_end_node_twui_images(attributes, buf, ctx)
  end

  def on_start_node_ui(attributes)
    @version = attributes[:version].to_i(10)
    @ui.put_version attributes[:version].to_i(10)
  end

  def on_end_node_ui(attributes, buf, ctx)
  end

  ## Data structure nodes
  def on_text_node_key(attributes, buf, ctx)
    @ui.put_str buf
  end

  def on_text_node_value(attributes, buf, ctx)
    @ui.put_str buf
  end

  def on_start_node_events(attributes)
    if @version > 54
      @ui.put_u attributes[:count].to_i
    end
    [true, nil, {}]
  end

  def on_end_node_events(attributes, buf, ctx)
    if @version <= 54
      @ui.put_str "events_end"
    end
  end

  def on_start_node_uientry(attributes)
    # v100+ non-root
    if attributes[:type] == 'normal'
      @ui.put_u2 0
    end
    [true, nil, {}]
  end

  def on_end_node_uientry(attributes, buf, ctx)
  end

  ## Common node types
  def on_start_array_node(attributes)
    @ui.put_u attributes[:count].to_i
    [true, nil, {}]
  end

  def on_start_passthrough_node(attributes)
    [true, nil, {}]
  end

  def on_end_passthrough_node(attributes, buf, ctx)
  end

  def on_start_text_node(attributes)
    [false, "", {}]
  end

  def on_start_empty_node(attributes)
    [false, nil, {}]
  end

  def on_start_node_additional_data(attributes)
    type = attributes[:type]
    if type == 'none'
      @ui.put_no
      [false, nil, {}]
    else
      @ui.put_yes
      @ui.put_str type
      [true, nil, {}]
    end
  end

  def on_end_node_additional_data(attributes, buf, ctx)
  end

  ## Autoconfigure
  OnStart = Hash.new{|ht,k| raise "Unknown tag open #{k.inspect}"}
  OnEnd = Hash.new{|ht,k| raise "Unknown tag close #{k.inspect}"}

  %W[
    images
    states
    image_uses
    transitions
    effects
    children
    phases
    table
    row
    dynamics
    funcs
    anims
    anim_attrs
    mouse_states
    mouse_state_data
    subtemplates
    properties
    materialdata
    array
  ].each do |m|
    # TODO: it would be better if count was actually automatically determined and didn't require hand checking
    OnStart[m] = :on_start_array_node
    OnEnd[m]   = :on_end_passthrough_node
  end

  %W[
    fcentry
    image
    state
    image_use
    transition
    effect
    phase
    col
    color
    dynamic
    func
    anim
    anim_attr
    mouse_state
    mouse_state_datapoint
    model
    models
    template
    subtemplate
    event
    property
    material
    materialdatapoint
    sound
  ].each do |m|
    OnStart[m] = :on_start_passthrough_node
    OnEnd[m]   = :on_end_passthrough_node
  end

  self.instance_methods.each do |m|
    m = m.to_s
    case m
    when /\Aon_text_node_(.*)\z/
      OnStart[$1] = :on_start_text_node
      OnEnd[$1]   = m.to_sym
    when /\Aon_empty_node_(.*)\z/
      OnStart[$1] = :on_start_empty_node
      OnEnd[$1]   = m.to_sym
    when /\Aon_start_node_(.*)\z/
      OnStart[$1] = m.to_sym
    when /\Aon_end_node_(.*)\z/
      OnEnd[$1] = m.to_sym
    end
  end
end

class Xml2Ui < Nokogiri::XML::SAX::Document
  include XmlTagHandlers
  attr_reader :ui

  def initialize(input)
    super()
    @input = input
    @ui = UiBuilder.new
    @stack  = [[true, nil, {}, {}]]
    parse_file(input)
  end

  ## Nokogiri callbacks
  def start_element_namespace(name, attributes, *namespace_stuff)
    raise "Cannot nest tags in this context" unless @stack[-1][0]
    attrs = {}
    attributes.each do |a|
      attrs[a.localname.to_sym] = a.value
    end
    can_nest, buf, ctx = send(OnStart[name], attrs)
    @stack << [can_nest, attrs, buf, ctx]
  end

  def end_element_namespace(name, *namespace_stuff)
    can_nest, attrs, buf, ctx = *@stack.pop
    send(OnEnd[name], attrs, buf, ctx)
  end

  def error(str)
    raise "#{@path}: XML parse error: #{str}"
  end

  def characters(chars)
    if buf = @stack[-1][2]
      # Stupid XML parsers not supporting full UTF8 (as XML 1.1 promised)
      buf << chars.tr("\uE01F", "\x1F")
    elsif chars =~ /\S/
      raise "#{@path}: Illegal place for non-whitespace characters: #{@stack.inspect} #{chars.inspect}"
    end
  end

  def parse_file(path)
    @path = path # for error reporting
    parser = Nokogiri::XML::SAX::Parser.new(self, 'UTF-8')
    raise "No such file or directory: #{path}" unless File.exist?(path)
    parser.parse_file(path)
  end
end
