class Float
  def pretty_single
    rv = (((100_000.0 * self).round / 100_000.0) rescue self)
    return rv if [self].pack("f") == [rv].pack("f")
    self
  end
end

class String
  # Escape characters for output as XML attribute values (< > & ' ")
  def xml_escape
    replacements = {
      "<" => "&lt;",
      ">" => "&gt;",
      "&" => "&amp;",
      "\"" => "&quot;",
      "'" => "&apos;",
      "\r" => "&#xD;",
      # XML parsers are shit, so we can't even do this
      # "\x1f" => "&#x1F;",
      "\x1f" => "&#xE01F;",
    }
    b.gsub(/([<>&\'\"\r\x1f])/) { replacements[$1] }
  end
end

class UiFile
  def initialize(path, output_path)
    @path = path
    @output_path = output_path
    @data = path.open("rb", &:read)
    @size = @data.size
  end

  def call
    with_xml_output! do
      err1 = try_convert!(debug: false)
      return unless err1
    end

    # Didn't work, so try it again in debug mode. We fully expect same error
    # so we're ignoring the first one

    with_xml_output! do
      err2 = try_convert!(debug: true)
      if err2
        out_error!(err2)
        raise err2
      end
    end
  end

private

  def get(sz)
    raise "Requested reading past end of file (#{@path}:#{@ofs}) - #{sz}" if @ofs + sz > @data.size
    rv = @data[@ofs, sz]
    @ofs += sz
    rv
  end

  def lookahead(sz)
    raise "Requested reading past end of file (#{@path}:#{@ofs}) - #{sz}" if @ofs + sz > @data.size
    @data[@ofs, sz]
  end

  def lookahead_i
    lookahead(4).unpack1("i")
  end

  def lookahead_u
    lookahead(4).unpack1("V")
  end

  def lookbehind(sz)
    raise if @ofs-sz < 0
    @data[@ofs-sz, sz]
  end

  def get_byte
    get(1).unpack1("C")
  end

  def get_bool
    v = get_byte
    raise "Invalid boolean value: #{v}" if v > 1
    v == 1
  end

  def get_u2
    get(2).unpack1("v")
  end

  def get_u
    get(4).unpack1("V")
  end

  def get_i
    get(4).unpack1("i")
  end

  def get_flt
    get(4).unpack1("f").pretty_single
  end

  def get_s
    get(get_u2)
  end

  def get_unicode
    get(get_u2*2).unpack("v*").pack("U*")
  end

  def get_version
    raise "Trying to get Version block at wrong offset" unless @ofs == 0
    raise "Not UI file" unless get(7) == "Version"
    v = get(3)
    raise "Not UI file" unless v =~ /[0-9]{3}/
    v.to_i
  end

  def version_string
    "%03d" % @version
  end

  def eof?
    @size == @ofs
  end

  def bytes_left
    @size - @ofs
  end

  # Most UI formats except the latest ones do
  def starts_with_root_ui_entry?
    @data[16,4] == "root" or @data[32,4] == "root"
  end

  def convert_u!(comment=nil)
    out_with_comment! "<u>#{get_u}</u>", comment
  end

  def convert_id!
    v4 = lookahead(4).bytes.map{|x| "%02x" % x}.join(" ")
    v = get_u
    out! "<u>#{v}</u><!-- ID (#{v4}) -->"
    if @version >= 126
      convert_uuid!
    end
  end

  # it doesn't have version number, but it's tagged as uuid
  def convert_uuid!(comment=nil)
    v = get(16).bytes.map{|x| "%02x" % x}
    vv = [
      v[0,4].join,
      v[4,2].join,
      v[6,2].join,
      v[8,2].join,
      v[10,6].join,
    ].join("-")
    out_with_comment! "<uuid>#{vv}</uuid>", comment
  end

  def convert_i!(comment=nil)
    out_with_comment! "<i>#{get_i}</i>", comment
  end

  def convert_i_zero!(comment=nil)
    # Well, at least it looks like it
    v = get_i
    unless v == 0
      flt = lookbehind(4).unpack1("f")
      hex = lookbehind(4).bytes.map{|x| "%02x" % x }.join(":")
      if comment
        raise "Must be zero, got #{v} / #{flt} / #{hex} (#{comment})"
      else
        raise "Must be zero, got #{v} / #{flt} / #{hex}"
      end
    end
    out_with_comment! "<i>#{v}</i><!-- always zero -->", comment
  end

  def convert_ix!(comment=nil)
    v = get_i
    hex = lookbehind(4).bytes.map{|x| "%02x" % x }.join(":")
    out_with_comment! "<i>#{v}</i><!-- #{hex} -->", comment
  end

  def convert_byte!(comment=nil)
    out_with_comment! "<byte>#{get_byte}</byte>", comment
  end

  def convert_s!(comment=nil)
    out_with_comment! "<s>#{get_s.xml_escape}</s>", comment
  end

  def convert_unicode!(comment=nil)
    out_with_comment! "<unicode>#{get_unicode.xml_escape}</unicode>", comment
  end

  def convert_bool!(comment=nil)
    v = get_byte
    if v <= 1
      out_with_comment!(v == 1 ? "<yes />" : "<no />", comment)
    else
      if comment
        raise "Invalid boolean value: got #{v} (#{comment})"
      else
        raise "Invalid boolean value: got #{v}"
      end
    end
  end

  def convert_bool_false!(comment=nil)
    v = get_byte
    if v == 0
      out_with_comment! "<no />", comment
    else
      if comment
        raise "Invalid boolean value: false is expected, got #{v} (#{comment})"
      else
        raise "Invalid boolean value: false is expected, got #{v}"
      end
    end
  end

  # These are either strings or booleans pretty much always (except in twui.images)
  def convert_u2!(comment=nil)
    v = get_u2
    out_with_comment! "<u2>#{v}</u2>", comment
  end

  def convert_flt!(comment=nil)
    if @debug
      i = lookahead_u
      hex = lookahead(4).bytes.map{|x| "%02x" % x }.join(":")
      out_with_comment! "<flt>#{get_flt}</flt><!-- (#{i} - #{hex}) -->", comment
    else
      out_with_comment! "<flt>#{get_flt}</flt>", comment
    end
  end

  def convert_angle!(comment=nil)
    i = lookahead_u
    v = get_flt
    vdeg = (v * 180.0 / Math::PI).round(2)
    if @debug
      out_with_comment! "<flt>#{v}</flt><!-- #{i} / #{vdeg} degrees -->", comment
    else
      out_with_comment! "<flt>#{v}</flt><!-- #{vdeg} degrees -->", comment
    end
  end

  def convert_bgra!(comment=nil)
    if comment
      out! "<!-- #{comment} -->"
    end
    tag! "color" do
      convert_byte! "B"
      convert_byte! "G"
      convert_byte! "R"
      convert_byte! "A"
    end
  end

  def convert_array!(type)
    count = get_u
    raise "#{type} array element count of #{count} impossibly high" if count > 0xffff
    tag! type, count: count do
      count.times do
        yield
      end
    end
  end

  def convert_image_list!
    convert_array! "images" do
      tag! "image" do
        convert_id!
        convert_s! "path"
        convert_i! "x size"
        convert_i! "y size"
        if @version < 74
          convert_bgra!
        end
        if @version >= 78
          convert_bool!
        end
      end
    end
  end

  def convert_debug!(size)
    v = get(size).chars
    out! %Q[<debug size="#{size}">]
    v.each_slice(16) do |slice|
      slice = slice.join
      asc = slice.chars.map{|c| c =~ /[\x20-\x7e]/ ? c : "."}.join
      asc += " " * (16 - asc.size)
      hex = slice.bytes.map{|c| "%02x" % c}.join(" ")
      out! "  #{asc} #{hex}\n"
    end
    out! "</debug>"
  end

  def convert_data!(size, comment=nil)
    v = get(size).bytes
    if comment
      out! "<!-- #{comment} -->"
    end
    out! %Q[<data size="#{size}">]
    v.each_slice(16) do |slice|
      hex = slice.map{|c| "%02x" % c}.join(" ")
      out! "  #{hex}\n"
    end
    out! "</data>"
  end

  def convert_data_zero!(size, comment=nil)
    v = get(size).bytes
    out! %Q[<data size="#{size}">]
    v.each_slice(16) do |slice|
      hex = slice.map{|c| "%02x" % c}.join(" ")
      out! "  #{hex}\n"
      unless slice.all?(&:zero?)
        if comment
          raise "Data should be all zeroes, got: #{v} (#{comment})"
        else
          raise "Data should be all zeroes, got: #{v}"
        end
      end
    end
    out! "</data>"
  end

  def convert_state_list!
    out_ofs!
    convert_array! "states" do
      tag! "state" do
        convert_id!
        convert_s! "title - NewState"
        convert_i! "x size"
        convert_i! "y size"

        convert_unicode! "state text"
        convert_unicode! "tooltip"
        convert_i! "text xsize?"
        convert_i! "text ysize?"
        convert_i! "text xalign?"
        convert_i! "text yalign?"

        convert_bool! "text behavior?"
        convert_unicode! "text label?"

        if @version >= 116
          convert_unicode! "localization id"
          convert_bool_false! "state stuff 1?"
          convert_bool_false! "state stuff 2?"

          if @version == 121 or @version == 122 or @version >= 129
            convert_s!
          end
        else
          convert_bool_false! "state stuff 3?"
          convert_bool! "state stuff 4?"
          convert_unicode! "localization id"
          convert_unicode! "tooltip id"

          if @version >= 90
            convert_s! "state stuff before font?"
          end
        end

        if @version >= 27
          convert_s! "font"
        end
        convert_i! "font size? line height?"
        convert_i! "font leading?"
        convert_i! "font tracking?"

        if @version >= 74
          convert_bgra!
        end

        if @version >= 43
          convert_s! "font category / twui"
        end

        if @version >= 86
          convert_i! "left ?"
          convert_i! "right ?"
          convert_i! "top ?"
          convert_i! "bottom ?"
        else
          convert_ix! "x ?"
          convert_ix! "y ?"
        end

        convert_i!
        if @version >= 90
          # no more flags
        elsif @version >= 83
          convert_bool!
          convert_bool!
          convert_bool!
          convert_bool!
        elsif @version >= 29
          convert_bool!
          convert_bool!
          convert_bool!
        elsif @version >= 27
          convert_bool!
          convert_bool!
        elsif @version >= 25
          convert_bool!
          convert_bool!
          convert_bool!
          convert_bool!
          convert_bool!
          convert_bool!
        end

        convert_s! "shader name"
        convert_flt! "shader vars"
        convert_flt! "shader vars"
        convert_flt! "shader vars"
        convert_flt! "shader vars"

        if @version >= 77
          convert_s! "text shader name"
          convert_flt! "text shader vars"
          convert_flt! "text shader vars"
          convert_flt! "text shader vars"
          convert_flt! "text shader vars"
        end

        out_ofs! "shaders done"

        if @version < 74
          convert_s! "state description"
          convert_s! "event text"
        end

        out_ofs! "image use list"
        convert_image_uses!

        # something mouse related???
        convert_i!
        convert_i!

        if @version < 74
          convert_transitions!
        else
          convert_mouse_states!
        end

        if @version >= 124
          convert_material!
        end
      end
    end
  end

  def convert_material!
    tag! "material" do
      path = get_s
      out_with_comment! "<s>#{path.xml_escape}</s>", "path"
      if path.empty?
        out! "<!-- rest skipped if path empty -->"
      else
        convert_array! "materialdata" do
          tag! "materialdatapoint" do
            convert_s!
            convert_flt!
            convert_flt!
            convert_flt!
            convert_flt!
          end
        end
        convert_properties!
        out_ofs! "material data ends"
      end
    end
  end

  def convert_mouse_state_data!
    convert_array! "mouse_state_data" do
      tag! "mouse_state_datapoint" do
        convert_id!
        convert_s!
        convert_s!
        convert_s!
      end
    end
  end

  def convert_mouse_states!
    convert_array! "mouse_states" do
      tag! "mouse_state" do
        convert_i! "type"
        convert_id!
        convert_i!
        convert_i!
        out_ofs! "mouse nested stuff starts"
        convert_mouse_state_data!
      end
    end
  end

  def convert_transitions!
    convert_array! "transitions" do
      tag! "transition" do
        convert_i! "type"
        convert_id!
        if @version >= 39
          convert_s!
          convert_i!
          convert_i!
        end
        if @version >= 43
          convert_s!
          convert_i!
        end
      end
    end
  end

  def convert_image_uses!
    convert_array! "image_uses" do
      tag! "image_use" do
        convert_id!
        convert_u! "x offset"
        convert_u! "y offset"
        convert_u! "x size"
        convert_u! "y size"
        convert_bgra! "color"
        if @version >= 119
          convert_s! "color?"
        end

        # Up to this point, this works for 74+ too
        out_ofs! "less decoded part of image_use follows"
        convert_bool! "tiled?"
        convert_bool! "flipped x?"
        convert_bool! "flipped y?"
        convert_i! "dock position (0-9)?"
        if @version >= 77 # or sth
          convert_i! "dock offset x?"
          convert_i! "dock offset y?"
        end
        convert_bool! "stretch x?"
        convert_bool! "stretch y?"
        convert_angle! "rotation angle"
        convert_flt! "rotation pivot x?"
        convert_flt! "rotation pivot y?"
        if @version >= 74
          if @version >= 103
            convert_flt! "rotation axis x?"
            convert_flt! "rotation axis y?"
            convert_flt! "rotation axis z?"
            convert_s! "shader name"
          else
            convert_s! "shader name"
            convert_flt! "rotation axis x?"
            convert_flt! "rotation axis y?"
            convert_flt! "rotation axis z?"
            convert_i_zero!
          end

          # There is extra stuff here :-(
          out_ofs! "extra stuff?"
          if @version <= 77
            convert_bool! "extra image use stuff?"
          end
          if @version >= 103
            convert_flt! "shader var?"
            convert_flt! "shader var?"
            convert_flt! "shader var?"
            convert_flt! "shader var?"
          end
          if @version >= 92
            convert_flt! "margin top?"
            convert_flt! "margin right?"
            convert_flt! "margin bottom?"
            convert_flt! "margin left?"
          else
            convert_flt! "margin top-bottom?"
            convert_flt! "margin left-right?"
          end
          if @version >= 125
            convert_bool!
          end
        else
          if @version >= 51
            convert_bool!
          end
          if @version == 31
            convert_i!
          end
          if @version == 30
            convert_bool!
          end
        end
      end
    end
  end

  def convert_anim_attrs!
    convert_array! "anim_attrs" do
      tag! "anim_attr" do
        out_ofs! "anim attr start"
        convert_id!
        convert_s! "animation?"
        convert_s! "state?"
        convert_s! "property?"
        out_ofs! "anim attr done"
      end
    end
  end

  def convert_sound!
    tag! "sound" do
      # This is a big wat
      out! "<!-- lookahead #{lookahead(4).bytes} -->"
      v = lookahead_i
      if v == -1
        convert_i! "no sound"
      elsif @version >= 124
        convert_u2!
        convert_s!
        out_ofs! "end of sound stuff?"
      elsif v == 0
        convert_i! "no sound"
      else
        convert_s!
        convert_s!
        out_ofs! "end of sound stuff?"
      end
    end
  end

  def convert_anims!
    convert_array! "anims" do
      tag! "anim" do
        out_ofs! "start of anim"

        if @version >= 113
          convert_sound!
        end

        convert_flt! "x offset?"
        convert_flt! "y offset?"
        convert_i! "x size?"
        convert_i! "y size?"
        convert_bgra!
        convert_flt! "shader vars?"
        convert_flt! "shader vars?"
        convert_flt! "shader vars?"
        convert_flt! "shader vars?"
        convert_flt! "rotation angle?"
        convert_i! "image index 1?"
        convert_i! "image index 2?"
        if @version >= 113
          convert_flt! "font scale?"
        end
        convert_i! "interpolation time?"
        convert_i! "interpolation property mask?"
        convert_flt! "easing weight?"
        convert_s! "easing curve?"
        convert_anim_attrs!

        out_ofs! "end of anim stuff"
        if @version >= 90
          convert_bool! "is movement absolute?"
        end

        if @version >= 104
          convert_bool! "end of anim 1?"
        end

        if @version <= 112
          if @version >= 100
            convert_s! "end of anim 2?"
          end
          if @version >= 106
            convert_s! "end of anim 3"
          end
        end
        if @version >= 124
          convert_s!
        end
        out_ofs! "end of anim"
      end
    end
  end

  def convert_funcs!
    convert_array! "funcs" do
      tag! "func" do
        convert_s! "name"
        convert_bool! "propagate?"
        convert_bool! "make noninteractive?"
        convert_anims!
        out_ofs! "end of func"
        if @version >= 91 and @version < 100
          convert_s!
        end
        if @version >= 113
          convert_s!
          convert_s!
        end
      end
    end
  end

  def convert_properties!
    convert_array! "properties" do
      tag! "property" do
        convert_s! "key"
        convert_s! "value"
      end
    end
  end

  # This is a total mess, maybe it will work eventually
  def convert_model!
    tag! "models" do
      out! "<!-- this is very poorly decoded part -->"
      out_ofs! "model"
      convert_s!
      if @version == 74
        header_size = 37
      elsif @version == 84 or @version == 85 or @version == 86
        header_size = 50
      else
        header_size = 74
      end
      exp_header_size = @data[@ofs,1000].index("Variant")
      if exp_header_size
        out! "<!-- model expected header size #{header_size}/#{exp_header_size-6} -->"
      else
        out! "<!-- model expected header size #{header_size}/unknown -->"
      end
      convert_data! header_size, "model header data"

      model_count = get_i
      out! "<i>#{model_count}</i><!-- model count -->"
      model_count.times do
        tag! "model" do
          convert_s! "mesh path?"
          convert_s! "mesh name?"
          if @version <= 77
            convert_data! 21, "some model data or anim header or sth"
          elsif @version == 84 or @version == 85 or @version == 86
            convert_data! 29, "some model data or anim header or sth"
          else
            convert_data! 1, "some model data or anim header or sth"
          end
          convert_ix! "anim count or something?" # assume 1, crashes otherwise
          convert_s! "anim name?"
          convert_s! "anim path?"
          convert_data! 4, "rest of anim stuff or sth"
          out_ofs! "end of model data"
        end
      end
    end
  end

  def convert_uientry_gen2!(*args)
    tag!("uientry", *args) do
      convert_id!
      convert_s! "title"
      if @version >= 43
        convert_s! "title2"
      end

      if @version >= 100 and @version < 113
        convert_s! "v100+ extra string?"
      elsif @version == 113
        tag! "event" do
          convert_s!
          convert_s!
          convert_s!
        end
      elsif @version >= 115
        convert_array! "events" do
          tag! "event" do
            convert_s!
            convert_s!
            convert_s!

            if @version >= 121
              convert_properties!
            end
          end
        end
      end

      convert_i! "x offset"
      convert_i! "y offset"

      (1..12).each do |i|
        case i
        when 3
          convert_byte! "uientry flag #{i}"
        else
          convert_bool! "uientry flag #{i}"
        end
      end
      convert_bool! if @version < 90

      convert_unicode! "tooltip text"
      convert_unicode! "tooltip id"

      convert_ix! "docking?"
      if @version >= 77
        convert_ix! "docking x?"
        convert_ix! "docking y?"
      end

      convert_bool!
      convert_i! "default state id"

      convert_image_list!

      convert_ix! "mask image?"

      if @version < 110
        convert_i!
      end

      if @version >= 126
        convert_uuid!
      end

      convert_state_list!

      if @version >= 126
        convert_uuid!
      end

      convert_properties!
      convert_i! "priority?"
      out_ofs! "before number of funcs?"
      convert_funcs!

      out_ofs! "children start here?"

      convert_children!

      out_ofs! "children end here?"

      convert_additional_data!

      out_ofs! "additional data ends here?"

      convert_s! "end of uientry 1?"
      convert_s! "end of uientry 2?"

      out_ofs! "end_of_uientry data 3"

      if get_bool
        out! "<yes /><!-- has some extra data (just below) -->"
        convert_array! "array" do
          convert_flt!
        end
      else
        out! "<no /><!-- has some extra data (section skipped) -->"
      end

      if @version == 97
        has_extra_data = get_bool
        if has_extra_data
          out! "<yes /><!-- has some extra v97 data (just below) -->"
          convert_i! "extra int 1?"
          convert_array! "array" do
            convert_ix!
          end
        else
          out! "<no /><!-- has some extra v97 data (section skipped) -->"
        end

        convert_ix! "uientry id reference maybe?"
      end

      has_model = get_bool
      if has_model
        out! "<yes /><!-- has model (controls presence of model below) -->"
        convert_model!
      else
        out! "<no /><!-- has model (controls presence of model below) -->"
      end

      # This version mix...
      if @version <= 84 and @version != 77 and @version != 78
        convert_bool! "end of uientry flag 5A?"
      else
        convert_bool! "end of uientry flag 5B?"
        convert_bool! "end of uientry flag 6B?"
      end

      if @version >= 94
        convert_bool!
      end

      if @version >= 113
        convert_flt!
        convert_flt!
        convert_flt!
      end

      out_ofs! "end of uientry"
    end
  end

  def convert_uientry!
    tag! "uientry" do
      convert_id!
      convert_s! "title"
      if @version >= 43
        convert_s! "title2"
      end
      convert_i! "x offset"
      convert_i! "y offset"
      7.times do
        convert_bool!
      end
      if @version >= 47
        convert_bool!
      end
      if @version >= 50
        convert_bool!
        convert_bool!
        convert_bool!
      end
      if @version >= 52
        convert_bool!
      end
      convert_s! "parent name"
      convert_i!
      convert_unicode! "tooltip text"
      convert_unicode! "tooltip id"
      convert_i!

      if @version >= 33
        convert_bool!
      end
      if @version >= 39
        convert_ix! "default state id"
      end
      convert_s! "script"
      convert_image_list!
      if @version >= 28
        convert_i!
      end
      if @version >= 32
        convert_i!
      end
      convert_state_list!

      out_ofs! "state list just finished"
      convert_i!

      out_ofs! "do event list now"
      convert_event_list!
      convert_i!

      if @version >= 39
        convert_effects!
      end

      convert_children!

      convert_s! "template"

      if @version >= 44
        convert_additional_data!
      end

      if @version >= 49
        convert_s!
      end
    end
  end

  def convert_additional_data!
    out_ofs! "additional data section"
    flag = get_bool
    if flag
      type = get_s
      tag! "additional_data", type: type do
        if type == "List" or type == "HorizontalList"
          count = get_u
          out!("<i>#{count}</i><!-- count data points -->") # generallly 0-5
          count.times do
            convert_flt! "data point"
          end
          convert_i! "mystery1"     # generally -2 to 5, but one 130
          convert_i! "mystery2"     # generally 0-2
          convert_bool! "mystery3"
          convert_i! "mystery4"     # generally 1-10
          if @version >= 54 and @version != 77
            convert_bool! "mystery5"
          end
          if @version >= 96
            convert_bool! "mystery6"
            convert_i! "mystery7"
          end
          if @version == 101
            convert_ix! "mystery8"
            convert_bool_false! "mystery9"
          elsif @version >= 102 and @version <= 104
            convert_i! "mystery8"
            convert_data_zero! 5
          elsif @version == 105
            convert_i! "mystery8"
            convert_data_zero! 10
          elsif @version >= 106
            convert_i!
            convert_i!
            convert_i!
            convert_i!
            convert_bool!
            convert_bool!
            convert_i!
            if @version >= 113
              convert_i_zero!
            end
            if @version >= 119
              convert_i_zero!
              convert_bool!
            end
            if @version >= 122
              convert_i!
              convert_i!
            end
            if @version >= 129
              convert_data_zero! 2, "v129 additional data?"
            end
          end
        elsif type == "Table"
          convert_array! "table" do
            convert_array! "row" do
              tag! "col" do
                5.times do
                  convert_flt! "data point"
                end
              end
            end
          end
        elsif type == "RadialList"
          convert_angle!
          convert_angle!
          convert_angle!
          convert_flt!

          convert_bool!
          if @version == 121
            convert_bool!
          end
          out_ofs! "rest of RadialList?"
        else
          raise "Unknown additional data section #{type}"
        end
      end
    else
      tag! "additional_data", type: "none"
    end
  end

  def convert_children!
    convert_array! "children" do
      if @version <= 54
        convert_uientry!
      elsif @version <= 99
        convert_uientry_gen2!
      else
        # Not sure wtf
        if lookahead(2) == "\x00\x00".b
          @ofs += 2
          convert_uientry_gen2! type: "normal"
        else
          convert_template!
        end
      end
    end
  end

  def convert_subtemplate!
    tag! "subtemplate" do
      convert_s! "source uientry?"
      convert_s! "dest uientry?"

      if @version >= 129
        convert_uuid!
        convert_array! "states" do
          tag! "state" do
            convert_s! "name"
            convert_uuid!
          end
          out_ofs! "state in template?"
        end
      end

      convert_s!

      if @version >= 119
        convert_array! "events" do
          tag! "event" do
            convert_s!
            convert_s!
            convert_s!
            if @version >= 121
              convert_array! "properties" do
                tag! "property" do
                  convert_s!
                  convert_s!
                end
              end
            end
          end
        end
      else
        convert_s! "type?"
      end

      convert_s! "func name?"
      out_ofs! "after all s?"

      convert_flt!
      convert_flt!
      convert_flt!
      convert_flt!
      convert_i!
      convert_i!
      convert_bool! "subtemplate flag 1?"
      if @version >= 128
        convert_bool! "subtemplate flag 2?"
      end
      convert_i!
      convert_i!
      convert_data_zero! 2
      convert_unicode! "tooltip id?"
      convert_unicode! "tooltip text?"

      if @version >= 128
        convert_bool!
      end

      out_ofs! "subtemplate states"

      # WTF? seriously? or are we missing some state count somewhere?
      while true
        out! "<!-- lookahead: #{ @data[@ofs, 4].bytes } -->"
        v = @data[@ofs+2, 2].bytes
        # length 1 string sometimes happens here
        break if v[0] == 0
        break if v[1] == 0 and lookahead(2) != "\x01\x00".b
        tag! "state" do
          convert_s! "name"
          convert_unicode!
          convert_unicode!
          convert_unicode!
          convert_unicode!
          if @version >= 128
            convert_bool!
          end
        end
      end

      out_ofs! "subtemplate properties"

      convert_properties!

      convert_array! "images" do
        tag! "image" do
          convert_s!
        end
      end

      if @version >= 128
        out_ofs! "v128+ stuff?"
        convert_i_zero! "v128+ stuff 1?"
        convert_array! "states" do
          tag! "state" do
            convert_s!
            convert_s!
            convert_flt!
            convert_flt!
            convert_flt!
            convert_flt!
          end
        end
        convert_array! "images" do
          tag! "image" do
            convert_s! "path"
            convert_uuid!
          end
        end
      end

      out_ofs! "end of subtemplate?"
    end
  end

  # Is it even a template?
  def convert_template!
    tag! "template" do
      convert_s! "name?"
      if @version >= 119
        convert_id!
      end

      convert_array! "subtemplates" do
        convert_subtemplate!
      end

      convert_array! "children" do
        convert_uientry_gen2!
      end

      out_ofs! "end of template?"
    end
  end

  def convert_effects!
    convert_array! "effects" do
      tag! "effect" do
        convert_s! "name"
        convert_bool!
        convert_bool!
        convert_array! "phases" do
          out_ofs! "phase data"
          tag! "phase" do
            11.times do
              convert_ix!
            end
            if @version >= 50
              out! "<!-- extra 3 -->"
              convert_ix!
              convert_ix!
              convert_ix!
            end
            v = get_i
            out! "<i>#{v}</i><!-- include optional extra phase details? -->"
            v.times do
              out_ofs! "optional phase details"
              convert_ix!
              convert_s!
              convert_s!
            end
          end
        end
      end
    end
    out_ofs! "effects end"
  end

  def convert_event_list!
    tag! "events" do
      while true
        # v29, looks like some stray \r\n - \n conversion artifact?
        # Honestly I don't know how it would even parse in game, probably would just crash
        # especially since there's another such artifact in different context in the same file
        #
        # 029/empire-ui-ui-campaign_ui-sabotage.txt - broken file
        # 032/empire-ui-ui-campaign_ui-layout_sabotage.xml - game probably just uses this one
        s = get_s
        break if s == "events_end"
        tag! "event" do
          out! "<s>#{s.xml_escape}</s>"
        end
      end
    end
  end

  def convert_ui!
    tag! "ui", version: version_string do
      if @version <= 54
        convert_uientry!
      else
        convert_uientry_gen2!
      end
      if bytes_left > 0
        out! "<todo>#{bytes_left} bytes</todo>"
        raise "TODO - incomplete decoding"
      end
    end
  end

  def convert_cml_002!
    tag! "cml", version: version_string do
      until eof?
        out! "<key>#{get_s.xml_escape}</key>"
        out! "<value>#{get_s.xml_escape}</value>"
      end
    end
  end

  def convert_fc!
    tag! "fc", version: version_string do
      until eof?
        tag! "fcentry" do
          convert_s!
          convert_u!
          convert_s!
          convert_u!
          convert_u!
          if @version >= 50
            convert_u!
            convert_u!
          end
          if @version >= 51
            convert_u!
          end
          convert_byte! "B"
          convert_byte! "G"
          convert_byte! "R"
          convert_byte! "A"
          if @version >= 53
            convert_s!
          end
          if @version >= 52
            convert_s! "T0"
            convert_u!
            convert_u!
            convert_u!
            convert_u!
          end
        end
      end
    end
  end

  def convert_twui_images!
    tag! "twui_images", version: version_string do
      convert_array! "images" do
        tag! "image" do
          convert_s!
          convert_data_zero! 19
          convert_i!
          convert_data_zero! 6
          x = get_u2
          out! "<i2>#{x}</i2><!-- x -->"
          y = get_u2
          out! "<i2>#{y}</i2><!-- y -->"
          convert_u2!
          out! "<!-- #{x}*#{y} datapoints -->"
          (x*y).times do
            convert_bgra!
          end
        end
      end
    end
  end

  def autodetect_and_convert!
    @version = get_version
    case @version
    when 2
      convert_cml_002!
    when 44, 50, 51, 52, 53
      if starts_with_root_ui_entry?
        convert_ui!
      else
        convert_fc!
      end
    when 119, 129
      if starts_with_root_ui_entry?
        convert_ui!
      else
        convert_twui_images!
      end
    when 25..999
      convert_ui!
    else
      raise "Not supported yet"
    end
  end

  def try_convert!(debug:)
    @ofs = 0
    @debug = debug
    autodetect_and_convert!
    nil
  rescue Exception => err
    err
  end

  def with_xml_output!
    XMLBuilder.new(@output_path) do |output|
      @output = output
      yield
    end
  end

  def out_error!(err)
    tag! "error", version: @version, msg: err do
      out! "Data before fail:"
      ofs = @save_ofs || @ofs
      hex_dump!(ofs-64, ofs)
      out! "Data from fail #{ofs}:"
      hex_dump!(ofs, ofs+1024)
    end
  end

  def out!(*args)
    @output.out!(*args)
  end

  def out_with_comment!(xml, comment)
    if comment
      out! "#{xml}<!-- #{comment} -->"
    else
      out! xml
    end
  end

  def tag!(*args, &blk)
    @output.tag!(*args, &blk)
  end

  def out_ofs!(comment=nil)
    return unless @debug
    @save_ofs = @ofs
    if comment
      out! "<!-- #{@ofs} - #{comment} -->"
    else
      out! "<!-- #{@ofs} -->"
    end
  end

  def hex_dump!(s, e)
    s = 0 if s < 0
    @data[s...e].chars.each_slice(16).each do |slice|
      slice = slice.join
      asc = slice.chars.map{|c| c =~ /[\x20-\x7e]/ ? c : "."}.join
      asc += " " * (16 - asc.size)
      hex = slice.bytes.map{|c| "%02x" % c}.join(" ")
      out! "#{asc} #{hex}\n"
    end
  end
end
