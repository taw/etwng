require "sea_grids"
require "poi"
require "commander_details"

module EsfSemanticConverter
  ConvertSemanticAry = {}
  ConvertSemanticRec = {}

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
    year, season = ensure_types(date, :u4, :asc)
    raise SemanticFail.new if season =~ /\s/
    if year == 0 and season == "summer"
      nil
    else
      "#{season} #{year}"
    end
  end
  
  def ensure_unit_history(unit_history)
    date, a, b = ensure_types(unit_history, [:rec, :DATE, nil], :u4, :u4)
    date = ensure_date(date)
    raise SemanticFail.new unless a == 0 and b == 0 and date
    date
  end

## Tag converters

## startpos.esf arrays
  def convert_ary_UNIT__LIST
    data = get_ary_contents(:s).flatten
    raise SemanticFail.new if data.any?{|name| name =~ /\s/}
    out_ary!("unit_list", "", data.map{|name| " #{name.xml_escape}" })
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
    data = get_ary_contents(:s, :u4)
    raise SemanticFali.new if data.any?{|name, value| name =~ /\s|=/}
    out_ary!("port_indices", "", data.map{|name,value| " #{name.xml_escape}=#{value}" })
  end

  def convert_ary_SETTLEMENT_INDICES
    data = get_ary_contents(:s, :u4)
    raise SemanticFali.new if data.any?{|name, value| name =~ /\s|=/}
    out_ary!("settlement_indices", "", data.map{|name,value| " #{name.xml_escape}=#{value}" })
  end
  
  def convert_ary_AgentAttributes
    data = get_ary_contents(:s, :i4)
    out_ary!("agent_attributes", "", data.map{|attribute,level| " #{attribute.xml_escape}=#{level}" })
  end
  
  def convert_ary_AgentAttributeBonuses
    data = get_ary_contents(:s, :u4)
    out_ary!("agent_attribute_bonuses", "", data.map{|attribute,level| " #{attribute.xml_escape}=#{level}" })
  end
  
  def convert_ary_AgentAncillaries
    convert_ary_contents_str("agent_ancillaries")
  end
  
## regions.esf arrays

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
    data = get_ary_contents(:i4, :i4, :i4, :bool, :i4, :bool)
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
  
## traderoutes.esf arrays

  def convert_ary_SETTLEMENTS
    convert_ary_contents_str("settlements")
  end

## pathfinding.esf arrays

  def convert_ary_vertices
    data = get_ary_contents(:i4, :i4)
    scale = 0.5**20
    out_ary!("vertices", "", data.map{|x,y|
      " #{x*scale},#{y*scale}"
    })
  end
  
## regions.esf records

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
    mask, cfrom, cto = get_rec_contents(:u4, :u4, :u4)
    out!("<connectivity mask=\"#{"%08x" % mask}\" from=\"#{cfrom}\" to=\"#{cto}\"/>")
  end

  def convert_rec_climate_map
    xsz, ysz, data = get_rec_contents(:u4, :u4, :bin6)
    path, rel_path = dir_builder.alloc_new_path("maps/climate_map", nil, ".pgm")
    File.write_pgm(path, xsz, ysz, data)
    out!("<climate_map pgm=\"#{rel_path}\"/>")
  end

  def convert_rec_wind_map
    xsz, ysz, unknown, data = get_rec_contents(:u4, :u4, :flt, :bin2)
    path, rel_path = dir_builder.alloc_new_path("maps/wind_map", nil, ".pgm")
    File.write_pgm(path, xsz*2, ysz, data)
    out!("<wind_map unknown=\"#{unknown}\" pgm=\"#{rel_path.xml_escape}\"/>")
  end

## startpos.esf records
  def convert_rec_CAMPAIGN_VICTORY_CONDITIONS
    campaign_type_labels = [" (short)", " (long)", " (prestige)", " (global domination)", " (unplayable)"]
    data = get_rec_contents([:ary, :REGION_KEYS, nil], :bool, :u4, :u4, :bool, :u4, :bool, :bool)
    regions, flag1, year, region_count, prestige_victory, campaign_type, flag2, flag3 = *data
    regions = regions.map{|region| ensure_types(region, :s)}.flatten
    campaign_type = "#{campaign_type}#{campaign_type_labels[campaign_type]}"
    prestige_victory = prestige_victory ? 'yes' : 'no'
    raise SemanticFail.new unless [flag1, flag2, flag3] == [false, false, false]
    out_ary!("victory_conditions",
      %Q[ year="#{year}" region_count="#{region_count}" prestige_victory="#{prestige_victory}" campaign_type="#{campaign_type}"],
      regions.map{|name| " #{name.xml_escape}"})
    end
  
  def convert_rec_CAMPAIGN_BONUS_VALUE_BLOCK
    (types, data), = get_rec_contents([:rec, :CAMPAIGN_BONUS_VALUE, nil])
    # types, data = get_rec_contents_dynamic
    raise "Die in fire" unless types.shift(3) == [:u4, :i4, :flt]
    type, subtype, value = *data.shift(3)
    case [type, *types]
    when [0, :s]
      out!(%Q[<campaign_bonus_0 subtype="#{subtype}" value="#{value}" agent="#{data[0].xml_escape}"/>])
    when [1]
      out!(%Q[<campaign_bonus_1 subtype="#{subtype}" value="#{value}"/>])
    when [2, :s]
      raise "Die in fire" unless types == [:s]
      out!(%Q[<campaign_bonus_2 subtype="#{subtype}" value="#{value}" slot_type="#{data[0].xml_escape}"/>])
    when [3, :s]
      out!(%Q[<campaign_bonus_3 subtype="#{subtype}" value="#{value}" resource="#{data[0].xml_escape}"/>])
    when [6, :s]
      raise "Die in fire" unless types == [:s]
      out!(%Q[<campaign_bonus_6 subtype="#{subtype}" value="#{value}" social_class="#{data[0].xml_escape}"/>])
    when [7, :s, :s]
      out!(%Q[<campaign_bonus_7 subtype="#{subtype}" value="#{value}" social_class="#{data[0].xml_escape}" religion="#{data[1].xml_escape}"/>])
    when [10, :s]
      out!(%Q[<campaign_bonus_10 subtype="#{subtype}" value="#{value}" religion="#{data[0].xml_escape}"/>])
    when [11, :s]
      out!(%Q[<campaign_bonus_11 subtype="#{subtype}" value="#{value}" resource="#{data[0].xml_escape}"/>])
    when [14, :s]
      out!(%Q[<campaign_bonus_14 subtype="#{subtype}" value="#{value}" unit_type="#{data[0].xml_escape}"/>])
    else
      pp [:cbv, type, subtype, value, types, data]
      puts ""
      raise SemanticFail.new
    end
  end
  
  def convert_rec_CAI_BORDER_PATROL_ANALYSIS_AREA_SPECIFIC_PATROL_POINTS
    data, = get_rec_contents([:rec, :CAI_BORDER_PATROL_POINT, nil])
    x, y, a = ensure_types(data, :i4, :i4, :bin8)
    x *= 0.5**20
    y *= 0.5**20
    a = a.unpack("V*").join(" ")
    out!(%Q[<cai_border_patrol_point x="#{x}" y="#{y}" a="#{a}"/>])
  end
  
  
  def convert_rec_LOCOMOTABLE
    types, data = get_rec_contents_dynamic
    
    raise SemanticFail.new unless types[0, 4] == [:i4, :i4, :i4, :i4]

    types = types[4..-1]
    
    tag!("rec", :type => "LOCOMOTABLE") do
      x = data.shift * 0.5**20
      y = data.shift * 0.5**20
      out!(%Q[<v2x x="#{x}" y="#{y}"/>])
      x = data.shift * 0.5**20
      y = data.shift * 0.5**20
      out!(%Q[<v2x x="#{x}" y="#{y}"/>])
      until data.empty?
        v = data.shift
        t = types.shift
        case t
        when :i4
          out!("<i>#{v}</i>")
        when :u4
          out!("<u>#{v}</u>")
        when :flt
          out!("<flt>#{v}</flt>")
        when :u2x
          out!("<u2x>#{v}</u2x>")
        when :bool
          if v
            out!("<yes/>")
          else
            out!("<no/>")
          end
        else
          # Should be possible to recover from it, isn't just yet
          raise "Total failure while converting LOCOMOTABLE"
        end
      end
    end
  end
  
  def convert_rec_FAMOUS_BATTLE_INFO
    x, y, name, a, b, c, d = get_rec_contents(:i4, :i4, :s, :i4, :i4, :i4, :bool)
    x *= 0.5**20
    y *= 0.5**20
    d = d ? "yes" : "no"
    out!(%Q[<famous_battle_info x="#{x}" y="#{y}" name="#{name}" a="#{a}" b="#{b}" c="#{c}" d="#{d}"/>])
  end

  def convert_rec_CAI_REGION_HLCI
    a, b, c, x, y = get_rec_contents(:u4, :u4, :bin8, :i4, :i4)
    x *= 0.5**20
    y *= 0.5**20
    c = c.unpack("V*").join(" ")
    out!(%Q[<cai_region_hlci a="#{a}" b="#{b}" c="#{c}" x="#{x}" y="#{y}"/>])
  end

  def convert_rec_CAI_TRADING_POST
    a, x, y, b = get_rec_contents(:u4, :i4, :i4, :u4)
    x *= 0.5**20
    y *= 0.5**20
    out!(%Q[<cai_trading_post a="#{a}" x="#{x}" y="#{y}" b="#{b}"/>])
  end

  def convert_rec_CAI_SITUATED
    x, y, a, b, c = get_rec_contents(:i4, :i4, :u4, :bin8, :u4)
    x *= 0.5**20
    y *= 0.5**20
    b = b.unpack("V*").join(" ")
    out!(%Q[<cai_situated x="#{x}" y="#{y}" a="#{a}" b="#{b}" c="#{c}"/>])
  end
  
  def convert_rec_THEATRE_TRANSITION_INFO
    link, a, b, c = get_rec_contents([:rec, :CAMPAIGN_MAP_TRANSITION_LINK, nil], :bool, :bool, :u4)
    fl, time, dest, via = ensure_types(link, :flt, :u4, :u4, :u4)
    raise SemanticFail.new if fl != 0.0 or b != false or c != 0
    if [a, time, dest, via] == [false, 0, 0xFFFF_FFFF, 0xFFFF_FFFF]
      out!("<theatre_transition/>")
    elsif a == true and time > 0 and dest != 0xFFFF_FFFF and via != 0xFFFF_FFFF
      out!(%Q[<theatre_transition turns="#{time}" destination="#{dest}" via="#{via}"/>])
    else
      raise SemanticFail.new
    end
  end

  def convert_rec_CAI_TECHNOLOGY_TREE
    data, = get_rec_contents(:u4)
    out!("<cai_technology_tree>#{data}</cai_technology_tree>")
  end
  
  def convert_rec_RandSeed
    data, = get_rec_contents(:u4)
    out!("<rand_seed>#{data}</rand_seed>")
  end

  def convert_rec_LAND_UNIT
    unit_type, unit_data, zero = get_rec_contents([:rec, :LAND_RECORD_KEY, nil], [:rec, :UNIT, nil], :u4)
    unit_type, = ensure_types(unit_type, :s)
    raise SemanticError.new unless zero == 0
    
    unit_data = ensure_types(unit_data,
      [:rec, :UNIT_RECORD_KEY, nil],
      [:rec, :UNIT_HISTORY, nil],    
      [:rec, :COMMANDER_DETAILS, nil],
      [:rec, :TRAITS, nil],
      :i4,
      :u4,
      :u4,
      :i4,
      :u4,
      :u4,
      :u4,
      :u4,
      :u4,
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
    data, = get_rec_contents(:u4)
    out!("<garrison_residence>#{data}</garrison_residence>")
  end
  
  def convert_rec_OWNED_INDIRECT
    data, = get_rec_contents(:u4)
    out!("<owned_indirect>#{data}</owned_indirect>")
  end
  
  def convert_rec_OWNED_DIRECT
    data, = get_rec_contents(:u4)
    out!("<owned_direct>#{data}</owned_direct>")
  end
  
  def convert_rec_FACTION_FLAG_AND_COLOURS
    path, r1,g1,b1, r2,g2,b2, r3,g3,b3 = get_rec_contents(:s, :byte,:byte,:byte, :byte,:byte,:byte, :byte,:byte,:byte)
    color1 = "#%02x%02x%02x" % [r1,g1,b1]
    color2 = "#%02x%02x%02x" % [r2,g2,b2]
    color3 = "#%02x%02x%02x" % [r3,g3,b3]
    out!("<flag_and_colours path=\"#{path.xml_escape}\" color1=\"#{color1.xml_escape}\" color2=\"#{color2.xml_escape}\" color3=\"#{color3.xml_escape}\"/>")
  end
  
  def convert_rec_techs
    status_hint = {0 => " (done)", 2 => " (researchable)", 4 => " (not researchable)"}
    data = get_rec_contents(:s, :u4, :flt, :u4, :bin8, :u4)
    name, status, research_points, school_slot_id, unknown1, unknown2 = *data
    status = "#{status}#{status_hint[status]}"
    unknown1 = unknown1.unpack("V*").join(" ")
    out!("<techs name=\"#{name.xml_escape}\" status=\"#{status}\" research_points=\"#{research_points}\" school_slot_id=\"#{school_slot_id}\" unknown1=\"#{unknown1}\" unknown2=\"#{unknown2}\"/>")
  end

  def convert_rec_COMMANDER_DETAILS
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
    ability, level, attribute = get_rec_contents(:s, :i4, :s)
    out!("<agent_ability ability=\"#{ability.xml_escape}\" level=\"#{level}\" attribute=\"#{attribute.xml_escape}\"/>")
  end
  
  def convert_rec_BUILDING
    health, name, faction, gov = get_rec_contents(:u4, :s, :s, :s)
    out!("<building health=\"#{health}\" name=\"#{name.xml_escape}\" faction=\"#{faction.xml_escape}\" government=\"#{gov.xml_escape}\"/>")
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
    name, x, y, unknown, data = get_rec_contents(:s, :u4, :u4, :i4, :bin8)
    raise SemanticFail.new if name =~ /\s/
    path, rel_path = dir_builder.alloc_new_path("map", nil, ".pgm")
    File.write_pgm(path, x*4, y, data)
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
    traits = traits.map{|trait| ensure_types(trait, :s, :i4)}
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

## bmd.dat records

  def convert_rec_HEIGHT_FIELD
    xi, yi, (xf, yf), data, unknown, hmin, hmax = get_rec_contents(:u4, :u4, :v2, :flt_ary, :i4, :flt, :flt)
    path, rel_path = dir_builder.alloc_new_path("height_field", nil, ".pgm")
    File.write_pgm(path, 4*xi, yi, data)
    out!("<height_field xsz=\"#{xf}\" ysz=\"#{yf}\" pgm=\"#{rel_path.xml_escape}\" unknown=\"#{unknown}\" hmin=\"#{hmin}\" hmax=\"#{hmax}\"/>")
  end
  
  def convert_rec_GROUND_TYPE_FIELD
    xi, yi, (xf, yf), data = get_rec_contents(:u4, :u4, :v2, :bin4)
    path, rel_path = dir_builder.alloc_new_path("group_type_field", nil, ".pgm")
    File.write_pgm(path, 4*xi, yi, data)
    out!("<ground_type_field xsz=\"#{xf}\" ysz=\"#{yf}\" pgm=\"#{rel_path.xml_escape}\"/>")
  end
  
  def convert_rec_BMD_TEXTURES
    types, data = get_rec_contents_dynamic
    tag!("bmd_textures") do
      until data.empty?
        if data.size == 3 and types == [:u4, :u4, :bin6]
          xsz, ysz, pxdata = data
          path, rel_path = dir_builder.alloc_new_path("bmd_textures/texture", nil, ".pgm")
          File.write_pgm(path, 4*xsz, ysz, pxdata)
          out!("<bmd_pgm pgm=\"#{rel_path.xml_escape}\"/>")
          break
        end
        t = types.shift
        v = data.shift
        
        case t
        when :s
          out!("<s>#{v.xml_escape}</s>")
        when :i4
          out!("<i>#{v}</i>")
        when :u4
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
        tag!("poi",
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
        ) do
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
                  out_ary!("sea_grid_numbers", "", numbers.empty? ? "" : " " + numbers.join(" "))
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

## autoconfigure everything

  self.instance_methods.each do |m|
    if m.to_s =~ /\Aconvert_ary_(.*)\z/
      ConvertSemanticAry[$1.gsub("__", " ").to_sym] = m
    elsif m.to_s =~ /\Aconvert_rec_(.*)\z/
      ConvertSemanticRec[$1.gsub("__", " ").to_sym] = m
    end
  end
end
