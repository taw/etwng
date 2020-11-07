require "sea_grids"
require "poi"
require "commander_details"
require "etw_region_names"

module EsfSemanticConverter
  ConvertSemanticAry = Hash.new{|ht,k| ht[k]={}}
  ConvertSemanticRec = Hash.new{|ht,k| ht[k]={}}

## Utility functions
  def convert_ary_contents_str(tag)
    data = get_ary_contents(:s).flatten
    raise SemanticFail.new if data.any?{|name| name =~ /\s/}
    out_ary!(tag, "", data.map{|name| " #{name.xml_escape}" })
  end

  def ensure_types(actual, *expected_types)
    (actual_type, actual_data) = *actual
    raise SemanticFail.new unless actual_type == expected_types
    actual_data
  end

  def ensure_loc(loc)
    loc_type, loc_data = loc
    if loc_type == [:s, :s] and loc_data == ["", ""]
      ""
    elsif loc_type == [:s] and loc_data != [""]
      loc_data[0]
    else
      raise SemanticFail.new
    end
  end

  def ensure_date(date)
    year, season = ensure_types(date, :u, :asc)
    raise SemanticFail.new if season =~ /\s/
    if year == 0 and season == "summer"
      nil
    else
      "#{season} #{year}"
    end
  end

  def ensure_unit_history(unit_history)
    date, a, b = ensure_types(unit_history, [:rec, :DATE, nil], :u, :u)
    date = ensure_date(date)
    raise SemanticFail.new unless a == 0 and b == 0 and date
    date
  end

## Annotation system

def annotate_value!(annotation)
  low_level_tag = @data[@ofs].ord # Temporary workaround, move logic to get_value!
  t, v = get_value!
  annotation = annotation ? "<!-- #{annotation} -->" : ""
  case t
  when :bool
    tag = v ? "<yes/>" : "<no/>"
    out!("#{tag}#{annotation}")
  when :i1, :i2, :i, :i8, :byte, :u2, :u, :u8, :flt
    # flt nan handling here?
    out!("<#{t}>#{v}</#{t}>#{annotation}")
  when :s, :asc
    if v.empty?
      out!("<#{t}/>#{annotation}")
    else
      out!("<#{t}>#{v.xml_escape}</#{t}>#{annotation}")
    end
  when :v2_ary
    data = v.unpack("f*").map(&:pretty_single)
    if data.empty?
      out!("<v2_ary/>#{annotation}")
    else
      out!("<v2_ary>#{annotation}")
      out!(" #{data.shift},#{data.shift}") until data.empty?
      out!("</v2_ary>")
    end
  when :flt_ary
    data = v.unpack("f*").map(&:pretty_single)
    if data.empty?
      out!("<flt_ary/>#{annotation}")
    else
      out!("<flt_ary>#{data.join(" ")}</flt_ary>#{annotation}")
    end
  # Annotations are meant to work with all u_ary formats, but it's not tested properly yet
  when :u_ary
    if v.empty?
      out!("<u4_ary/>#{annotation}")
    else
      out!("<u4_ary>#{v.join(" ")}</u4_ary>#{annotation}")
    end
  when :v2
    out!("<v2 x=\"#{v[0]}\" y=\"#{v[1]}\"/>#{annotation}")
  when :v3
    out!("<v3 x=\"#{v[0]}\" y=\"#{v[1]}\" z=\"#{v[2]}\"/>#{annotation}")

  else
    raise "Trying to annotate value of unknown type: #{t}"
  end
end

def annotate_rec(type, annotations)
  each_rec_member(type) do |ofs_end, i|
    field_type = lookahead_type
    if field_type
      annotation = annotations[[field_type, i]]
      annotate_value!(annotation) if annotation
    end
  end
end

def annotate_rec_nth(type, annotations)
  each_rec_member_nth_by_type(type) do |ofs_end, i, field_type|
    if field_type
      annotation = annotations[[field_type, i]]
      annotate_value!(annotation) if annotation
    end
  end
end

## Tag converters

## startpos.esf arrays
  def lookahead_faction_ids
    save_ofs = @ofs
    ofs_end, count = get_ofs_end_and_item_count

    rv = {}
    id = nil

    count.times do |i|
      rec_ofs_end = get_ofs_end
      node_type, version = get_rec_header!
      return nil unless node_type == :FACTION # Version number doesn't really matter
      return nil unless rec_ofs_end == get_ofs_end

      while @ofs < rec_ofs_end
        t = get_byte
        if !@absa and (t == 0x80 or t == 0x81)
          @ofs += 3
          @ofs  = get_u
        elsif @abca and (t >= 0x80 and t <= 0xbf)
          @ofs += 1
          @ofs  = get_ofs_end
        elsif t == 0x04
          id = get_u
        elsif t == 0x16
          id = get_u1
        elsif t == 0x17
          id = get_u2
        elsif t == 0x08
          @ofs += 4
        elsif t == 0x0e
          if @abcf
            rv[id] = @str_lookup[get_u]
          else
            rv[id] = get_s
          end
          @ofs = rec_ofs_end
        elsif t == 0x0f
          if @abcf
            rv[id] = @asc_lookup[get_u]
          else
            rv[id] = get_ascii
          end
          @ofs = rec_ofs_end
        else
          warn "Unexpected field type %02X during lookahead of faction ids" % t
          return nil
        end
      end
    end
    return rv
  ensure
    @ofs = save_ofs
  end

  def convert_ary_FACTION_ARRAY
    @faction_ids = lookahead_faction_ids
    raise QuietSemanticFail.new
  end

  def convert_ary_UNIT__LIST
    data = get_ary_contents(:s).flatten
    raise SemanticFail.new if data.any?{|name| name =~ /\s/}
    out_ary!("unit_list", "", data.map{|name| " #{name.xml_escape}" })
  end

  def convert_rec_CAI_BDI_COMPONENT_BLOCK_OWNS
    annotate_rec("CAI_BDI_COMPONENT_BLOCK_OWNS",
      [:u, 0] => "BDI Information",
      [:u, 1] => "Army ID"
    )
  end

  def convert_rec_CAI_WORLD_REGION_HLCIS
    annotate_rec("CAI_WORLD_REGION_HLCIS",
      [:u, 1] => "HLCIS ID"
    )
  end

  def convert_rec_CAI_WORLD_RESOURCE_MOBILES
    annotate_rec("CAI_WORLD_RESOURCE_MOBILES",
      [:u, 3] => "Army ID",
      [:u_ary, 11] => "BDI Information",
      [:u, 13] => "HLCIS ID",
      [:u_ary, 15] => "BDI Information",
      [:u_ary, 19] => "BDI Information",
      [:u_ary, 22] => "BDI Information"
    )
  end

  def convert_ary_CAI_HISTORY_EVENT_HTML_CLASSES
    data = get_ary_contents(:asc).flatten
    raise SemanticFail.new if data.any?{|name| name =~ /\s/}
    out_ary!("cai_event_classes", "", data.map{|name| " #{name.xml_escape}" })
  end

  def convert_ary_UNIT_CLASS_NAMES_LIST
    data = get_ary_contents([:rec, :CAMPAIGN_LOCALISATION, nil], :bool)
    data = data.map{|loc, used|
      loc = ensure_loc(loc)
      raise SemanticFail.new if loc =~ /\s|=/
      [loc, used]
    }
    out_ary!("unit_class_names_list", "", data.map{|loc, used| " #{loc}=#{used ? 'yes' : 'no'}"})
  end

  def convert_ary_REGION_OWNERSHIP
    data = get_ary_contents(:s, :s)
    raise SemanticFali.new if data.any?{|region, owner| region =~ /\s|=/ or owner =~ /\s|=/}
    out_ary!("region_ownership", "", data.map{|region,owner| " #{region.xml_escape}=#{owner.xml_escape}" })
  end

  def convert_ary_RELIGION_BREAKDOWN
    data = get_ary_contents(:s, :flt)
    raise SemanticFali.new if data.any?{|name, value| name =~ /\s|=/}
    out_ary!("religion_breakdown", "", data.map{|name,value| " #{name.xml_escape}=#{value}" })
  end

  def convert_ary_RESOURCES_ARRAY
    convert_ary_contents_str("resources_array")
  end

  def convert_ary_REGION_KEYS
    convert_ary_contents_str("REGION_KEYS")
  end

  def convert_ary_COMMODITIES_ORDER
    convert_ary_contents_str("commodities_order")
  end

  def convert_ary_RESOURCES_ORDER
    convert_ary_contents_str("resources_order")
  end

  def convert_ary_PORT_INDICES
    data = get_ary_contents(:s, :u)
    raise SemanticFali.new if data.any?{|name, value| name =~ /\s|=/}
    @port_indices = Hash[data.map{|name,value| [value, name]}]
    out_ary!("port_indices", "", data.map{|name,value| " #{name.xml_escape}=#{value}" })
  end

  def convert_ary_SETTLEMENT_INDICES
    data = get_ary_contents(:s, :u)
    raise SemanticFali.new if data.any?{|name, value| name =~ /\s|=/}
    @settlement_indices = Hash[data.map{|name,value| [value, name]}]
    out_ary!("settlement_indices", "", data.map{|name,value| " #{name.xml_escape}=#{value}" })
  end

  def convert_ary_AgentAttributes
    data = get_ary_contents(:s, :i)
    out_ary!("agent_attributes", "", data.map{|attribute,level| " #{attribute.xml_escape}=#{level}" })
  end

  def convert_ary_AgentAttributeBonuses
    data = get_ary_contents(:s, :u)
    out_ary!("agent_attribute_bonuses", "", data.map{|attribute,level| " #{attribute.xml_escape}=#{level}" })
  end

  def convert_ary_AgentAncillaries
    convert_ary_contents_str("agent_ancillaries")
  end

## regions.esf arrays

  def convert_rec_query_info
    annotate_rec "query_info",
      [:u, 0] => "number of quads",
      [:u, 1] => "number of cells (cell = quad not empty)"
  end

  def convert_rec_cell
    (x,y), ab0, data = get_rec_contents(:v2, :u, :u_ary)
    raise SemanticFail.new if (data.size % 4) != 0
    data = data.pack("V*").unpack("l*") # Why sint32?

    a0, b0 = ab0 >> 16, ab0 & 0xffff
    a0n = (a0 == -1 ? "invalid" : @regions_lookup_table[a0]) || "unknown"

    out!(%Q[<cell x='#{x}' y='#{y}' region='#{a0} (#{a0n})' area='#{b0}'>])
    until data.empty?
      c1, c2, ab1, ab2 = data.shift(4)
      a1, b1 = ab1 >> 16, ab1 & 0xffff
      a2, b2 = ab2 >> 16, ab2 & 0xffff
      c1x = @region_data_vertices[2*c1]
      c1y = @region_data_vertices[2*c1+1]
      c2x = @region_data_vertices[2*c2]
      c2y = @region_data_vertices[2*c2+1]

      a1n = (a1 == -1 ? "invalid" : @regions_lookup_table[a1]) || "unknown"
      a2n = (a2 == -1 ? "invalid" : @regions_lookup_table[a2]) || "unknown"

      out!(%[ <line_segment v1='#{c1} (#{c1x},#{c1y})' region1='#{a1} (#{a1n})' area1='#{b1}' v2='#{c2} (#{c2x},#{c2y})' region2='#{a2} (#{a2n})' area2='#{b2}'/>])
    end
    out!(%Q[</cell>])
  end

  def convert_rec_transition_links
    annotate_rec "transition_links",
      [:u, 1] => "turns needed",
      [:u, 2] => "destination theatre #",
      [:u, 3] => "area # inside destination theatre"
  end

  def convert_rec_slot_descriptions
    v2a_annotations = [
      "land area",
      "sea area (present only for ports)",
      "total area (different from land area only in ports)",
    ]
    each_rec_member("slot_descriptions") do |ofs_end, i|
      next unless @data[@ofs].ord == 0x4c
      annotation = v2a_annotations.shift
      next unless annotation
      annotation = "<!-- #{annotation} -->"

      data = get_value![1].unpack("f*").map(&:pretty_single)
      if data.empty?
        out!("<v2_ary/>" + annotation)
      else
        out!("<v2_ary>" + annotation)
        out!(" #{data.shift},#{data.shift}") until data.empty?
        out!("</v2_ary>")
      end
    end
  end

  def convert_ary_region_keys
    data = get_ary_contents(:s, :v2)
    raise SemanticFali.new if data.any?{|name, xy| name =~ /\s|=|,/}
    out_ary!("region_keys", "", data.map{|name,(x,y)| " #{name.xml_escape}=#{x},#{y}"})
  end

  def convert_ary_groundtype_index
    convert_ary_contents_str("groundtype_index")
  end

  def convert_ary_land_indices
    data = get_ary_contents(:s, :byte)
    raise SemanticFali.new if data.any?{|name, value| name =~ /\s|=/}
    out_ary!("land_indices", "", data.map{|name,value| " #{name.xml_escape}=#{value}" })
  end

  def convert_ary_sea_indices
    data = get_ary_contents(:s, :byte)
    raise SemanticFali.new if data.any?{|name, value| name =~ /\s|=/}
    out_ary!("sea_indices", "", data.map{|name, value| " #{name.xml_escape}=#{value}" })
  end

  def convert_ary_DIPLOMACY_RELATIONSHIP_ATTITUDES_ARRAY
    draa_labels = [
      "State gift received",
      "Military alliance",
      "Alliance Broken",
      "Alliances not honoured",
      "Enemy of my enemy",
      "Trade Agreement",
      "Trade Agreement broken",
      "War",
      "Peace Treaty",
      "Allied with enemy",
      "War declared on friend",
      "Unreliable ally",
      "Territorial expansion",
      "Backstabber",
      "Assassination attempts",
      "Religion",
      "Government type",
      "Historical Friendship/Grievance",
      "Acts of sabotage",
      "Acts of espionage",
      "Threats of Attack",
      "Unknown (does not seem to do anything)",
    ]
    data = get_ary_contents(:i, :i, :i, :bool, :i, :bool)
    out!("<ary type=\"DIPLOMACY_RELATIONSHIP_ATTITUDES_ARRAY\">")
    data.each_with_index do |entry, i|
      label = draa_labels[i] || "Unknown #{i}"
      a,b,c,d,e,f = *entry
      d = d ? 'yes' : 'no'
      f = f ? 'yes' : 'no'
      if [a,b,c,d] == [0, 0, 0, 'no']
        abcd = ""
      else
        abcd = %Q[ drift="#{a}" current="#{b}" limit="#{c}" active1="#{d}"]
      end
      if [e,f] == [0, 'no']
        ef = ""
      else
        ef =  %Q[ extra="#{e}" active2="#{f}"]
      end
      out!(" <draa#{abcd}#{ef}/><!-- #{label.xml_escape} -->")
    end
    out!("</ary>")
  end

## trade_routes.esf

  def convert_rec_SPLINES
    each_rec_member("SPLINES") do |ofs_end, i|
      if i == 1 and lookahead_type == :bool
        annotate_value!("is land")
      end
    end
  end

  def convert_rec_ROUTES
    names = (@ports || []) + (@settlements || [])
    each_rec_member_nth_by_type("ROUTES") do |ofs_end, j, type|
      if j == 0 and type == :u
        val = get_value![1]
        name = names[val] || "unknown"
        out!("<u>#{val}</u><!-- start point (#{name}) -->")
      elsif j == 1 and type == :u
        val = get_value![1]
        name = names[val] || "unknown"
        out!("<u>#{val}</u><!-- end point (#{name}) -->")
      elsif j == 0 and type == :flt
        annotate_value!("length of route")
      end
    end
  end

## trade_routes.esf arrays

  def convert_ary_SETTLEMENTS
    data = get_ary_contents(:s).flatten
    raise SemanticFail.new if data.any?{|name| name =~ /\s/}
    @settlements = data
    out_ary!("settlements", "", data.map{|name| " #{name.xml_escape}" })
  end

  def convert_ary_PORTS
    data = get_ary_contents(:s).flatten
    raise SemanticFail.new if data.any?{|name| name =~ /\s/}
    @ports = data
    out_ary!("ports", "", data.map{|name| " #{name.xml_escape}" })
  end

## pathfinding.esf arrays

  def convert_rec_grid_data
    region_names = nil

    @path_ids_to_names = []

    x0 = nil
    y0 = nil
    cell_dim = nil
    x1 = nil
    y1 = nil

    each_rec_member("grid_data") do |ofs_end, i|
      tag = lookahead_type
      if i == 0 and lookahead_v2x?(ofs_end)
        x = get_value![1] * 0.5**20
        y = get_value![1] * 0.5**20
        x0 = x
        y0 = y
        out!(%Q[<v2x x="#{x}" y="#{y}"/><!-- starting point -->])
      elsif i == 1 and tag == :u2
        annotate_value!("starting x cell")
      elsif i == 2 and tag == :u2
        annotate_value!("starting y cell")
      elsif i == 3 and tag == :i
        v = get_value![1]
        vs = v * 0.5**20
        cell_dim = vs
        out!(%Q[<i>#{v}</i><!-- dimension of cells (#{vs}) -->])
      elsif i == 4 and tag == :u
        val = get_value![1]
        x1 = x0 + val*cell_dim
        out!("<u>#{val}</u><!-- columns -->")
      elsif i == 5 and tag == :u
        val = get_value![1]
        y1 = y0 + val*cell_dim
        out!("<u>#{val}</u><!-- rows -->")
        out!("<!-- boundingbox(#{x0},#{y0},#{x1},#{y1}) -->")
      elsif i == 6 and tag == :u
        annotate_value!("number of traits + number of empty cells")
      elsif i == 7 and tag == :u2
        annotate_value!("number of passable regions")
      elsif i == 8 and tag == :u2
        annotate_value!("number of listed regions (generally equals to the previous number, but not compulsory)")
      elsif i == 9 and @data[@ofs].ord == 0x43
        v = get_value![1].unpack("s*")
        region_names = {}

        out!(%Q[<i2_ary>])
        v.each_with_index{|r, i|
          region_names[i+1] = region_name = EtwRegionNames[r]
          out!(%Q[ #{r} <!-- #{region_name} -->])
        }
        out!(%Q[</i2_ary>])
      elsif i == 10 and @data[@ofs].ord == 0x47 and region_names
        v = get_value![1].unpack("v*")

        if v.index(0)
          out!(%Q[<u2_ary>])

          idx_to_names = []

          while v[0] != 0
            i    = v.shift
            name = region_names[i]
            idx_to_names << name
            @path_ids_to_names << name
            out!(" #{i} <!-- #{name} -->")
          end

          v.shift
          out!("")
          out!(" 0 <!-- sea -->")
          out!("")

          @path_ids_to_names << "sea"

          until v.empty?
            sz = v.shift
            elems = (0...sz).map{ v.shift }
            elems_names = elems.map{|i| region_names[i] }
            path = elems_names.join(", ")
            @path_ids_to_names << path
            out!(%Q[ #{sz} #{elems.join(", ")} <!-- #{path} -->])
          end

          out!(%Q[</u2_ary>])
        else
          out!(%Q[<u2_ary>])
          v.each{|i|
            out!(" #{i}")
          }
          out!(%Q[</u2_ary>])
        end
      end
    end
  end

  def convert_ary_vertices
    data = get_ary_contents(:i, :i)
    @pathfinding_vertices_ary = data
    scale = 0.5**20
    out_ary!("vertices", "", data.map{|x,y|
      " #{x*scale},#{y*scale}"
    })
  end

  def convert_rec_pathfinding_areas
    each_rec_member("pathfinding_areas") do |ofs_end, i|
      next unless i == 1 and @data[@ofs].ord == 0x48
      data = get_value![1]
      if data[0] >= data.size
        warn "Vertices count greater than data size, skipping annotations"
        out!("<u4_ary>")
        data.each{|u| out!(" #{u}")}
        out!("</u4_ary>")
      else
        @vertices_ary_lookup_table = {}
        idx_start = data.size
        idx_cur = nil
        out!("<u4_ary>")
        start = true
        cnt = 0
        scale = 0.5**20
        until data.empty?
          i = data.shift
          if cnt == 0
            idx = idx_start - data.size - 1
            idx_cur = @vertices_ary_lookup_table[idx] = []
            cnt = i
            if cnt > data.size
              warn "Vertices count greater than data size, annotations for pathfinding_areas will be wrong"
            else
              out!("") unless start
              start = false
              out!(" #{i} <!-- vertices count -->")
              nx_has_0123 = !(data[0, i] & [0,1,2,3]).empty?
              if nx_has_0123
                # out!(" <!-- open line -->")
              else
                out!(" <!-- closed line -->")
              end
            end
          else
            if i < @pathfinding_vertices_ary.size
              x, y = @pathfinding_vertices_ary[i]
              x = x*scale
              y = y*scale
              if i <= 3
                out!(" #{i}")
                idx_cur << "#{i}"
              else
                out!(" #{i} <!-- #{x},#{y} -->")
                idx_cur << "#{i} (#{x},#{y})"
              end
            else
              out!(" #{i}")
            end
            cnt -= 1
          end
        end
        out!("</u4_ary>")
      end
    end
    @pathfinding_vertices_ary = nil
  end

## regions.esf records
  def lookahead_region_data_vertices
    if @abca
      save_ofs = @ofs
      begin
        get_ofs_end
        return nil unless get_rec_header![0] == :vertices
        get_ofs_end
        return nil unless get_byte == 0x4c
        get_ofs_bytes.unpack("f*").map(&:pretty_single)
      ensure
        @ofs = save_ofs
      end
    else
      return nil unless @data[@ofs+4].ord == 0x80
      return nil unless @data[@ofs+12].ord == 0x4c
      ofs_end, = @data[@ofs+13, 4].unpack("V")
      @data[@ofs+17...ofs_end].unpack("f*").map(&:pretty_single)
    end
  end

  def lookahead_region_names
    save_ofs = @ofs
    ofs_end, count = get_ofs_end_and_item_count

    rv = []

    count.times do
      rec_ofs_end = get_ofs_end
      while @ofs < rec_ofs_end
        t = get_byte
        if t == 14
          if @abcf
            rv << @str_lookup[get_u]
          else
            rv << get_s
          end
          @ofs = rec_ofs_end
        else
          warn "Unexpected field type #{t} during lookahead of region names"
          return []
        end
      end
    end
    return rv
  ensure
    @ofs = save_ofs
  end

  def convert_ary_regions
    @regions_lookup_table = lookahead_region_names
    raise QuietSemanticFail.new
  end

  def convert_rec_region_data
    @region_data_vertices = lookahead_region_data_vertices
    @region_data_num ||= 0
    @region_data_num += 1
    dir_builder.region_data_num = @region_data_num
    tag!("rec", :type=>"region_data") do
      convert_until_ofs!(get_ofs_end)
    end
  end

  def convert_rec_faces
    raise SemanticFail.new unless @region_data_vertices
    data, = get_rec_contents(:u_ary)
    tag!("rec", :type=>"faces") do
      out!("<u4_ary>")
      data.each do |i|
        x = @region_data_vertices[2*i]
        y = @region_data_vertices[2*i+1]
        out!(" #{i} <!-- #{x} #{y}-->")
      end
      out!("</u4_ary>")
    end
  end

  def convert_rec_outlines
    raise SemanticFail.new unless @region_data_vertices
    each_rec_member("outlines") do |ofs_end, i|
      next unless lookahead_type == :u_ary
      data = get_value![1]
      out!("<u4_ary>")
      data.each do |i|
        x = @region_data_vertices[2*i]
        y = @region_data_vertices[2*i+1]
        out!(" #{i} <!-- #{x} #{y}-->")
      end
      out!("</u4_ary>")
    end
  end

  def convert_rec_BOUNDS_BLOCK
    (xmin, ymin), (xmax, ymax) = get_rec_contents(:v2, :v2)
    out!("<bounds_block xmin=\"#{xmin}\" ymin=\"#{ymin}\" xmax=\"#{xmax}\" ymax=\"#{ymax}\"/>")
  end

  def convert_rec_black_shroud_outlines
    name, data = get_rec_contents(:s, :v2_ary)
    data = data.unpack("f*").map(&:pretty_single)
    out!("<black_shroud_outlines name=\"#{name.xml_escape}\">")
    out!(" #{data.shift},#{data.shift}") until data.empty?
    out!("</black_shroud_outlines>")
  end

  def convert_rec_connectivity
    ab, cfrom, cto = get_rec_contents(:u, :u, :u)
    a, b = ab >> 16, ab & 0xffff
    an = (a == -1 ? "invalid" : @regions_lookup_table[a]) || "unknown"
    out!(%Q[<connectivity region="#{a} (#{an})" area="#{b}" from=\"#{cfrom}\" to=\"#{cto}\"/>])
  end

  def convert_rec_climate_map
    xsz, ysz, data = get_rec_contents(:u, :u, :bin6)
    path, rel_path = dir_builder.alloc_new_path("maps/climate_map-%d", nil, ".pgm")
    File.write_pgm(path, xsz, ysz, data)
    out!("<climate_map pgm=\"#{rel_path}\"/>")
  end

  def convert_rec_wind_map
    xsz, ysz, sea_phillips_constant, data = get_rec_contents(:u, :u, :flt, :bin2)
    path, rel_path = dir_builder.alloc_new_path("maps/wind_map-%d", nil, ".pgm")
    File.write_pgm(path, xsz*2, ysz, data)
    out!("<wind_map sea_phillips_constant=\"#{sea_phillips_constant}\" pgm=\"#{rel_path.xml_escape}\"/>")
  end

  def convert_rec_areas
    each_rec_member("areas") do |ofs_end, i|
      case [i, lookahead_type]
      when [0, :bool]
        annotate_value!("is land bridge")
      when [1, :bool]
        annotate_value!("English Channel coast ?")
      when [2, :bool]
        annotate_value!("passable")
      when [5, :u2]
        annotate_value!("adjoning passable areas id")
      when [8, :u2]
        annotate_value!("impassable land areas id (65535=passable)")
      when [9, :u2]
        annotate_value!("island id (65535=navigable, 104=ETW mainland)")
      end
    end
  end

## startpos.esf records
  def convert_rec_COMPRESSED_DATA
    # 5-byte block containing the information required by LZMA to decompress the data (often called ‘encode properties’)
    cdata, (mtypes, mdata) = get_rec_contents(:bin6, [:rec, :COMPRESSED_DATA_INFO, nil])
    raise SemanticFail.new unless mtypes == [:u, :bin6]
    sz, meta = mdata
    path, rel_path = dir_builder.alloc_new_path("compressed_data", nil, ".esf.xz")
    File.write(path, meta + [sz].pack("Q") + cdata)
    out!("<compressed_data path=\"#{rel_path.xml_escape}\"/>")
  end

  def convert_rec_CULTURE_PATHS
    agent, culture = get_rec_contents(:s, :s)
    out!(%Q[<culture_path agent="#{agent.xml_escape}" culture="#{culture.xml_escape}"/>])
  end

  def convert_rec_CAMPAIGN_VICTORY_CONDITIONS
    campaign_type_labels = [" (Short)", " (Long)", " (Prestige)", " (Global Domination)", " (Unplayable)"]
    data = get_rec_contents([:ary, :REGION_KEYS, nil], :bool, :u, :u, :bool, :u, :bool, :bool)
    regions, flag1, year, region_count, prestige_victory, campaign_type, flag2, flag3 = *data
    regions = regions.map{|region| ensure_types(region, :s)}.flatten
    campaign_type = "#{campaign_type}#{campaign_type_labels[campaign_type]}"
    prestige_victory = prestige_victory ? 'yes' : 'no'
    raise SemanticFail.new unless [flag1, flag2, flag3] == [false, false, false]
    out_ary!("victory_conditions",
      %Q[ year="#{year}" region_count="#{region_count}" prestige_victory="#{prestige_victory}" campaign_type="#{campaign_type}"],
      regions.map{|name| " #{name.xml_escape}"})
  end

  # def convert_rec_BUILDING_CONSTRUCTION_ITEM
  #   pp :bci
  #   types, data = get_rec_contents_dynamic
  #   raise "Die in fire" unless types.shift(5) == [:u, :bool, :u, :u, :u]
  #   code, flag, turns_done, turns, cost = data.shift(5)
  #   pp [:bci, code, flag, "#{turns_done}/#{turns}", cost, types, data]
  #   puts ""
  #   raise SemanticFail.new
  # end

  def convert_rec_CAMPAIGN_BONUS_VALUE_BLOCK
    (types, data), = get_rec_contents([:rec, :CAMPAIGN_BONUS_VALUE, nil])
    # types, data = get_rec_contents_dynamic
    raise "Die in fire" unless types.shift(3) == [:u, :i, :flt]
    type, subtype, value = *data.shift(3)
    case [type, *types]
    when [0, :s]
      out!(%Q[<campaign_bonus_0 subtype="#{subtype}" value="#{value}" agent="#{data[0].xml_escape}"/>])
    when [1]
      out!(%Q[<campaign_bonus_1 subtype="#{subtype}" value="#{value}"/>])
    when [2, :s]
      out!(%Q[<campaign_bonus_2 subtype="#{subtype}" value="#{value}" slot_type="#{data[0].xml_escape}"/>])
    when [3, :s]
      out!(%Q[<campaign_bonus_3 subtype="#{subtype}" value="#{value}" resource="#{data[0].xml_escape}"/>])
    when [6, :s]
      out!(%Q[<campaign_bonus_6 subtype="#{subtype}" value="#{value}" social_class="#{data[0].xml_escape}"/>])
    when [7, :s, :s]
      out!(%Q[<campaign_bonus_7 subtype="#{subtype}" value="#{value}" social_class="#{data[0].xml_escape}" religion="#{data[1].xml_escape}"/>])
    when [8, :s]
      out!(%Q[<campaign_bonus_8 subtype="#{subtype}" value="#{value}" weapon="#{data[0].xml_escape}"/>])
    when [9, :s]
      out!(%Q[<campaign_bonus_9 subtype="#{subtype}" value="#{value}" ammunition="#{data[0].xml_escape}"/>])
    when [10, :s]
      out!(%Q[<campaign_bonus_10 subtype="#{subtype}" value="#{value}" religion="#{data[0].xml_escape}"/>])
    when [11, :s]
      out!(%Q[<campaign_bonus_11 subtype="#{subtype}" value="#{value}" resource="#{data[0].xml_escape}"/>])
    when [12, :s]
      out!(%Q[<campaign_bonus_12 subtype="#{subtype}" value="#{value}" unit_ability="#{data[0].xml_escape}"/>])
    when [14, :s]
      out!(%Q[<campaign_bonus_14 subtype="#{subtype}" value="#{value}" unit_type="#{data[0].xml_escape}"/>])
    else
      # A lot of shogun 2 stuff here
      # [:cbv, 13, 8, 50.0, [:s], ["cavalry_missile"]]
      # [:cbv, 16, 7, 1.0, [:s], ["Genpei_Inf_Heavy_Naginata_Warrior_Monks"]]
      # [:cbv, 15, 7, 1.0, [:s], ["samurai_hero"]]
      # pp [:cbv, type, subtype, value, types, data]
      raise SemanticFail.new
    end
  end

  def convert_rec_POPULATION__CLASSES
    data, = get_rec_contents([:rec, :POPULATION_CLASS, nil])
    data = ensure_types(data, :s, :bin4, :bin4, :i,:i,:i,:i,:i, :u,:u,:u, :i,:i)
    cls = data.shift
    a1 = data.shift.unpack("l*")
    a2 = data.shift.unpack("l*")
    raise SemanticFail.new unless a1.size == 11
    raise SemanticFail.new unless a2.size == 6
    attrs = [
      ["social_class", cls.xml_escape],

      ["gov_type_happy", a1.shift],
      ["taxes", a1.shift],
      ["religion", a1.shift],
      ["events", a1.shift],
      ["culture", a1.shift],
      ["industry", a1.shift],
      ["characters_happy", a1.shift],
      ["war", a1.shift],
      ["reform", a1.shift],
      ["bankrupcy", a1.shift],
      ["resistance", a1.shift],

      ["gov_type", a2.shift],
      ["gov_buildings", a2.shift],
      ["characters", a2.shift],
      ["policing", a2.shift],
      ["garrison", a2.shift],
      ["crackdown", a2.shift],

      ["happy_total", data.shift],
      ["unhappy_total", data.shift],
      ["repression_total", data.shift],

      ["unknown_1", data.shift],    # rioting-related
      ["turns_rioting", data.shift],
      ["unknown_3", data.shift],    # (uint) rioting related
      ["unknown_4", data.shift],    # (uint) rioting-related
      ["unknown_5", data.shift],    # (uint) 7 is normal, 1/2/6/10 also seen, rioting-related
      ["unknown_zero", data.shift],
      ["foreign", data.shift],
    ]
    raise SemanticFail.new unless a1 == [] and a2 == [] and data == []
    out!("<population_class")
    attrs.each{|name,value|
      out!(%Q[  #{name}="#{value}"])
    }
    out!("/>")
  end

  def convert_rec_CAI_BORDER_PATROL_ANALYSIS_AREA_SPECIFIC_PATROL_POINTS
    data, = get_rec_contents([:rec, :CAI_BORDER_PATROL_POINT, nil])
    x, y, a = ensure_types(data, :i, :i, :u_ary)
    x *= 0.5**20
    y *= 0.5**20
    a = a.join(" ")
    out!(%Q[<cai_border_patrol_point x="#{x}" y="#{y}" a="#{a}"/>])
  end

  def convert_rec_QUAD_TREE_BIT_ARRAY_NODE
    ofs_end = get_ofs_end
    if ofs_end - @ofs == 10 and @data[@ofs].ord == 0x08 and @data[@ofs+5].ord == 0x08
      a, b = get_bytes(10).unpack("xVxV")
      a = "%08x" % a
      b = "%08x" % b
      out!(%Q[<quad_tree_leaf>#{b}#{a}</quad_tree_leaf>])
    else
      tag!("quad_tree_node") do
        send(@esf_type_handlers[get_byte]) while @ofs < ofs_end
      end
    end
  end

  def lookahead_v2x?(ofs_end)
    # STDERR.puts "LOOKAHEAD v2x #{@ofs} #{@data[@ofs, 10].unpack("C*").map{|u| "%02x " % u}}"
    u4_encodings = {0x04 => 4, 0x19 => 0, 0x1a => 1, 0x1b => 2, 0x1c => 3}
    return false unless @ofs < ofs_end and u4_encodings[@data[@ofs].ord]
    ofs2 = @ofs + 1 + u4_encodings[@data[@ofs].ord]
    return false unless ofs2 < ofs_end and u4_encodings[@data[ofs2].ord]
    true
  end

  # Call only if lookahead_v2x? says it's ok
  def convert_v2x!
    x = get_value![1] * 0.5**20
    y = get_value![1] * 0.5**20
    out!(%Q[<v2x x="#{x}" y="#{y}"/>])
  end

  def each_rec_member(type)
    tag!("rec", :type => type) do
      ofs_end = get_ofs_end
      i = 0
      while @ofs < ofs_end
        xofs = @ofs
        yield(ofs_end, i)
        send(@esf_type_handlers[get_byte]) if xofs == @ofs
        i += 1
      end
    end
  end

  def each_rec_member_nth_by_type(tag)
    nth_by_type = Hash.new(0)
    each_rec_member(tag) do |ofs_end, i|
      type = lookahead_type
      j = nth_by_type[type]
      nth_by_type[type] += 1
      yield(ofs_end, j, type)
    end
  end

  def convert_rec_OBSTACLE
    autoconvert_v2x "OBSTACLE", 7, 8
  end

  def convert_rec_OBSTACLE_BOUNDARIES
    path_type_to_name = [
      "passable area",
      "sea boundary",
      "transition area",
      "river",
      "land bridge area",
      "land bridge transition area",
      "road",
      "slot",
      "move area",
      "unit",
      "garrisoned unit",
      "fort",
    ]

    data, = get_rec_contents(:u_ary)
    recs = []
    until data.empty?
      n = data.shift
      raise "Malformatted OBSTACLE_BOUNDARIES" if data.size < 2*n + 2
      recs << [(0...n).map{ [data.shift, data.shift] }, data.shift]
      raise "Malformatted OBSTACLE_BOUNDARIES"  unless data.shift == 0
    end

    out!("<obstacle_boundaries>")
    recs.each do |pairs, id|
      row, col = id >> 16, id & 0xFFFF
      out!(%Q[ <obstacle_boundaries_entry row="#{row}" col="#{col}">])
      pairs.each do |a,b|

        passable_part = a >> 24
        unknown2      = (a >> 4) & 0xFFFFF
        path_type     = a & 0xF

        path_id = b >> 22
        path_id -= 1024 if path_id >= 512
        grid_path = ((b >> 21) & 1) == 1
        index = b & 0x1FFFFF

        out!(%Q[  <boundaries_passable_part passable_part="%d (%02x)" unknown2="%d (%05x)" path_type="%d (%s)" path_id="%d" grid_path="%s" index="%d"/>] % [
          passable_part, passable_part,
          unknown2, unknown2,
          path_type,
          path_type_to_name[path_type] || "unknown",
          path_id,
          grid_path ? 'yes' : 'no',
          index
        ])
      end
      out!( " </obstacle_boundaries_entry>")
    end
    out!("</obstacle_boundaries>")
  end

  def convert_rec_BOUNDARIES
    data, = get_rec_contents(:u_ary)
    data = data.map{|x|
      [(x&0x8000_0000) != 0, x & 0x7FFF_FFFF]
    }
    if data.empty?
      out!("<BOUNDARIES/>")
    else
      out!("<BOUNDARIES>")
      data.each{|a,b|
        a  = a ? 'yes' : 'no'
        out!(" #{a},#{b}")
      }
      out!("</BOUNDARIES>")
    end
  end

  def convert_rec_PATHFINDING_GRID
    each_rec_member("PATHFINDING_GRID") do |ofs_end, i|
      if i == 0 and @data[@ofs].ord == 0x08
        v = get_value![1]
        out!("<u>#{v}</u><!-- grid_paths -->")
      elsif i == 1 and @data[@ofs].ord == 0x48
        # Why is this int32, not uint32 again?
        v = get_value![1].pack("V*").unpack("l*")
        parts = []
        until v.empty?
          sz = v.shift
          parts << {
            :points => (0...sz).map{ [v.shift, v.shift] },
            :type => v.shift,
          }
        end
        out!("<grid_paths>")
        scale = 0.5 ** 20
        parts.each_with_index{|part, grid_no|
          out!(" <grid_path repetitions=\"#{part[:type]}\"><!-- #{grid_no} -->")
          part[:points].each{|x,y|
            x *= scale
            y *= scale
            out!("  #{x},#{y}")
          }
          out!(" </grid_path>")
        }
        out!("</grid_paths>")
      elsif i == 5 and @data[@ofs].ord == 0x48
        v = get_value![1]
        out!("<cell_id_coords>")
        until v.empty?
          rc = v.shift
          row, col = rc>>16, rc & 0xffff
          cell_id = v.shift
          out!(" #{row},#{col}=#{cell_id}")
        end
        out!("</cell_id_coords>")
      end
    end
  end

  def convert_rec_LOCOMOTABLE
    each_rec_member("LOCOMOTABLE") do |ofs_end, i|
      type = lookahead_type
      # Steps 0/1 take two elements, so steps 6/7 really mean elements 8/9
      if i == 0 or i == 1
        raise "Something is wrong here" unless lookahead_v2x?(ofs_end)
        convert_v2x!
      elsif i == 2 and type == :flt
        annotate_value!("Character Facing Direction")
      elsif i == 3 and type == :flt
        annotate_value!("Character Facing Direction")
      elsif i == 6 and type == :i
        annotate_value!("Movement Points Total")
      elsif i == 7 and type == :i
        annotate_value!("Movement Points Left")
      end
    end
  end

  def parse_path_boundary_data(a)
    u1 = a >> 24
    u2 = (a >> 4) & 0xFFFFF
    u3 = a & 0xF
    u3n = ["passable area", "sea boundary", "transition area", "river", "land bridge area",
      "land bridge transition area", "road", "slot"][u3] || "unknown"
    %Q[passable_part="%d (of 255)" unknown2="%d (%05x)" path_type="%d (%s)"] % [u1,u2,u2,u3,u3n]
  end

  def parse_path_id(path_id)
    if path_id == 1023 or path_id == -1
      path_name = "transition"
    else
      path_name = @path_ids_to_names[path_id] || "?"
    end
    %Q[path_id="%d (%s)"] % [path_id, path_name]
  end

  def convert_rec_grid_cells
    each_rec_member_nth_by_type("grid_cells") do |ofs_end, i|
      if i == 0 and @data[@ofs].ord == 0x46
        v = get_value![1].unpack("C*")
        str = []
        until v.empty?
          str << v.shift(4).map{|x| "%02x" % x}.join(" ")
        end
        out!("<bin6>#{str.join(' ; ')}</bin6>")
      elsif i == 1 and @data[@ofs].ord == 0x46
        v = get_value![1].unpack("C*")
        out!("<bin6><!-- #{v.size/12} empty cells -->")
        until v.empty?
          line = v.shift(12).map{|x| "%02x" % x}
          part0 = line[0,4].join(" ")
          part1 = line[4,4].join(" ")
          part2 = line[8,4].join(" ")
          out!(" #{part0} ; #{part1} ; #{part2}")
        end
        out!("</bin6>")
      elsif i == 0 and lookahead_type == :u
        val = get_value![1]
        t2,path_id = get_value!
        raise "Error converitng grid_cells" unless t2 == :u2
        attrs = parse_path_boundary_data(val)
        attrs2 = parse_path_id(path_id)
        out!(%Q[<boundaries_empty %s %s/>] % [attrs,attrs2])
      end
    end
  end

  # vertex_id is index to u4_ary in corresponding pathfinding-*.xml
  def convert_rec_boundaries
    a, b = get_rec_contents(:u, :u)
    attrs = parse_path_boundary_data(a)
    path_id = b >> 22
    path_id = -1 if path_id == 1023
    attrs2 = parse_path_id(path_id)
    vertex_index = b & 0x3FFFFF

    if @vertices_ary_lookup_table
      vertex_path = @vertices_ary_lookup_table[vertex_index]
      vertex_path = vertex_path ? vertex_path.join("; ") : "no such path"
      out!(%Q[<boundaries %s %s vertex_index="%d"/><!-- %s -->] % [attrs,attrs2,vertex_index,vertex_path])
    else
      out!(%Q[<boundaries %s %s vertex_index="%d"/>] % [attrs,attrs2,vertex_index])
    end

  end

  def convert_rec_FORT
    each_rec_member("FORT") do |ofs_end, i|
      if i == 0 and lookahead_v2x?(ofs_end)
        convert_v2x!
      elsif i == 4 and lookahead_type == :i
        annotate_value!("Fort Building Slot ID")
      elsif i == 5 and lookahead_type == :i
        annotate_value!("Faction ID")
      end
    end
  end

  def convert_rec_CAI_BDI_COMPONENT_PROPERTY_SET
    autoconvert_v2x "CAI_BDI_COMPONENT_PROPERTY_SET", 10, 13
  end

  def convert_rec_CAI_BDIM_WAIT_HERE
    autoconvert_v2x "CAI_BDIM_WAIT_HERE", 0
  end

  def convert_rec_CAI_BDIM_MOVE_TO_POSITION
    autoconvert_v2x "CAI_BDIM_MOVE_TO_POSITION", 1, 5
  end

  def convert_rec_CAI_BDI_RECRUITMENT_NEW_FORCE_OF_OR_REINFORCE_TO_STRENGTH
    autoconvert_v2x "CAI_BDI_RECRUITMENT_NEW_FORCE_OF_OR_REINFORCE_TO_STRENGTH", 4
  end

  def convert_rec_FACTION_INTERNATIONAL_TRADE_ROUTES_ARRAY
    annotate_rec_nth "FACTION_INTERNATIONAL_TRADE_ROUTES_ARRAY",
      [:u, 0] => "Route ID"
  end

  def convert_rec_CAI_WORLD_FACTIONS
    annotate_rec("CAI_WORLD_FACTIONS",
      [:u, 2] => "Faction ID",
      [:u_ary, 10] => "BDI Information",
      [:u, 12] => "HLCIS ID",
      [:u_ary, 14] => "BDI Information",
      [:u_ary, 21] => "BDI Information"
    )
  end

  def convert_rec_INTERNATIONAL_TRADE_ROUTE
    cnt = nil
    is_sea = nil
    each_rec_member_nth_by_type("INTERNATIONAL_TRADE_ROUTE") do |ofs_end, i, type|
      if i == 0 and type == :u
        cnt = val = get_value![1]
        out!("<u>#{val}</u><!-- Number Of Connections -->")
      elsif type == :u and (i-1)%2 == 0 and (i-1)/2 < cnt-1
        val = get_value![1]
        out!("<u>#{val}</u><!-- Start Point (#{port_lookpup(val)}) -->")
      elsif type == :u and (i-1)%2 == 1 and (i-1)/2 < cnt-1
        val = get_value![1]
        out!("<u>#{val}</u><!-- End Point (#{port_lookpup(val)}) -->")
      elsif type == :bool and i < cnt
        is_sea = val = get_value![1]
        tag = val ? "<yes/>" : "<no/>"
        out!("#{tag}<!-- Trading Over Sea -->")
      elsif type == :i and i < cnt
        if is_sea == nil or is_sea == true
          annotate_value!("Region ID Of Home Factions")
        else
          annotate_value!("Region ID Of Trading Factions")
        end
      elsif type == :i and i == cnt
        annotate_value!("Route ID")
      elsif @data[@ofs].ord == 0x48 and i == 0
        data = get_value![1]
        out!("<u4_ary>#{data.join(" ")}</u4_ary><!-- Commodities Quantity -->")
      elsif @data[@ofs].ord == 0x48 and i == 1
        data = get_value![1]
        out!("<u4_ary>#{data.join(" ")}</u4_ary><!-- Resources Quantity -->")
      end
    end
  end

  def convert_rec_FACTION_DOMESTIC_TRADE_ROUTES_ARRAY
    annotate_rec_nth "FACTION_DOMESTIC_TRADE_ROUTES_ARRAY",
      [:u, 0] => "Route ID"
  end

  def convert_rec_DOMESTIC_TRADE_ROUTE
    cnt = nil
    each_rec_member_nth_by_type("DOMESTIC_TRADE_ROUTE") do |ofs_end, i, type|
      if type == :s and i == 0
        annotate_value!("Theatre ID")
      elsif type == :u and i == 0
        cnt = val = get_value![1]
        out!("<u>#{val}</u><!-- Number Of Connections -->")
      elsif type == :u and (i-1)%2 == 0 and (i-1)/2 < cnt-1
        val = get_value![1]
        out!("<u>#{val}</u><!-- Start Point (#{port_lookpup(val)}) -->")
      elsif type == :u and (i-1)%2 == 1 and (i-1)/2 < cnt-1
        val = get_value![1]
        out!("<u>#{val}</u><!-- End Point (#{port_lookpup(val)}) -->")
      elsif @data[@ofs].ord == 0x48 and i == 0
        data = get_value![1]
        out!("<u4_ary>#{data.join(" ")}</u4_ary><!-- Commodities Quantity -->")
      end
    end
  end

  def convert_rec_CAMPAIGN_TRADE_MANAGER
    annotate_rec_nth "CAMPAIGN_TRADE_MANAGER",
      [:u_ary, 0] => "Commodities Baseline Price Per Unit",
      [:u_ary, 1] => "Commodities Current Price Per Unit",
      [:u_ary, 5] => "Resources Trade Value",
      [:flt_ary, 0] => "Demand"
  end

  def convert_rec_TEATHRES
    annotate_rec_nth "THEATRES",
      [:s, 0] => "Theatre ID"
  end

  def convert_rec_FACTION
    @dir_builder.faction_name = lookahead_str
    annotate_rec_nth "FACTION",
      [:i, 0] => "Faction ID",
      [:s, 0] => "Faction Name",
      [:s, 1] => "On Screen Name",
      [:bool, 2] => "True - Major, False - Minor",
      [:u_ary, 0] => "Governor ID For Each Theatre",
      [:s, 2] => "Religion",
      [:i, 1] => "Capital ID Else 0 If You Lose Your Capital",
      [:i, 2] => "Capital ID",
      [:bool, 6] => "Emergent",
      [:s, 3] => "Campaign AI Manager Behaviour (patch.pack)",
      [:s, 4] => "Campaign AI Personalities (patch.pack)",
      [:i, 5] => "Protectorate ID"
    @dir_builder.faction_name = nil
  end

  def convert_versioned_rec_FACTION(version)
    @dir_builder.faction_name = lookahead_str
    tag!("rec", :type=>"FACTION", :version => version) do
      convert_until_ofs!(get_ofs_end)
    end
    @dir_builder.faction_name = nil
  end

  def convert_rec_FACTION_TECHNOLOGY_MANAGER
    annotate_rec "FACTION_TECHNOLOGY_MANAGER",
      [:i, 1] => "Technology ID"
  end

  def convert_rec_REBEL_SETUP
    unit_list, faction, religion, gov, unknown, social_class = get_rec_contents([:ary, :"UNIT LIST", nil], :s, :s, :s, :u, :s)
    attrs = %Q[ faction="#{faction.xml_escape}" religion="#{religion.xml_escape}" gov="#{gov.xml_escape}" unknown="#{unknown}" social_class="#{social_class.xml_escape}"]
    unit_list = unit_list.map{|unit| ensure_types(unit, :s)}.flatten
    out_ary!("rebel_setup", attrs, unit_list.map{|unit| " #{unit}"})
  end

  def autoconvert_v2x(type, *positions)
    each_rec_member(type) do |ofs_end, i|
      convert_v2x! if positions.include?(i) and lookahead_v2x?(ofs_end)
    end
  end

  def convert_rec_REGION
    annotate_rec("REGION",
      [:s, 0] => "Region Name",
      [:i, 4] => "Region ID",
      [:u, 9] => "Subsistence Agricultural (SA)",
      [:u, 10] => "Industrial Wealth Plus (SA)",
      [:u, 11] => "Industrial Wealth Plus (SA) Minus Trading Losses",
      [:u, 12] => "Town Wealth",
      [:u, 13] => "Minimum Town Wealth",
      [:u, 14] => "Town Wealth",
      [:i, 15] => "Town Monetary Growth",
      [:u, 19] => "Controlling Faction ID",
      [:u, 21] => "Governor ID",
      [:s, 22] => "Theatre",
      [:s, 23] => "Emerging Nation",
      [:s, 24] => "Region Rebels",
      [:s, 25] => "Region Tribes",
      [:s, 37] => "Latest Constuction",
      [:u, 39] => "Region Array. From Top To Bottom. 1st 62 Regions 881206575. 2nd 15 Regions 1771634741. 3rd 32 Regions 1928099569. 4th 28 Regions 688200897. Why????"
    )
  end

  def convert_rec_REGION_SLOT
    each_rec_member("REGION_SLOT") do |ofs_end, i|
      if i == 6 and lookahead_v2x?(ofs_end)
        convert_v2x!
      else
        case [lookahead_type, i]
        when [:u, 2]
          annotate_value! "Building Slot ID"
        when [:s, 3]
          annotate_value! "Slot Name"
        when [:i, 7]
          annotate_value! "Something To Do With Commodities"
        when [:i, 8]
          annotate_value! "Something To Do With Town/Port/Road/Wall"
        when [:bool, 9]
          annotate_value! "Town or Port Emerged"
        when [:i, 10]
          annotate_value! "Commodities = 0; Town/Port/Road/Wall = 1"
        when [:i, 11]
          annotate_value! "Commodities = 2; Town/Port/Road/Wall = 1"
        when [:u, 12]
          annotate_value! "4294967295 Trade/Finance ID ??"
        when [:u, 13]
          annotate_value! "Town Or Port Emergence Order"
        end
      end
    end
  end

  def convert_rec_GOVERNMENT
    annotate_rec "GOVERNMENT",
      [:i, 0] => "Government ID",
      [:i, 2] => "Government Popularity"
  end

  def convert_rec_CHARACTER_POST
    annotate_rec "CHARACTER_POST",
      [:i, 0] => "Cabinet ID",
      [:s, 1] => "Cabinet Title",
      [:u, 2] => "Character ID",
      [:bool, 3] => "Governor",
      [:i, 4] => "Government ID",
      [:i, 5] => "Government ID"
  end

  def convert_rec_GOVERNORSHIP
    annotate_rec "GOVERNORSHIP",
      [:i, 1] => "Governor ID",
      [:u_ary, 2] => "Region ID",
      [:u, 3] => "Faction ID"
  end

  def convert_rec_MILITARY_FORCE
    annotate_rec("MILITARY_FORCE",
      [:u, 0] => "Army ID",
      [:u, 1] => "Character ID"
    )
  end

  def convert_rec_ARMY
    annotate_rec("ARMY",
      [:i, 4] => "Army ID",
      [:u, 5] => "Army In Building Slot ID",
      [:bool, 6] => "Under Seige",
      [:u, 7] => "Army ID Of Ship Escorting"
    )
  end

  def convert_rec_NAVY
    annotate_rec("NAVY",
      [:u, 4] => "Army ID In Ship"
    )
  end

  def convert_rec_CAI_WORLD_UNITS
    annotate_rec("CAI_WORLD_UNITS",
      [:u, 1] => "Unit ID",
      [:u_ary, 9] => "BDI Information",
      [:u_ary, 13] => "BDI Information",
      [:u_ary, 20] => "BDI Information"
    )
  end

  def convert_rec_CAI_UNIT
    annotate_rec("CAI_UNIT",
      [:u, 0] => "Character ID",
      [:u, 1] => "Army Unit ID",
      [:u, 2] => "Army ID"
    )
  end

  def convert_rec_CAI_WORLD_TRADING_POSTS
    annotate_rec("CAI_WORLD_TRADING_POSTS",
      [:u, 1] => "Trade Post ID",
      [:u_ary, 20] => "BDI Information"
    )
  end

  def convert_rec_CAI_GARRISONABLE
    annotate_rec("CAI_GARRISONABLE",
      [:u, 0] => "Army ID",
      [:u_ary, 2] => "Army ID"
    )
  end

  def convert_rec_CAI_FACTION_BDI_POOL
    annotate_rec("CAI_FACTION_BDI_POOL",
      [:u, 2] => "All these u records are BDI Information"
    )
  end

  def convert_rec_CAI_FACTION_MANAGER
    annotate_rec("CAI_FACTION_MANAGER",
      [:u, 0] => "Faction ID"
    )
  end

  def convert_rec_CAI_REGION
    annotate_rec("CAI_REGION",
      [:u_ary, 0] => "Theatre ID",
      [:u_ary, 1] => "HLCIS ID",
      [:u, 2] => "Settlement ID",
      [:u_ary, 3] => "Region Slot IDs Of Region_Slots In This Region",
      [:flt, 4] => "X Coordinate",
      [:flt, 5] => "Y Coordinate",
      [:u_ary, 7] => "Boundary ID",
      [:s, 10] => "Name",
      [:u, 11] => "Region ID",
      [:u, 12] => "Governor ID",
      [:u_ary, 13] => "Faction ID"
    )
  end

  def convert_rec_CAMPAIGN_PLAYER_SETUP
    annotate_rec("CAMPAIGN_PLAYER_SETUP",
      [:bool, 4] => "Playable"
    )
  end

  def convert_rec_CAI_RESOURCE_MOBILE
    annotate_rec("CAI_RESOURCE_MOBILE",
      [:u, 0] => "Character ID",
      [:u_ary, 4] => "Character IDs",
      [:u_ary, 5] => "Army Unit IDs",
      [:u, 10] => "Army ID",
      [:u_ary, 15] => "Sea Grid ID"
    )
  end

  def convert_rec_CAI_WORLD_REGIONS
    annotate_rec("CAI_WORLD_REGIONS",
      [:u, 2] => "Region ID",
      [:u_ary, 10] => "BDI Information",
      [:u_ary, 14] => "BDI Information",
      [:u_ary, 21] => "BDI Information"
    )
  end

  def convert_rec_CAI_REGION_BOUNDARY
    annotate_rec("CAI_REGION_BOUNDARY",
      [:u, 0] => "Region ID A",
      [:u, 1] => "Region ID 2",
      [:flt, 2] => "Distance between Region ID A and Region ID B"
    )
  end

  def convert_rec_CAI_WORLD_REGION_BOUNDARIES
    annotate_rec("CAI_WORLD_REGION_BOUNDARIES",
      [:u, 1] => "Boundary ID"
    )
  end

  def convert_rec_CAI_REGION_SLOT
    annotate_rec("CAI_REGION_SLOT",
      [:u, 1] => "Building Slot ID",
      [:bool, 5] => "Yes = port, No = town (ports have extra set of coordinates for their sea part following)"
    )
  end

  def convert_rec_CAI_SETTLEMENT
    annotate_rec("CAI_SETTLEMENT",
      [:u_ary, 0] => "Building_slot ID",
      [:u, 1] => "Faction ID",
      [:u, 2] => "Settlement ID"
    )
  end

  def convert_rec_SIEGEABLE_GARRISON_RESIDENCE
    each_rec_member("SIEGEABLE_GARRISON_RESIDENCE") do |ofs_end, i|
      if i == 1 and lookahead_type == :u
        annotate_value!("Building Slot ID")
      elsif i == 10 and lookahead_v2x?(ofs_end)
        convert_v2x!
      elsif i == 11 and lookahead_type == :u
        annotate_value!("Army ID")
      elsif i == 13 and lookahead_type == :u_ary
        annotate_value!("Character ID Of Garrison")
      end
    end
  end

  def convert_rec_CAI_WORLD_BUILDING_SLOTS
    annotate_rec("CAI_WORLD_BUILDING_SLOTS",
      [:u, 1] => "Building Slot ID",
      [:u_ary, 9] => "BDI Information",
      [:u, 11] => "0 = Unemerged, 1 = Emerged",
      [:u_ary, 13] => "BDI Information",
      [:u_ary, 20] => "BDI Information"
    )
  end

  def convert_rec_CAI_CHARACTER
    annotate_rec("CAI_CHARACTER",
      [:u, 0] => "Army ID",
      [:u, 1] => "Unit ID",
      [:u, 2] => "Army ID",
      [:u, 3] => "Army Character ID"
    )
  end

  def convert_rec_CAI_WORLD_CHARACTERS
    annotate_rec("CAI_WORLD_CHARACTERS",
      [:u, 2] => "Character ID"
    )
  end

  def convert_rec_CAI_WORLD_TECHNOLOGY_TREES
    annotate_rec("CAI_WORLD_TECHNOLOGY_TREES",
      [:u, 1] => "Technology ID",
      [:u_ary, 20] => "BDI Information"
    )
  end

  def convert_rec_CAI_BUILDING_SLOT
    annotate_rec("CAI_BUILDING_SLOT",
      [:u, 0] => "Building Slot ID",
      [:u, 1] => "Bulding type: 0 = Settlement, 1 = Wall/Road, 2 = Town, 3 = Port, 4 = Mine, 5 = Farm, 6 = Trade Resource, 7 = Multiple Trade Resources",
      [:u, 2] => "Settlement ID If Building Is part Of The Settlement. Region Slot ID If Not Part Of The Settlement"
    )
  end

  def convert_rec_CAI_FACTION_LEARNT_PARAMETERS_INFO
    annotate_rec("CAI_FACTION_LEARNT_PARAMETERS_INFO",
      [:u, 0] => "Faction ID"
    )
  end

  def convert_rec_CAI_WORLD_REGION_SLOTS
    annotate_rec("CAI_WORLD_REGION_SLOTS",
      [:u, 3] => "Region Slot ID",
      [:u_ary, 11] => "BDI Information",
      [:u_ary, 15] => "BDI Information",
      [:u_ary, 22] => "BDI Information"
    )
  end

  def convert_rec_CAI_FACTION
    annotate_rec("CAI_FACTION",
      [:u_ary, 0] => "Region ID Of Regions Owned By This Faction",
      [:u_ary, 1] => "Theatre ID",
      [:u_ary, 2] => "HLCIS ID",
      [:u_ary, 3] => "Army ID",
      [:u_ary, 4] => "Character ID",
      [:u, 5] => "Region ID Of Capital",
      [:u, 6] => "Faction ID",
      [:u, 9] => "Technology ID",
      [:u_ary, 10] => "Governor ID",
      [:u_ary, 31] => "BDI Information",
      [:u, 36] => "Region ID Of Capital",
      [:u_ary, 37] => "Region ID Of Faction's Needed For Victory Conditions"
    )
  end

  def convert_rec_CAI_WORLD_GOVERNORSHIPS
    annotate_rec("CAI_WORLD_GOVERNORSHIPS",
      [:u, 1] => "Governor ID",
      [:u_ary, 9] => "BDI Information",
      [:u_ary, 13] => "BDI Information"
    )
  end

  def convert_rec_CAI_GOVERNORSHIP
    annotate_rec("CAI_GOVERNORSHIP",
      [:u, 0] => "Governor ID",
      [:u, 1] => "Theatre ID",
      [:u, 2] => "Character ID",
      [:u_ary, 3] => "Region ID Of Regions Controlled By This Governor"
    )
  end

  def convert_rec_POPULATION
    annotate_rec("POPULATION",
      [:u, 1] => "Constant Over Game ?",
      [:u, 2] => "Constant Over Game ?",
      [:u, 3] => "New Minimum When New Settlement Emerged ?"
    )
  end
  def convert_rec_REGION_FACTORS
    annotate_rec("REGION_FACTORS",
      [:u, 2] => "Current Population",
      [:u, 3] => "Max Supported Population ?",
      [:u, 4] => "Constant Over Game ?",
      [:flt, 5] => "Population Growth"
    )
  end

  def convert_rec_ORDINAL_PAIR
    name, number = get_rec_contents([:rec, :CAMPAIGN_LOCALISATION, nil], :i)
    name = ensure_loc(name)
    out!(%Q[<ordinal_pair name="#{name.xml_escape}" number="#{number}"/>])
  end

  def convert_rec_PORTRAIT_DETAILS
    card, template, info, number = get_rec_contents(:s, :s, :s, :i)
    if [card, template, info, number] == ["", "", "", -1]
      out!(%Q[<portrait_details/>])
    elsif template.empty?
      out!(%Q[<portrait_details card="#{card.xml_escape}" info="#{info.xml_escape}" number="#{number}"/>])
    else
      out!(%Q[<portrait_details card="#{card.xml_escape}" template="#{template.xml_escape}" info="#{info.xml_escape}" number="#{number}"/>])
    end
  end

  def convert_rec_GOVERNORSHIP_TAXES
    level_lower, level_upper, rate_lower, rate_upper = get_rec_contents(:u, :u, :byte, :byte)
    out!(%Q[<gov_taxes level_lower="#{level_lower}" level_upper="#{level_upper}" rate_lower="#{rate_lower}" rate_upper="#{rate_upper}"/>])
  end

  def convert_ary_GOV_IMP
    data = get_ary_contents_dynamic
    raise SemanticFail.new unless data.size == 1
    type, data = *data[0]
    case type
    when [[:rec, :"GOVERNMENT::CONSTITUTIONAL_MONARCHY", nil]]
      raise SemanticFail.new unless data.size == 1
      type, data = *data[0]
      raise SemanticFail.new unless type == [:u, :bool, :i]
      minister_changes, had_elections, elections_due = *data
      out!(%Q[<gov_constitutional_monarchy minister_changes="#{minister_changes}" had_elections="#{had_elections ? 'yes' : 'no'}" elections_due="#{elections_due}"/>])
    when [[:rec, :"GOVERNMENT::ABSOLUTE_MONARCHY", nil]]
      raise SemanticFail.new unless data == [[[], []]]
      out!("<gov_absolute_monarchy/>")
    when [[:rec, :"GOVERNMENT::REPUBLIC", nil]]
      raise SemanticFail.new unless data.size == 1
      type, data = *data[0]
      raise SemanticFail.new unless type == [:u, :bool, :i, :u]
      minister_changes, had_elections, elections_due, term = *data
      out!(%Q[<gov_republic minister_changes="#{minister_changes}" had_elections="#{had_elections ? 'yes' : 'no'}" elections_due="#{elections_due}" term="#{term}"/>])
    else
      raise SemanticFail.new
    end
  end

  # This is somewhat dubious
  # Type seems to be:
  # * u, false, v2x
  # * u, true u, v2x
  # Revert if it causes any problems
  def convert_rec_CAI_TRADE_ROUTE_POI_RAID_ANALYSIS
    autoconvert_v2x "CAI_TRADE_ROUTE_POI_RAID_ANALYSIS", 2, 3
  end

  def convert_rec_CAI_BDIM_SIEGE_SH
    autoconvert_v2x "CAI_BDIM_SIEGE_SH", 5
  end

  def convert_rec_CAI_HLPP_INFO
    autoconvert_v2x "CAI_HLPP_INFO", 1
  end

  def convert_rec_CAI_BORDER_PATROL_ANALYSIS_AREA_SPECIFIC
    autoconvert_v2x "CAI_BORDER_PATROL_ANALYSIS_AREA_SPECIFIC", 3
  end

  def convert_rec_CAI_BDI_UNIT_RECRUITMENT_NEW
    autoconvert_v2x "CAI_BDI_UNIT_RECRUITMENT_NEW", 0
  end

  def convert_rec_FAMOUS_BATTLE_INFO
    x, y, name, a, b, c, d = get_rec_contents(:i, :i, :s, :i, :i, :i, :bool)
    x *= 0.5**20
    y *= 0.5**20
    d = d ? "yes" : "no"
    out!(%Q[<famous_battle_info x="#{x}" y="#{y}" name="#{name}" a="#{a}" b="#{b}" c="#{c}" d="#{d}"/>])
  end

  def convert_rec_CAI_REGION_HLCI
    a, b, c, x, y = get_rec_contents(:u, :u, :u_ary, :i, :i)
    x *= 0.5**20
    y *= 0.5**20
    c = c.join(" ")
    out!(%Q[<cai_region_hlci region_id="#{a}" area_id="#{b}" area="#{c}" x="#{x}" y="#{y}"/><!-- area (0 = first area in this region, 1 = second area in this region) -->])
  end

  def convert_rec_CAI_TRADING_POST
    a, x, y, b = get_rec_contents(:u, :i, :i, :u)
    x *= 0.5**20
    y *= 0.5**20
    out!(%Q[<cai_trading_post cai_theatres_id="#{a}" x="#{x}" y="#{y}" b="#{b}"/>])
  end

  def convert_rec_CAI_SITUATED
    x, y, a, b, c = get_rec_contents(:i, :i, :u, :u_ary, :u)
    x *= 0.5**20
    y *= 0.5**20
    b = b.join(" ")
    out!(%Q[<cai_situated x="#{x}" y="#{y}" region_id="#{a}" theatre_id="#{b}" area_id="#{c}"/>])
  end

  def convert_rec_THEATRE_TRANSITION__INFO
    link, a, b, c = get_rec_contents([:rec, :CAMPAIGN_MAP_TRANSITION_LINK, nil], :bool, :bool, :u)
    fl, time, dest, via = ensure_types(link, :flt, :u, :u, :u)
    raise SemanticFail.new if fl != 0.0 or b != false or c != 0
    if [a, time, dest, via] == [false, 0, 0xFFFF_FFFF, 0xFFFF_FFFF]
      out!("<theatre_transition/>")
    elsif a == true and time > 0 and dest != 0xFFFF_FFFF and via != 0xFFFF_FFFF
      out!(%Q[<theatre_transition turns="#{time}" destination="#{dest}" via="#{via}"/>])
    else
      raise SemanticFail.new
    end
  end

  def convert_rec_SETTLEMENT
    annotate_rec("SETTLEMENT",
      [:s, 3] => "DB Table Campaign_map_settlements",
      [:i, 4] => "Settlement ID",
      [:s, 5] => "DB Table Campaign_map_settlements"
    )
  end

  def convert_rec_CAI_WORLD_SETTLEMENTS
    annotate_rec("CAI_WORLD_SETTLEMENTS",
      [:u, 3] => "Settlement ID",
      [:u_ary, 11] => "BDI Information",
      [:u_ary, 15] => "BDI Information",
      [:u_ary, 22] => "BDI Information"
    )
  end

  def convert_rec_CAI_TECHNOLOGY_TREE
    data, = get_rec_contents(:u)
    out!("<cai_technology_tree>#{data}</cai_technology_tree><!-- Technology ID -->")
  end

  def convert_rec_RandSeed
    data, = get_rec_contents(:u)
    out!("<rand_seed>#{data}</rand_seed>")
  end

  def convert_rec_LAND_UNIT
    unit_type, unit_data, zero = get_rec_contents([:rec, :LAND_RECORD_KEY, nil], [:rec, :UNIT, nil], :u)
    unit_type, = ensure_types(unit_type, :s)
    raise SemanticError.new unless zero == 0

    unit_data = ensure_types(unit_data,
      [:rec, :UNIT_RECORD_KEY, nil],
      [:rec, :UNIT_HISTORY, nil],
      [:rec, :COMMANDER_DETAILS, nil],
      [:rec, :TRAITS, nil],
      :i,
      :u,
      :u,
      :i,
      :u,
      :u,
      :u,
      :u,
      :u,
      :byte,
      [:rec, :CAMPAIGN_LOCALISATION, nil]
    )
    raise SemanticError.new unless unit_type == ensure_types(unit_data.shift, :s)[0]
    unit_history = ensure_unit_history(unit_data.shift)

    fnam, lnam, faction = ensure_types(unit_data.shift, [:rec, :CAMPAIGN_LOCALISATION, nil], [:rec, :CAMPAIGN_LOCALISATION, nil], :s)
    commander = CommanderDetails.parse(ensure_loc(fnam), ensure_loc(lnam), faction)
    raise SemanticFail.new unless commander

    traits, = ensure_types(unit_data.shift, [:ary, :TRAIT, nil])
    raise SemanticFail.new unless traits == []

    unit_id = unit_data.shift
    current_size = unit_data.shift
    max_size = unit_data.shift
    mp = unit_data.shift
    kills  = unit_data.shift
    deaths = unit_data.shift
    commander_id = unit_data.shift
    commander_id = nil if commander_id == 0

    raise SemanticFail.new unless unit_data.shift == kills
    raise SemanticFail.new unless unit_data.shift == deaths

    exp = unit_data.shift
    name = ensure_loc(unit_data.shift)

    raise SemanticFail.new unless unit_data == []

    tag!("land_unit",
      :unit_id => unit_id,
      :commander_id => commander_id,
      :size => "#{current_size}/#{max_size}",
      :name => name,
      :commander => commander,
      :exp => exp,
      :kills => kills,
      :deaths => deaths,
      :mp => mp,
      :created => unit_history,
      :type => unit_type
    )
  end

  def convert_rec_GARRISON_RESIDENCE
    data, = get_rec_contents(:u)
    out!("<garrison_residence>#{data}</garrison_residence><!-- Faction ID -->")
  end

  def convert_rec_OWNED_INDIRECT
    data, = get_rec_contents(:u)
    out!("<owned_indirect>#{data}</owned_indirect><!-- Faction ID -->")
  end

  def convert_rec_OWNED_DIRECT
    data, = get_rec_contents(:u)
    out!("<owned_direct>#{data}</owned_direct><!-- Faction ID -->")
  end

  def convert_rec_FACTION_FLAG_AND_COLOURS
    path, r1,g1,b1, r2,g2,b2, r3,g3,b3 = get_rec_contents(:s, :byte,:byte,:byte, :byte,:byte,:byte, :byte,:byte,:byte)
    color1 = "#%02x%02x%02x" % [r1,g1,b1]
    color2 = "#%02x%02x%02x" % [r2,g2,b2]
    color3 = "#%02x%02x%02x" % [r3,g3,b3]
    out!("<flag_and_colours path=\"#{path.xml_escape}\" color1=\"#{color1.xml_escape}\" color2=\"#{color2.xml_escape}\" color3=\"#{color3.xml_escape}\"/>")
  end

## Tried to insert research_points_hint = "<!-- Research Points Invested (patch.pack) -->" school_slot_id_hint = "<!-- Researching By School ID -->" and failed.

  def convert_rec_techs
    status_hint = {0 => " (Researched)", 2 => " (Researchable)", 4 => " (Not Researchable)"}
    unknown2_hint = {0 => " (??)", 1 => " (??)", 2 => " (??)", 3 => " (??)", 4 => " (??)", 5 => " (??)"}
    data = get_rec_contents(:s, :u, :flt, :u, :u_ary, :u)
    name, status, research_points, school_slot_id, unknown1, unknown2 = *data
    status = "#{status}#{status_hint[status]}"
    unknown1 = unknown1.join(" ")
    unknown2 = "#{unknown2}#{unknown2_hint[unknown2]}"
    out!("<techs name=\"#{name.xml_escape}\" status=\"#{status}\" research_points=\"#{research_points}\" school_slot_id=\"#{school_slot_id}\" unknown1=\"#{unknown1}\" unknown2=\"#{unknown2}\"/>")
  end

  def convert_rec_COMMANDER__DETAILS
    fnam, lnam, faction = get_rec_contents([:rec, :CAMPAIGN_LOCALISATION, nil], [:rec, :CAMPAIGN_LOCALISATION, nil], :s)
    fnam = ensure_loc(fnam)
    lnam = ensure_loc(lnam)
    commander = CommanderDetails.parse(fnam, lnam, faction)
    if commander
      out!("<commander>#{commander.xml_escape}</commander>")
    else
      out!("<commander_details name=\"#{fnam.xml_escape}\" surname=\"#{lnam.xml_escape}\" faction=\"#{faction.xml_escape}\"/>")
    end
  end

  def convert_rec_AgentAbilities
    ability, level, attribute = get_rec_contents(:s, :i, :s)
    out!("<agent_ability ability=\"#{ability.xml_escape}\" level=\"#{level}\" attribute=\"#{attribute.xml_escape}\"/>")
  end

  def convert_rec_BUILDING
    health, name, faction, gov = get_rec_contents(:u, :s, :s, :s)
    out!("<building health=\"#{health}\" name=\"#{name.xml_escape}\" faction=\"#{faction.xml_escape}\" government=\"#{gov.xml_escape}\"/>")
  end

  def convert_v2_rec_DATE
    a,b,c,d = get_rec_contents(:u, :u, :u, :u)
    if [a,b,c,d] == [0,0,0,0]
      out!("<date2/>")
    else
      out!("<date2>#{d} #{c} #{b} #{a}</date2>")
    end
  end

  def convert_rec_DATE
    date = ensure_date(get_rec_contents_dynamic)
    if date
      out!("<date>#{date.xml_escape}</date>")
    else
      out!("<date/>")
    end
  end

  def convert_rec_UNIT_HISTORY
    date = ensure_unit_history(get_rec_contents_dynamic)
    out!("<unit_history>#{date.xml_escape}</unit_history>")
  end

  def convert_rec_MAPS
    name, x, y, unknown, data = get_rec_contents(:s, :u, :u, :i, :u_ary)
    raise SemanticFail.new if name =~ /\s/
    path, rel_path = dir_builder.alloc_new_path("map-%d", nil, ".pgm")
    File.write_pgm(path, x*4, y, data.pack("V*"))
    out!("<map name=\"#{name.xml_escape}\" unknown=\"#{unknown}\" pgm=\"#{rel_path.xml_escape}\"/>")
  end

  def convert_rec_CAMPAIGN_LOCALISATION
    loc_type, loc_data = get_rec_contents_dynamic
    if loc_type == [:s] and loc_data != [""]
      out!("<loc>#{loc_data[0].xml_escape}</loc>")
    elsif loc_type == [:s, :s] and loc_data == ["", ""]
      out!("<loc/>")
    elsif loc_type == [:s, :s] and loc_data[0] == "" and loc_data[1] != ""
      loc_data[1]
      out!("<loc2>#{loc_data[1].xml_escape}</loc2>")
    else
      raise SemanticFail.new
    end
  end

  def convert_rec_LAND_RECORD_KEY
    key, = get_rec_contents(:s)
    out!("<land_key>#{key.xml_escape}</land_key>")
  end

  def convert_rec_UNIT_RECORD_KEY
    key, = get_rec_contents(:s)
    out!("<unit_key>#{key.xml_escape}</unit_key>")
  end

  def convert_rec_NAVAL_RECORD_KEY
    key, = get_rec_contents(:s)
    out!("<naval_key>#{key.xml_escape}</naval_key>")
  end

  def convert_rec_TRAITS
    traits, = get_rec_contents([:ary, :TRAIT, nil])
    traits = traits.map{|trait| ensure_types(trait, :s, :i)}
    raise SemanticFail.new if traits.any?{|trait, level| trait =~ /\s|=/}
    out_ary!("traits", "", traits.map{|trait, level| " #{trait.xml_escape}=#{level}" })
  end

  def convert_rec_ANCILLARY_UNIQUENESS_MONITOR
    entries, = get_rec_contents([:ary, :ENTRIES, nil])
    entries = entries.map{|entry| ensure_types(entry, :s)}.flatten
    raise SemanticFail.new if entries.any?{|entry| entry =~ /\s|=/}
    out_ary!("ancillary_uniqueness_monitor", "", entries.map{|entry| " #{entry.xml_escape}" })
  end

  def convert_rec_REGION_OWNERSHIPS_BY_THEATRE
    theatre, ownerships = get_rec_contents(:s, [:ary, :REGION_OWNERSHIPS, nil])
    ownerships = ownerships.map{|o| ensure_types(o, :s, :s)}
    raise SemanticFail.new if ownerships.any?{|region, owner| region =~ /\s|=/ or owner =~ /\s|=/}
    out_ary!("region_ownerships_by_theatre", " theatre=\"#{theatre.xml_escape}\"", ownerships.map{|region, owner| " #{region.xml_escape}=#{owner.xml_escape}" })
  end

  def convert_rec_ALLIED_IN_WAR_AGAINST
    each_rec_member("ALLIED_IN_WAR_AGAINST") do |ofs_end, i|
      if i == 0 and lookahead_type == :u
        id = get_value![1]
        tag = "<u>#{id}</u>"
        tag += "<!-- #{@faction_ids[id].xml_escape} -->" if @faction_ids and @faction_ids[id]
        out!(tag)
      end
    end
  end

  def convert_rec_CHARACTER_DETAILS
    annotate_rec("CHARACTER_DETAILS",
      [:s, 4] => "Head Of State",
      [:u, 10] => "Character ID"
    )
  end

  def convert_rec_CHARACTER
    each_rec_member_nth_by_type("CHARACTER") do |ofs_end, i|
      case [i, lookahead_type]
      when [0, :i]
        annotate_value!("Character ID")
      when [0, :u]
        annotate_value!("Army ID")
      when [1, :u]
        annotate_value!("Unit ID")
      when [3, :u]
        annotate_value!("Character In Building Slot ID")
      when [4, :u]
        annotate_value!("Cabinet ID")
      when [1, :bool]
        annotate_value!("Government Opposition")
      when [0, :flt]
        annotate_value!("10 - Land Leader / 15 - Navy Leader")
      else
        if i == 0 and @data[@ofs].ord == 0x48
          data = get_value![1].pack("V*").unpack("l*").map{|u| u * (0.5**20) }
          if data.empty?
            out!("<v2x_ary/>")
          else
            out!("<v2x_ary>")
            until data.empty?
              out!(" #{data.shift},#{data.shift}")
            end
            out!("</v2x_ary>")
          end
        end
      end
    end
  end

  def convert_rec_DIPLOMACY_RELATIONSHIP
    each_rec_member("DIPLOMACY_RELATIONSHIP") do |ofs_end, i|
      case [i, lookahead_type]
      when [0, :i]
        id = get_value![1]
        tag = "<i>#{id}</i>"
        tag += "<!-- #{@faction_ids[id].xml_escape} -->" if @faction_ids and @faction_ids[id]
        out!(tag)
      when [2, :bool]
        annotate_value!("Trade Agreement")
      when [3, :i]
        annotate_value!("Military Access (-1 = Infinite)")
      when [4, :s]
        annotate_value!("Protectorate/Patron Standing")
      when [6, :u]
        annotate_value!("20 If Allied")
      when [13, :u]
        annotate_value!("10 If Allied")
      when [20, :s]
        annotate_value!("Diplomatic Standing")
      end
    end
  end

  def convert_rec_TRADE_SEGMENTS
    each_rec_member_nth_by_type("TRADE_SEGMENTS") do |ofs_end, j, type|
      if type == :bool and j == 0
        annotate_value!("Is Land")
      elsif type == :u and j == 0
        annotate_value!("Number Of Sub-segments")
      elsif type == :v2 and j % 4 == 0
        annotate_value!("Sub-segment ##{j / 4}")
      elsif type == :flt and j == 0
        annotate_value!("Length Of Segment")
      elsif @data[@ofs].ord == 0x4a and j == 0
        out!("<!-- Lengths Of Sub-segments -->")
        # pass through
      elsif @data[@ofs].ord == 0x4a and j == 1
        out!("<!-- Cummulative Lengths Of Sub-segments -->")
        # pass through
      elsif @data[@ofs].ord == 0x48 and j == 0
        out!("<!-- Domestic Trade Route IDs -->")
        # pass through
      elsif @data[@ofs].ord == 0x48 and j == 1
        out!("<!-- International Trade Route IDs -->")
        # pass through
      end
    end
  end

  def port_lookpup(val)
    pi = @port_indices || {}
    si = @settlement_indices || {}
    pi[val] || si[val] || "unknown"
  end

  def convert_rec_TRADE_ROUTES
    pi = @port_indices || {}
    si = @settlement_indices || {}
    each_rec_member_nth_by_type("TRADE_ROUTES") do |ofs_end, j, type|
      if type == :u and j == 0
        val = get_value![1]
        name = pi[val] || si[val] || "unknown"
        out!("<u>#{val}</u><!-- Start Point (#{name}) -->")
      elsif type == :u and j == 1
        val = get_value![1]
        name = pi[val] || si[val] || "unknown"
        out!("<u>#{val}</u><!-- End Point (#{name}) -->")
      elsif type == :flt and j == 0
        val = get_value![1]
        out!("<flt>#{val}</flt><!-- Length Of Route -->")
      end
    end
  end

## bmd.dat records

  def convert_rec_HEIGHT_FIELD
    xi, yi, (xf, yf), data, unknown, hmin, hmax = get_rec_contents(:u, :u, :v2, :flt_ary, :i, :flt, :flt)
    path, rel_path = dir_builder.alloc_new_path("height_field-%d", nil, ".pgm")
    File.write_pgm(path, 4*xi, yi, data)
    out!("<height_field xsz=\"#{xf}\" ysz=\"#{yf}\" pgm=\"#{rel_path.xml_escape}\" unknown=\"#{unknown}\" hmin=\"#{hmin}\" hmax=\"#{hmax}\"/>")
  end

  def convert_rec_GROUND_TYPE_FIELD
    xi, yi, (xf, yf), data = get_rec_contents(:u, :u, :v2, :bin4)
    path, rel_path = dir_builder.alloc_new_path("group_type_field", nil, ".pgm")
    File.write_pgm(path, 4*xi, yi, data)
    out!("<ground_type_field xsz=\"#{xf}\" ysz=\"#{yf}\" pgm=\"#{rel_path.xml_escape}\"/>")
  end

  def convert_rec_BMD_TEXTURES
    types, data = get_rec_contents_dynamic
    tag!("bmd_textures") do
      until data.empty?
        if data.size == 3 and types == [:u, :u, :bin6]
          xsz, ysz, pxdata = data
          path, rel_path = dir_builder.alloc_new_path("bmd_textures/texture-%d", nil, ".pgm")
          File.write_pgm(path, 4*xsz, ysz, pxdata)
          out!("<bmd_pgm pgm=\"#{rel_path.xml_escape}\"/>")
          break
        end
        t = types.shift
        v = data.shift

        case t
        when :s
          out!("<s>#{v.xml_escape}</s>")
        when :i
          out!("<i>#{v}</i>")
        when :u
          out!("<u>#{v}</u>")
        when :bool
          if v
            out!("<yes/>")
          else
            out!("<no/>")
          end
        when :bin6
          rel_path = dir_builder.save_binfile("bmd_textures/texture", nil, ".jpg", v)
          out!("<bin6ext path=\"#{rel_path.xml_escape}\"/>")
        else
          # Should be possible to recover from it, isn't just yet
          raise "Total failure while converting BMD_TEXTURES"
        end
      end
    end
  end

## poi.esf
  def convert_rec_CAI_POI_ROOT
    pois = PoiEsfParser.new(*get_rec_contents_dynamic).get_pois

    tag!("pois") do
      pois.each do |poi|
        code1 = poi.shift
        flag1 = poi.shift
        x, y = poi.shift
        region_name, region_id = poi.shift
        val1 = poi.shift
        ary1 = poi.shift
        val2 = poi.shift
        ary2 = poi.shift
        ary3 = poi.shift
        code2 = poi.shift
        flag2 = poi.shift
        raise SemanticFail.new unless poi == []
        attrs = {
          :x => x, :y => y,
          :region_name => region_name,
          :region_id => region_id,
          :code1 => code1,
          :code2 => code2,
          :flag1 => flag1 ? 'yes' : 'no',
          :flag2 => flag2 ? 'yes' : 'no',
          :val1 => val1,
          :val2 => val2,
          :ids => ary3.join(" ")
        }
        if ary1.empty? and ary2.empty?
          tag!("poi", attrs)
        else
          tag!("poi", attrs) do
            ary1.each{|name, val|
              out!(%Q[<poi_region1 name="#{name}" val="#{val}"/>])
            }
            ary2.each{|name, val|
              out!(%Q[<poi_region2 name="#{name}" val="#{val}"/>])
            }
          end
        end
      end
    end
  end

## sea_grids.esf
  def convert_rec_CAI_SEA_GRID_ROOT
    sea_grids = SeaGridsEsfParser.new(*get_rec_contents_dynamic).get_sea_grids

    tag!("sea_grids") do
      sea_grids.each do |grid_name, (min_x, min_y), (max_x, max_y), factor, areas, connections|
        tag!("theatre_sea_grid",
            :name => grid_name,
            :minx => min_x, :miny => min_y, :maxx => max_x, :maxy => max_y,
            :factor => factor
          ) do
          areas.each do |row|
            tag!("sea_grid_row") do
              row.each do |(cmin_x, cmin_y), (cmax_x, cmax_y), area_id, lands, seas, ports, numbers|
                tag!("sea_grid_cell", :area_id => area_id, :minx => cmin_x, :miny => cmin_y, :maxx => cmax_x, :maxy => cmax_y) do
                  out_ary!("sea_grid_lands", "", lands.map{|x| " #{x}"})
                  out_ary!("sea_grid_seas", "", seas.map{|x| " #{x}"})
                  out_ary!("sea_grid_ports", "", ports.map{|x| " #{x}"})
                  out_ary!("sea_grid_numbers", "", numbers.empty? ? [] : [" " + numbers.join(" ")])
                end
              end
            end
          end
          tag!("sea_grid_connections") do
            connections.each do |area1, area2, x|
              out!("<sea_grid_connection area1=\"#{area1}\" area2=\"#{area2}\" value=\"#{x}\"/>")
            end
          end
        end
      end
    end
  end

## farm_tile_templates
  def convert_rec_WALL_POST_LIST
    data, = get_rec_contents([:rec, :WALL_POST, nil])
    (x, y), (dx, dy) = ensure_types(data, :v2, :v2)
    out!(%Q[<wall_post x="#{x}" y="#{y}" dx="#{dx}" dy="#{dy}"/>])
  end

  def convert_rec_FARM_TREE_LIST
    data, = get_rec_contents([:rec, :FARM_TREE, nil])
    type, (x, y) = ensure_types(data, :s, :v2)
    out!(%Q[<farm_tree type="#{type.xml_escape}" x="#{x}" y="#{y}"/>])
  end

  def convert_rec_ID_LIST
    data, = get_rec_contents(:u_ary)
    if data.empty?
      out!("<id_list/>")
    else
      out!("<id_list>#{data.join(" ")}</id_list>")
    end
  end

## autoconfigure everything

  self.instance_methods.each do |m|
    if m.to_s =~ /\Aconvert_ary_(.*)\z/
      ConvertSemanticAry[nil][$1.gsub("__", " ").to_sym] = m
    elsif m.to_s =~ /\Aconvert_rec_(.*)\z/
      ConvertSemanticRec[nil][$1.gsub("__", " ").to_sym] = m
    end
  end
  # Range of these covering NTW...S2TW
  # We only care about faction name lookup
  (39..46).each{|version|
    m = :"convert_v#{version}_rec_FACTION"
    define_method(m){ convert_versioned_rec_FACTION(version)}
    ConvertSemanticRec[version][:FACTION] = m
  }
  ConvertSemanticRec[2][:DATE] = :convert_v2_rec_DATE
end
