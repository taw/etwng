class EsfConv
  def initialize(stream)
    @stream = stream
  end
end

class EsfConv00 < EsfConv
  def to_ruby
    @stream.i2
  end
  def to_xml
    "<i2>#{to_ruby}</i2>"
  end
end

class EsfConv01 < EsfConv
  def to_ruby
    b = @stream.byte
    stream.error!("Boolean not 00/01") if b > 2
    return [false, true][b]
  end
  def to_xml
    b = @stream.byte
    stream.error!("Boolean not 00/01") if b > 2
    return ["<no/>", "<yes/>"][b]
  end
end

class EsfConv04 < EsfConv
  def to_ruby
    @stream.i4
  end
  def to_xml
    "<i>#{to_ruby}</i>"
  end
end

class EsfConv06 < EsfConv
  def to_ruby
    @stream.byte
  end
  def to_xml
    "<byte>#{to_ruby}</byte>"
  end
end

class EsfConv07 < EsfConv
  def to_ruby
    @stream.u2
  end
  def to_xml
    "<u2>#{to_ruby}</u2>"
  end
end

class EsfConv08 < EsfConv
  def to_ruby
    @stream.u4
  end
  def to_xml
    "<u>#{to_ruby}</u>"
  end
end


class EsfConv0a < EsfConv
  def to_ruby
    @stream.flt
  end
  def to_xml
    "<f>#{to_ruby}</f>"
  end
end

class EsfConv0c < EsfConv
  def to_ruby
    [@stream.flt, @stream.flt]
  end
  def to_xml
    "<v2 x='#{@stream.flt}' y='#{@stream.flt}'/>"
  end
end

class EsfConv0d < EsfConv
  def to_ruby
    [@stream.flt, @stream.flt, @stream.flt]
  end
  def to_xml
    "<v3 x='#{@stream.flt}' y='#{@stream.flt}' z='#{@stream.flt}'/>"
  end
end

class EsfConv0e < EsfConv
  def to_ruby
    @stream.str
  end
  def to_xml
    v = to_ruby.xml_escape
    if v.empty?
      "<s/>"
    else
      "<s>#{v}</s>"
    end
  end
end

class EsfConv0f < EsfConv
  def to_ruby
    @stream.ascii
  end
  def to_xml
    v = to_ruby.xml_escape
    if v.empty?
      "<asc/>"
    else
      "<asc>#{v}</asc>"
    end
  end
end

class EsfConv10 < EsfConv
  def to_ruby
    @stream.u2
  end
  def to_xml
    "<u2x>#{to_ruby}</u2x>"
  end
end
