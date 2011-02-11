class SeaGridsEsfParser
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
  def get_s_ary
    get_ary{ get1(:s) }
  end
  def get_u4_ary
    get_ary{ get1(:u4) }
  end
  def get_area
    # area_id, lands, seas, ports, numbers
    [get1(:u4), get_s_ary, get_s_ary, get_s_ary, get_u4_ary]
  end
  def get_bounding_boxes(xsize, ysize)
    (0...ysize).map{|yi|
      (0...xsize).map{|xi|
        raise SemanticFail.new unless get(:u4, :u4) == [xi, yi]
        get(:v2, :v2)
      }
    }
  end
  def get_theatre_grid
    grid_name, min_xy, max_xy, factor, xsize, ysize = get(:s, :v2, :v2, :flt, :u4, :u4)
    # Bounding boxes
    areas = get_bounding_boxes(xsize, ysize)
    (0...ysize).each{|yi|
      (0...xsize).each{|xi|
        areas[yi][xi] += get_area
      }
    }
    connections = get_ary{ get(:u4, :u4, :flt) }
    [grid_name, min_xy, max_xy, factor, areas, connections]
  end
  def get_sea_grids
    rv = get_ary{ get_theatre_grid }
    raise SemanticFail.new unless @types.empty? and @data.empty?
    rv
  end
end
