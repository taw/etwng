require "pathname"

class UiBuilder
  attr_reader :data

  def initialize
    @data = "".b
  end

  def put_u(v)
    @data << [v].pack("V")
  end

  def put_i(v)
    @data << [v].pack("V")
  end

  def put_u2(v)
    @data << [v].pack("v")
  end

  def put_i2(v)
    @data << [v].pack("v")
  end

  def put_flt(v)
    @data << [v].pack("f")
  end

  def put_byte(v)
    @data << [v].pack("C")
  end

  def put_str(v)
    @data << [v.size].pack("v") << v.b
  end

  def put_unicode(v)
    v_utf16 = v.unpack("U*").pack("v*")
    @data << [v_utf16.size/2].pack("v") << v_utf16
  end

  def put_no
    @data << "\x00".b
  end

  def put_yes
    @data << "\x01".b
  end

  def put_version(v)
    vs = "Version%03d" % v
    raise unless vs.size == 10
    @data << vs
  end

  def save!(path)
    Pathname(path).binwrite(@data)
  end
end
