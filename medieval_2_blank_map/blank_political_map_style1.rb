#!/usr/bin/env ruby

module PNM
  def self.parse(path_in)
    File.open(path_in, "rb") { |fh_in|
      p6 = fh_in.readline
      sz = fh_in.readline
      l255 = fh_in.readline
      data_in = fh_in.read

      raise "Format error" unless p6 == "P6\n" and l255 == "255\n" and sz =~ /\A(\d+) (\d+)\n\z/
      xsz, ysz = $1.to_i, $2.to_i
      raise "Bad file size" unless data_in.size == xsz * ysz * 3
      return [xsz, ysz, data_in]
    }
  end
end

class Image
  attr_reader :xsize, :ysize, :data

  def initialize(xsize, ysize, data = nil)
    data ||= "\x00" * (3 * xsize * ysize)
    raise "Data size is wrong" unless xsize * ysize * 3 == data.size
    @xsize, @ysize, @data = xsize, ysize, data
  end

  def self.parse_pnm(path)
    xsize, ysize, data = PNM.parse(path)
    Image.new(xsize, ysize, data)
  end

  def [](x, y)
    @data[(@xsize * y + x) * 3, 3].unpack("CCC")
  end

  def []=(x, y, v)
    @data[(@xsize * y + x) * 3, 3] = v.pack("CCC")
  end

  def each_pixel
    ysize.times do |y|
      xsize.times do |x|
        yield(x, y, self[x, y])
      end
    end
  end

  def blank_political_map
    new_img = Image.new(@xsize - 1, @ysize - 1)

    (ysize - 1).times do |y|
      (xsize - 1).times do |x|
        a = self[x, y]
        b = self[x + 1, y]
        c = self[x, y + 1]
        d = self[x + 1, y + 1]
        colors = [a, b, c, d].uniq
        # ocean, city, port
        water = [[41, 140, 233], [41, 140, 234], [41, 140, 235], [41, 141, 237]]
        colors2 = colors - [[0, 0, 0], [255, 255, 255]] - water
        if !(colors & water).empty?
          new_img[x, y] = [41, 140, 233]
        elsif colors2.size == 1
          new_img[x, y] = [128, 255, 196]
        else
          new_img[x, y] = [0, 0, 0]
        end
      end
    end

    new_img
  end

  def save!(path)
    File.open(path, "wb") do |fh|
      fh.write "P6\n", "#{@xsize} #{@ysize}\n", "255\n", @data
    end
  end
end

unless ARGV.size == 2
  STDERR.puts "Usage: #{$0} file_in.pnm file_out.pnm"
  exit 1
end

path_in = ARGV[0]
path_out = ARGV[1]

img = Image.parse_pnm(path_in)
img.blank_political_map.save!(path_out)
