class PoiEsfParser
  def initialize(types, data)
    @types, @data = types, data
  end
  def get(*tags)
    raise SemanticFail.new unless @types.shift(tags.size) == tags
    @data.shift(tags.size)
  end
  def get1(tag)
    raise SemanticFail.new unless @types.shift == tag
    @data.shift
  end
  def get_ary(&blk)
    (0...get1(:u4)).map(&blk)
  end
  def get_v2x
    [get1(:i4) * (0.5**20), get1(:i4) * (0.5**20)]
  end
  def get_poi
    data = get(:u4, :i4, :bool)
    data << get_v2x
    name1 = get(:s, :u4)
    name2 = get(:s, :u4)
    raise SemanticFail.new unless name1 == name2
    data << name1
    data << get1(:flt)
    data << get_ary{ get(:s, :flt) }
    data << get1(:flt)
    data << get_ary{ get(:s, :flt) }
    data << get_ary{ get1(:u4) }
    data += get(:u4, :bool)
    data
  end
  def get_pois
    rv = get_ary{ get_poi }
    rv.each_with_index{|poi, i|
      raise SemanticFali.new unless i == poi.shift
    }
    raise SemanticFail.new unless @types.empty? and @data.empty?
    rv
  end
end
