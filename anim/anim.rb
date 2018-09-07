# Common functions for the format

require "json"

class Float
  def pretty_single
    rv = (((100_000.0 * self).round / 100_000.0) rescue self)
    return rv if [self].pack("f") == [rv].pack("f")
    self
  end
end

class BaseJson2Anim
  def initialize(input_path, output_path)
    @input_path = Pathname(input_path)
    @data = JSON.parse(@input_path.open("rb", &:read))
    @output_path = Pathname(output_path)
  end

  def call
    @output = "".b
    put_anim
    @output_path.open("wb") do |fh|
      fh.write @output
    end
  end

  def put(v)
    @output << v
  end

  def put_flt(v)
    put [v].pack("f")
  end

  def put_i4(v)
    put [v].pack("V")
  end

  def put_u4(v)
    put [v].pack("V")
  end

  def put_u2(v)
    put [v].pack("v")
  end

  def put_i2(v)
    put [v].pack("v")
  end

  def put_str(v)
    v = v.unpack("U*").pack("v*")
    put_u2 v.size/2
    put v
  end
end

class BaseAnim2Json
  def initialize(input_path, output_path)
    @input_path = Pathname(input_path)
    @data = @input_path.open("rb", &:read)
    @ofs = 0
    @output_path = Pathname(output_path)
  end

  def get(sz)
    raise "Format Error, trying to read past end of file" if @ofs+sz > @data.size
    rv = @data[@ofs, sz]
    @ofs += sz
    rv
  end

  def eof?
    @data.size == @ofs
  end

  def bytes_left
    @data.size - @ofs
  end

  def get_flt
    get(4).unpack("f")[0].pretty_single
  end

  def get_u4
    get(4).unpack("V")[0]
  end

  def get_i4
    get(4).unpack("i")[0]
  end

  def get_i2
    get(2).unpack("s")[0]
  end

  def get_u2
    get(2).unpack("v")[0]
  end

  def get_ascii
    get(get_u2)
  end

  def get_str
    get(2*get_u2).unpack("v*").pack("U*")
  end

  # Does not deal with denormals, NaNs etc.
  def self.half_prec
    unless @half_prec
      @half_prec = {}
      (0..0xFFFF).each do |i|
        ip = [i].pack("v")
        sign     = ((i & 0x8000) == 1) ? -1.0 : 1.0
        if i & 0x7FFF == 0
          @half_prec[ip] = 0.0 * sign
        else
          exponent = 2.0 ** (((i >> 10) & 0x1F) - 15)
          mantissa = 1.0 + (i & 0x3FF) / 0x400.to_f
          @half_prec[ip] = sign * exponent * mantissa
        end
      end
    end
    @half_prec
  end

  def get_half
    Anim.half_prec[get(2)]
  end

  def get_fix2
    (get_i2/0x7FFF.to_f)
  end
end
