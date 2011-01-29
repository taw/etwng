module EsfSemanticConverter
  ConvertSemanticAry = {}
  ConvertSemanticRec = {}

## Utility functions  
  def convert_ary_contents_str(tag)
    data = get_ary_contents(:s).flatten
    raise SemanticFail.new if data.any?{|name| name =~ /\s/}
    out_ary!(tag, "", data.map{|name| " #{name.xml_escape}" })
  end

  def ensure_types(data, *expected_types)
    out = []
    data.each do |t, *v|
      raise SemanticFail.new unless t == expected_types.shift
      out.push *v
    end
    out
  end

  def ensure_loc(data)
    if data == [[:s, ""], [:s, ""]]
      ""
    elsif data.size == 1 and data[0][0] == :s and data[0][1] != ""
      data[0][1]
    else
      raise SemanticFail.new
    end
  end

## Tag converters

## startpos.esf arrays
  def convert_ary_UNIT_CLASS_NAMES_LIST
    data = get_ary_contents_dynamic
    data = data.map{|rec|
      raise SemanticFail.new unless rec.map{|t,*v| t} == [[:rec, :CAMPAIGN_LOCALISATION, nil], :bool]
      loc, used = rec.map{|t,*v| v}
      loc = ensure_loc(loc)
      raise SemanticFail.new if loc =~ /\s|=/
      used = used[0]
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
    raise SemanticFali.new if data.any?{|name, x, y| name =~ /\s|=|,/}
    out!("<region_keys>")
    data.each{|name,x,y| out!(" #{name.xml_escape}=#{x},#{y}") }
    out!("</region_keys>")
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
    out_ary!("sea_indices", "", data.map{|name,value| " #{name.xml_escape}=#{value}" })
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
      "Allied with enemy nation",
      "War declared on friend",
      "Unreliable ally",
      "Territorial expansion",
      "Backstabber! Attacked by forces given safe passage",
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
      out!(" <!-- #{label.xml_escape} -->")
      out!(" <draa drift=\"#{a}\" current=\"#{b}\" max=\"#{c}\" active1=\"#{d}\" extra=\"#{e}\" active2=\"#{f}\"/>")
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
    xmin, ymin, xmax, ymax = get_rec_contents(:v2, :v2)
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
    path, rel_path = dir_builder.alloc_new_path("climate_map", nil, ".pgm")
    File.write_pgm(path, xsz, ysz, data)
    out!("<climate_map pgm=\"#{rel_path}\"/>")
  end

  def convert_rec_wind_map
    xsz, ysz, unknown, data = get_rec_contents(:u4, :u4, :flt, :bin2)
    path, rel_path = dir_builder.alloc_new_path("wind_map", nil, ".pgm")
    File.write_pgm(path, xsz*2, ysz, data)
    out!("<wind_map unknown=\"#{unknown}\" pgm=\"#{rel_path.xml_escape}\"/>")
  end

## startpos.esf records

  def convert_rec_techs
    data = get_rec_contents(:s, :u4, :flt, :u4, :bin8, :u4)
    name, status, research_points, unknown1, unknown2, unknown3 = *data
    unknown2 = unknown2.unpack("V*").join(" ")
    out!("<techs name=\"#{name.xml_escape}\" status=\"#{status}\" research_points=\"#{research_points}\" unknown1=\"#{unknown1}\" unknown2=\"#{unknown2}\" unknown3=\"#{unknown3}\"/>")
  end

  def convert_rec_COMMANDER_DETAILS
    data = get_rec_contents_dynamic
    raise SemanticFail.new unless data.map{|t,*v| t} == [[:rec, :CAMPAIGN_LOCALISATION, nil], [:rec, :CAMPAIGN_LOCALISATION, nil], :s]
    fnam, lnam, faction = data.map{|t,*v| v}
    fnam = ensure_loc(fnam)
    lnam = ensure_loc(lnam)
    faction = faction[0]
    out!("<commander_details name=\"#{fnam.xml_escape}\" surname=\"#{lnam.xml_escape}\" faction=\"#{faction.xml_escape}\"/>")
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
    year, season = get_rec_contents(:u4, :asc)
    raise SemanticFail.new if season =~ /\s/
    if season == "summer" and year == 0
      out!("<date/>")
    else
      out!("<date>#{season.xml_escape} #{year}</date>")
    end
  end

  def convert_rec_MAPS
    name, x, y, unknown, data = get_rec_contents(:s, :u4, :u4, :i4, :bin8)
    raise SemanticFail.new if name =~ /\s/
    path, rel_path = dir_builder.alloc_new_path("map", nil, ".pgm")
    File.write_pgm(path, x*4, y, data)
    out!("<map name=\"#{name.xml_escape}\" unknown=\"#{unknown}\" pgm=\"#{rel_path.xml_escape}\"/>")
  end

  def convert_rec_CAMPAIGN_LOCALISATION
    loc = ensure_loc(get_rec_contents_dynamic)
    if loc.empty?
      out!("<loc/>")
    else
      out!("<loc>#{loc.xml_escape}</loc>")
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
    traits = get_rec_contents([:ary, :TRAIT, nil])
    traits = traits.map{|trait| ensure_types(trait, :s, :i4)}
    raise SemanticFail.new if traits.any?{|trait, level| trait =~ /\s|=/}
    out_ary!("traits", "", traits.map{|trait, level| " #{trait.xml_escape}=#{level}" })
  end

  def convert_rec_ANCILLARY_UNIQUENESS_MONITOR
    entries = get_rec_contents([:ary, :ENTRIES, nil])
    entries = entries.map{|entry| ensure_types(entry, :s)}.flatten
    raise SemanticFail.new if entries.any?{|entry| entry =~ /\s|=/}
    out_ary!("ancillary_uniqueness_monitor", "", entries.map{|entry| " #{entry.xml_escape}" })
  end
  
  def convert_rec_REGION_OWNERSHIPS_BY_THEATRE
    theatre, *ownerships = get_rec_contents(:s, [:ary, :REGION_OWNERSHIPS, nil])
    ownerships = ownerships.map{|o| ensure_types(o, :s, :s)}
    raise SemanticFail.new if ownerships.any?{|region, owner| region =~ /\s|=/ or owner =~ /\s|=/}
    out_ary!("region_ownerships_by_theatre", " theatre=\"#{theatre.xml_escape}\"", ownerships.map{|region, owner| " #{region.xml_escape}=#{owner.xml_escape}" })
  end

## bmd.dat records

  def convert_rec_HEIGHT_FIELD
    xi, yi, xf, yf, data, unknown, hmin, hmax = get_rec_contents(:u4, :u4, :v2, :flt_ary, :i4, :flt, :flt)
    path, rel_path = dir_builder.alloc_new_path("height_field", nil, ".pgm")
    File.write_pgm(path, 4*xi, yi, data)
    out!("<height_field xsz=\"#{xf}\" ysz=\"#{yf}\" pgm=\"#{rel_path.xml_escape}\" unknown=\"#{unknown}\" hmin=\"#{hmin}\" hmax=\"#{hmax}\"/>")
  end
  
  def convert_rec_GROUND_TYPE_FIELD
    xi, yi, xf, yf, data = get_rec_contents(:u4, :u4, :v2, :bin4)
    path, rel_path = dir_builder.alloc_new_path("group_type_field", nil, ".pgm")
    File.write_pgm(path, 4*xi, yi, data)
    out!("<ground_type_field xsz=\"#{xf}\" ysz=\"#{yf}\" pgm=\"#{rel_path.xml_escape}\"/>")
  end
  
  def convert_rec_BMD_TEXTURES
    data = get_rec_contents_dynamic
    tag!("bmd_textures") do
      until data.empty?
        if data.size == 3 and data.map{|t,v| t} == [:u4, :u4, :bin6]
          xsz, ysz, pxdata = data.map{|t,v| v}
          path, rel_path = dir_builder.alloc_new_path("bmd_textures/texture", nil, ".pgm")
          File.write_pgm(path, 4*xsz, ysz, pxdata)
          out!(" <bmd_pgm pgm=\"#{rel_path.xml_escape}\"/>")
          break
        end        
        t, v = data.shift
        case t
        when :s
          out!(" <s>#{v.xml_escape}</s>")
        when :i4
          out!(" <i>#{v}</i>")
        when :u4
          out!(" <u>#{v}</u>")
        when :bool
          if v
            out!(" <yes/>")
          else
            out!(" <no/>")
          end
        when :bin6
          rel_path = dir_builder.save_binfile("bmd_textures/texture", nil, ".jpg", v)
          out!(" <bin6ext path=\"#{rel_path.xml_escape}\"/>")
        else
          # Should be possible to recover from it, isn't just yet
          raise "Total failure while converting BMD_TEXTURES"
        end
      end
    end
  end
  
## autoconfigure everything

  self.instance_methods.each do |m|
    if m.to_s =~ /\Aconvert_ary_(.*)\z/
      ConvertSemanticAry[$1.to_sym] = m
    elsif m.to_s =~ /\Aconvert_rec_(.*)\z/
      ConvertSemanticRec[$1.to_sym] = m
    end
  end
end
