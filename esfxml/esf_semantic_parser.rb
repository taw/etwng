class SemanticFail < Exception
end

module EsfSemantic
  ConvertSemanticAry = {}
  ConvertSemanticRec = {}

## Utility functions

  def get_rec_contents_dynamic
    out     = []
    end_ofs = get_u4
    while @ofs < end_ofs
      out.push send(@esf_type_handlers_get[get_byte])
    end
    out
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
    node_type = get_node_type
    version   = get_byte
    version   = nil if version == DefaultVersions[node_type]
    ofs_end   = get_u4
    count     = get_u4
    [[:ary, node_type, version], *(0...count).map{ get_rec_contents_dynamic }]
  end

  def get_80!
    node_type = get_node_type
    version   = get_byte
    version   = nil if version == DefaultVersions[node_type]
    [[:rec, node_type, version], *get_rec_contents_dynamic]
  end

  def get_ary_contents(*expect_types)
    data = []
    ofs_end   = get_u4
    count     = get_u4
    data.push get_rec_contents(*expect_types) while @ofs < ofs_end
    data
  end
  
  def convert_ary_contents_str(tag)
    data = get_ary_contents(:s).flatten
    raise SemanticFail.new if data.any?{|name| name =~ /\s/}
    @xmlout.out_ary!(tag, "", data.map{|name| " #{name.xml_escape}" })
  end

## Tag converters

## startpos.esf arrays

  def convert_ary_REGION_OWNERSHIP
    data = get_ary_contents(:s, :s)
    raise SemanticFali.new if data.any?{|region, owner| region =~ /\s|=/ or owner =~ /\s|=/}
    @xmlout.out!("region_ownership", "", data.map{|region,owner| " #{region.xml_escape}=#{owner.xml_escape}" })
  end

  def convert_ary_RELIGION_BREAKDOWN
    data = get_ary_contents(:s, :flt)
    raise SemanticFali.new if data.any?{|name, value| name =~ /\s|=/}
    @xmlout.out_ary!("religion_breakdown", "", data.map{|name,value| " #{name.xml_escape}=#{value.pretty_single}" })
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
    @xmlout.out_ary!("port_indices", "", data.map{|name,value| " #{name.xml_escape}=#{value}" })
  end

  def convert_ary_SETTLEMENT_INDICES
    data = get_ary_contents(:s, :u4)
    raise SemanticFali.new if data.any?{|name, value| name =~ /\s|=/}
    @xmlout.out_ary!("settlement_indices", "", data.map{|name,value| " #{name.xml_escape}=#{value}" })
  end
  
  def convert_ary_AgentAttributes
    data = get_ary_contents(:s, :i4)
    @xmlout.out_ary!("agent_attributes", "", data.map{|attribute,level| " #{attribute.xml_escape}=#{level}" })
  end
  
  def convert_ary_AgentAttributeBonuses
    data = get_ary_contents(:s, :u4)
    @xmlout.out_ary!("agent_attribute_bonuses", "", data.map{|attribute,level| " #{attribute.xml_escape}=#{level}" })
  end
  
## regions.esf arrays

  def convert_ary_region_keys
    data = get_ary_contents(:s, :v2)
    raise SemanticFali.new if data.any?{|name, x, y| name =~ /\s|=|,/}
    @xmlout.out!("<region_keys>")
    data.each{|name,x,y| @xmlout.out!(" #{name.xml_escape}=#{x.pretty_single},#{y.pretty_single}") }
    @xmlout.out!("</region_keys>")
  end

  def convert_ary_groundtype_index
    convert_ary_contents_str("groundtype_index")
  end

  def convert_land_indices_ary
    data = get_ary_contents(:s, :byte)
    raise SemanticFali.new if data.any?{|name, value| name =~ /\s|=/}
    @xmlout.out_ary!("land_indices", "", data.map{|name,value| " #{name.xml_escape}=#{value}" })
  end

  def convert_sea_indices_ary
    data = get_ary_contents(:s, :byte)
    raise SemanticFali.new if data.any?{|name, value| name =~ /\s|=/}
    @xmlout.out_ary!("sea_indices", "", data.map{|name,value| " #{name.xml_escape}=#{value}" })
  end
  
## traderoutes.esf arrays

  def convert_ary_SETTLEMENTS
    convert_ary_contents_str("settlements")
  end

## regions.esf records

  def convert_rec_BOUNDS_BLOCK
    xmin, ymin, xmax, ymax = get_rec_contents(:v2, :v2)
    @xmlout.out!("<bounds_block xmin='#{xmin.pretty_single}' ymin='#{ymin.pretty_single}' xmax='#{xmax.pretty_single}' ymax='#{ymax.pretty_single}'/>")
  end

  def convert_rec_black_shroud_outlines
    name, data = get_rec_contents(:s, :v2_ary)
    data = data.unpack("f*").map(&:pretty_single)
    @xmlout.out!("<black_shroud_outlines name='#{name.xml_escape}'>")
    @xmlout.out!(" #{data.shift},#{data.shift}") until data.empty?
    @xmlout.out!("</black_shroud_outlines>")
  end

  def convert_rec_connectivity
    mask, cfrom, cto = get_rec_contents(:u4, :u4, :u4)
    @xmlout.out!("<connectivity mask='#{"%08x" % mask}' from='#{cfrom}' to='#{cto}'/>")
  end

  def convert_rec_climate_map
    xsz, ysz, data = get_rec_contents(:u4, :u4, :bin6)
    path, rel_path = alloc_new_path("climate_map", nil, ".pgm")
    File.write_pgm(path, xsz, ysz, data)
    @xmlout.out!("<climate_map pgm='#{rel_path}'/>")
  end

  def convert_rec_wind_map
    xsz, ysz, unknown, data = get_rec_contents(:u4, :u4, :flt, :bin2)
    path, rel_path = alloc_new_path("wind_map", nil, ".pgm")
    File.write_pgm(path, xsz*2, ysz, data)
    @xmlout.out!("<wind_map unknown='#{unknown.pretty_single}' pgm='#{rel_path.xml_escape}'/>")
  end

## startpos.esf records

  def convert_rec_AgentAbilities
    ability, level, attribute = get_rec_contents(:s, :i4, :s)
    @xmlout.out!("<agent_ability ability='#{ability.xml_escape}' level='#{level}' attribute='#{attribute.xml_escape}'/>")
  end

  def convert_rec_DATE
    year, season = get_rec_contents(:u4, :asc)
    raise SemanticFail.new if season =~ /\s/
    if season == "summer" and year == 0
      @xmlout.out!("<date/>")
    else
      @xmlout.out!("<date>#{season.xml_escape} #{year}</date>")
    end
  end

  def convert_rec_MAPS
    name, x, y, unknown, data = get_rec_contents(:s, :u4, :u4, :i4, :bin8)
    raise SemanticFail.new if name =~ /\s/
    path, rel_path = alloc_new_path("map", nil, ".pgm")
    File.write_pgm(path, x*4, y, data)
    @xmlout.out!("<map name='#{name.xml_escape}' unknown='#{unknown}' pgm='#{rel_path.xml_escape}'/>")
  end

  def convert_rec_CAMPAIGN_LOCALISATION
    data = get_rec_contents_dynamic
    if data == [[:s, ""], [:s, ""]]
      @xmlout.out!("<loc/>")
    elsif data.size == 1 and data[0][0] == :s and data[0][1] != ""
      @xmlout.out!("<loc>#{data[0][1].xml_escape}</loc>")
    else
      raise SemanticFail.new
    end
  end

  def convert_rec_LAND_RECORD_KEY
    key, = get_rec_contents(:s)
    @xmlout.out!("<land_key>#{key.xml_escape}</land_key>")
  end

  def convert_rec_UNIT_RECORD_KEY
    key, = get_rec_contents(:s)
    @xmlout.out!("<unit_key>#{key.xml_escape}</unit_key>")
  end

  def convert_rec_NAVAL_RECORD_KEY
    key, = get_rec_contents(:s)
    @xmlout.out!("<naval_key>#{key.xml_escape}</naval_key>")
  end

  def convert_rec_TRAITS
    traits = get_rec_contents([:ary, :TRAIT, nil])
    traits = traits.map do |trait|
      raise SemanticFail.new unless trait.map{|t,v| t} == [:s, :i4]
      trait.map{|t,v| v}
    end
    raise SemanticFail.new if traits.any?{|trait, level| trait =~ /\s|=/}
    @xmlout.out_ary!("traits", "", traits.map{|trait, level| " #{trait.xml_escape}=#{level}" })
  end

## bmd.dat records

  def convert_rec_HEIGHT_FIELD
    xi, yi, xf, yf, data, unknown, hmin, hmax = get_rec_contents(:u4, :u4, :v2, :flt_ary, :i4, :flt, :flt)
    path, rel_path = alloc_new_path("height_field", nil, ".pgm")
    File.write_pgm(path, 4*xi, yi, data)
    @xmlout.out!("<height_field xsz='#{xf.pretty_single}' ysz='#{yf.pretty_single}' pgm='#{rel_path.xml_escape}' unknown='#{unknown}' hmin='#{hmin.pretty_single}' hmax='#{hmax.pretty_single}'/>")
  end
  
  def convert_rec_GROUND_TYPE_FIELD
    xi, yi, xf, yf, data = get_rec_contents(:u4, :u4, :v2, :bin4)
    path, rel_path = alloc_new_path("group_type_field", nil, ".pgm")
    File.write_pgm(path, 4*xi, yi, data)
    @xmlout.out!("<ground_type_field xsz='#{xf.pretty_single}' ysz='#{yf.pretty_single}' pgm='#{rel_path.xml_escape}'/>")
  end
  
  def convert_rec_BMD_TEXTURES
    data = get_rec_contents_dynamic
    @xmlout.tag!("bmd_textures") do
      until data.empty?
        if data.size == 3 and data.map{|t,v| t} == [:u4, :u4, :bin6]
          xsz, ysz, pxdata = data.map{|t,v| v}
          path, rel_path = alloc_new_path("bmd_textures/texture", nil, ".pgm")
          File.write_pgm(path, 4*xsz, ysz, pxdata)
          @xmlout.out!(" <bmd_pgm pgm='#{rel_path.xml_escape}'/>")
          break
        end        
        t, v = data.shift
        case t
        when :s
          @xmlout.out!(" <s>#{v.xml_escape}</s>")
        when :i4
          @xmlout.out!(" <i>#{v}</i>")
        when :u4
          @xmlout.out!(" <u>#{v}</u>")
        when :bool
          if v
            @xmlout.out!(" <yes/>")
          else
            @xmlout.out!(" <no/>")
          end
        when :bin6
          rel_path = save_binfile("bmd_textures/texture", nil, ".jpg", v)
          @xmlout.out!(" <bin6ext path='#{rel_path.xml_escape}'/>")
        else
          # Should be possible to recover from it, isn't just yet
          raise "Total failure while converting BMD_TEXTURES"
        end
      end
    end
  end
  
## autoconfigure everything

  self.instance_methods.each{|m|
    if m.to_s =~ /\Aconvert_ary_(.*)\z/
      ConvertSemanticAry[$1.to_sym] = m
    elsif m.to_s =~ /\Aconvert_rec_(.*)\z/
      ConvertSemanticRec[$1.to_sym] = m
    end
  }
end
