class SemanticFail < Exception
  attr_reader :save_ofs
  def initialize(save_ofs)
    @save_ofs = save_ofs
    super()
  end
end

module EsfSemantic
  ConvertSemanticAry = {
    # startpos.esf
    :RESOURCES_ARRAY       => :convert_resources_ary,
    :RELIGION_BREAKDOWN    => :convert_religion_breakdown_ary,
    :REGION_KEYS           => :convert_REGION_KEYS_ary,
    :COMMODITIES_ORDER     => :convert_commodities_order_ary,
    :RESOURCES_ORDER       => :convert_resources_order_ary,
    :PORT_INDICES          => :convert_port_indices_ary,
    :SETTLEMENT_INDICES    => :convert_settlement_indices_ary,
    :REGION_OWNERSHIPS     => :convert_region_ownership_ary,

    # regions.esf
    :groundtype_index      => :convert_groundtype_index_ary,
    :land_indices          => :convert_land_indices_ary,
    :sea_indices           => :convert_sea_indices_ary,
    :region_keys           => :convert_region_keys_ary,
  }
  ConvertSemanticRec = {
    # startpos.esf
    :DATE                  => :convert_date,
    :AgentAbilities        => :convert_agent_abilities,
    :AgentAttributes       => :convert_agent_attributes,

    # regions.esf
    :connectivity          => :convert_connectivity,
    :BOUNDS_BLOCK          => :convert_bounds_block,
    :climate_map           => :convert_climate_map,
    :wind_map              => :convert_wind_map,
    :black_shroud_outlines => :convert_black_shroud_outlines,
  }

## Utility functions

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

  def get_ary_contents(*expect_types)
    data = []
    ofs_end   = get_u4
    count     = get_u4
    while @ofs < ofs_end
      data.push get_rec_contents(*expect_types)
    end
    data
  end
  def convert_ary_contents_str(tag)
    data = get_ary_contents(:s).flatten
    raise SemanticFail.new if data.any?{|name| name =~ /\s/}
    @xmlout.out!("<#{tag}>")
    data.each{|name| @xmlout.out!(" #{name.xml_escape}") }
    @xmlout.out!("</#{tag}>")
  end

## Tag converters

  def convert_region_ownership_ary
    data = get_ary_contents(:s, :s)
    raise SemanticFali.new if data.any?{|region, owner| region =~ /\s|=/ or owner =~ /\s|=/}
    @xmlout.out!("<region_ownership>")
    data.each{|region,owner| @xmlout.out!(" #{region.xml_escape}=#{owner.xml_escape}") }
    @xmlout.out!("</region_ownership>")
  end
    
  def convert_religion_breakdown_ary
    data = get_ary_contents(:s, :flt)
    raise SemanticFali.new if data.any?{|name, value| name =~ /\s|=/}
    @xmlout.out!("<religion_breakdown>")
    data.each{|name,value| @xmlout.out!(" #{name.xml_escape}=#{value.pretty_single}") }
    @xmlout.out!("</religion_breakdown>")
  end

  def convert_port_indices_ary
    data = get_ary_contents(:s, :u4)
    raise SemanticFali.new if data.any?{|name, value| name =~ /\s|=/}
    @xmlout.out!("<port_indices>")
    data.each{|name,value| @xmlout.out!(" #{name.xml_escape}=#{value}") }
    @xmlout.out!("</port_indices>")
  end

  def convert_settlement_indices_ary
    data = get_ary_contents(:s, :u4)
    raise SemanticFali.new if data.any?{|name, value| name =~ /\s|=/}
    @xmlout.out!("<settlement_indices>")
    data.each{|name,value| @xmlout.out!(" #{name.xml_escape}=#{value}") }
    @xmlout.out!("</settlement_indices>")
  end

  def convert_groundtype_index_ary
    convert_ary_contents_str("groundtype_index")
  end
  def convert_resources_ary
    convert_ary_contents_str("resources_array")
  end
  def convert_REGION_KEYS_ary
    convert_ary_contents_str("REGION_KEYS")
  end
  def convert_commodities_order_ary
    convert_ary_contents_str("commodities_order")
  end
  def convert_resources_order_ary
    convert_ary_contents_str("resources_order")
  end

  def convert_land_indices_ary
    data = get_ary_contents(:s, :byte)
    raise SemanticFali.new if data.any?{|name, value| name =~ /\s|=/}
    @xmlout.out!("<land_indices>")
    data.each{|name,value| @xmlout.out!(" #{name.xml_escape}=#{value}") }
    @xmlout.out!("</land_indices>")
  end

  def convert_sea_indices_ary
    data = get_ary_contents(:s, :byte)
    raise SemanticFali.new if data.any?{|name, value| name =~ /\s|=/}
    @xmlout.out!("<sea_indices>")
    data.each{|name,value| @xmlout.out!(" #{name.xml_escape}=#{value}") }
    @xmlout.out!("</sea_indices>")
  end

  def convert_region_keys_ary
    data = get_ary_contents(:s, :v2)
    raise SemanticFali.new if data.any?{|name, x, y| name =~ /\s|=|,/}
    @xmlout.out!("<region_keys>")
    data.each{|name,x,y| @xmlout.out!(" #{name.xml_escape}=#{x.pretty_single},#{y.pretty_single}") }
    @xmlout.out!("</region_keys>")
  end

  def convert_bounds_block
    xmin, ymin, xmax, ymax = get_rec_contents(:v2, :v2)
    @xmlout.out!("<bounds_block xmin='#{xmin.pretty_single}' ymin='#{ymin.pretty_single}' xmax='#{xmax.pretty_single}' ymax='#{ymax.pretty_single}'/>")
  end

  def convert_black_shroud_outlines
    name, data = get_rec_contents(:s, :v2_ary)
    @xmlout.out!("<black_shroud_outlines name='#{name.xml_escape}'>")
    @xmlout.out!(" #{data.shift},#{data.shift}") until data.empty?
    @xmlout.out!("</black_shroud_outlines>")
  end

  def convert_connectivity
    mask, cfrom, cto = get_rec_contents(:u4, :u4, :u4)
    @xmlout.out!("<connectivity mask='#{"%08x" % mask}' from='#{cfrom}' to='#{cto}'/>")
  end

  def convert_climate_map
    xsz, ysz, data = get_rec_contents(:u4, :u4, :bin6)
    path, rel_path = alloc_new_path("climate_map", nil, ".pgm")
    File.write_pgm(path, xsz, ysz, data)
    @xmlout.out!("<climate_map pgm='#{rel_path}'/>")
  end

  def convert_wind_map
    xsz, ysz, unknown, data = get_rec_contents(:u4, :u4, :flt, :bin2)
    path, rel_path = alloc_new_path("wind_map", nil, ".bin")
    File.write(path, data)
    @xmlout.out!("<wind_map xsz='#{xsz}' ysz='#{ysz}' unknown='#{unknown.pretty_single}' data='#{rel_path}'/>")
  end

  def convert_agent_attributes
    attribute, level = get_rec_contents(:s, :i4)
    @xmlout.out!("<agent_attribute attribute='#{attribute.xml_escape}' level='#{level}'/>")
  end

  def convert_agent_abilities
    ability, level, attribute = get_rec_contents(:s, :i4, :s)
    @xmlout.out!("<agent_ability ability='#{ability.xml_escape}' level='#{level}' attribute='#{attribute.xml_escape}'/>")
  end

  def convert_date
    year, season = get_rec_contents(:u4, :asc)
    raise SemanticFail.new if season =~ /\s/
    @xmlout.out!("<date>#{season.xml_escape} #{year}</date>")
  end
end
