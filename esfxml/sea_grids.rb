class SeaGridsEsfParser
  def initialize(types, data)
    @types, @data = types, data
  end
  def get_u4
    raise SemanticFail.new unless @types.shift == :u4
    @data.shift
  end
  def get_s
    raise SemanticFail.new unless @types.shift == :s
    @data.shift
  end
  def get_flt
    raise SemanticFail.new unless @types.shift == :flt
    @data.shift
  end
  def get_v2
    raise SemanticFail.new unless @types.shift == :v2
    @data.shift
  end
  def get_s_ary
    (0...get_u4).map{ get_s }
  end
  def get_u4_ary
    (0...get_u4).map{ get_u4 }
  end
  def get_area
    # area_id, lands, seas, ports, numbers
    [get_u4, get_s_ary, get_s_ary, get_s_ary, get_u4_ary]
  end
  def get_bounding_boxes(xsize, ysize)
    (0...ysize).map{|yi|
      (0...xsize).map{|xi|
        raise SemanticFail.new unless get_u4 == xi
        raise SemanticFail.new unless get_u4 == yi
        [get_v2, get_v2]
      }
    }
  end
  def get_theatre_grid
    grid_name = get_s
    min_xy = get_v2
    max_xy = get_v2
    factor = get_flt
    xsize = get_u4
    ysize = get_u4
    # Bounding boxes
    areas = get_bounding_boxes(xsize, ysize)
    (0...ysize).each{|yi|
      (0...xsize).each{|xi|
        areas[yi][xi] += get_area
      }
    }
    connections = (0...get_u4).map{ [get_u4, get_u4, get_flt] }
    [grid_name, min_xy, max_xy, factor, areas, connections]
  end
  def get_sea_grids
    rv = (0...get_u4).map{ get_theatre_grid }
    raise SemanticFail.new unless @types.empty? and @data.empty?
    rv
  end
end
