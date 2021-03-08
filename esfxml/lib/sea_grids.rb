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
    (0...get1(:u)).map(&blk)
  end
  def get_s_ary
    get_ary{ get1(:s) }
  end
  def get_u4_ary
    get_ary{ get1(:u) }
  end
  def get_area
    # area_id, lands, seas, ports, numbers
    [get1(:u), get_s_ary, get_s_ary, get_s_ary, get_u4_ary]
  end
  def get_bounding_boxes(xsize, ysize)
    (0...ysize).map{|yi|
      (0...xsize).map{|xi|
        raise SemanticFail.new unless get(:u, :u) == [xi, yi]
        get(:v2, :v2)
      }
    }
  end
  def get_theatre_grid
    grid_name, min_xy, max_xy, factor, xsize, ysize = get(:s, :v2, :v2, :flt, :u, :u)
    # Bounding boxes
    areas = get_bounding_boxes(xsize, ysize)
    (0...ysize).each{|yi|
      (0...xsize).each{|xi|
        areas[yi][xi] += get_area
      }
    }
    connections = get_ary{ get(:u, :u, :flt) }
    [grid_name, min_xy, max_xy, factor, areas, connections]
  end
  def get_sea_grids
    rv = get_ary{ get_theatre_grid }
    raise SemanticFail.new unless @types.empty? and @data.empty?
    rv
  end
end
