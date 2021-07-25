#!/usr/bin/env ruby

require "pathname"
require "pry"

class Float
  def pretty_single
    rv = (((100_000.0 * self).round / 100_000.0) rescue self)
    return rv if [self].pack("f") == [rv].pack("f")
    self
  end
end

class BinFile
  def initialize(input_path)
    @input_path = Pathname(input_path)
    @data = @input_path.open("rb", &:read)
    @ofs = 0
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
    get(4).unpack1("f").pretty_single
  end

  def get_u4
    get(4).unpack1("V")
  end

  def get_u2
    get(2).unpack1("v")
  end

  def get_i4
    get(4).unpack1("i")
  end

  def get_str
    get(get_u2)
  end

  def get_str_table
    get_i4.times.map{ get_str }
  end

  def call
    @version = get_i4
    raise "Version bad" unless @version == 2 or @version == 3

    @str_table_at = get_i4

    @ofs = @str_table_at
    @strs = get_str_table
    raise unless eof?
    @ofs = 8

    @data = @data[0, @str_table_at]

    raise "Expected 1" unless get_i4 == 1
    raise "Expected 0" unless get_i4 == 0
    raise "Expected 1" unless get_i4 == 1

    item_count = get_i4

    # return unless item_count == 1 or item_count == 2

    puts "#{@input_path}:"

    p [:v, @version]
    p [:items, item_count]

    p [:items_contents]

    # p [:array_of_ints_a, get_i4.times.map{ get_i4 }]
    # p [:array_of_ints_b, get_i4.times.map{ get_i4 }]

    while bytes_left >= 4
      i = get_i4
      if i == 0
        p [:zero]
      elsif i >= 0 and i < @strs.size
        p [:int, i, @strs[i]]
      else
        @ofs -= 4
        p [:flt, i, get_flt]
      end
    end

    p [:bytes_left, bytes_left]

    p [:strs, @strs]
    puts ""
  end
end
