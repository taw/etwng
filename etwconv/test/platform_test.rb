require "test/unit"

require "lib/platform"

# This test verifies that Ruby pack and unpack are compatible with assumptions used
class TestPlatform < Test::Unit::TestCase
  def assert_pack(fmt, data_ruby, data_bin)
    assert_equal data_ruby, data_bin.unpack(fmt), "Unpacking #{fmt.inspect} should work"
    assert_equal data_bin, data_ruby.pack(fmt),   "Packing #{fmt.inspect} should work"
  end
  
  def test_byte
    fmt = FmtNames[:byte]
    assert_pack fmt, [  0], "\x00"
    assert_pack fmt, [  1], "\x01"
    assert_pack fmt, [127], "\x7F"
    assert_pack fmt, [128], "\x80"
    assert_pack fmt, [254], "\xFE"
    assert_pack fmt, [255], "\xFF"
  end

  def test_u4
    fmt = FmtNames[:u4]
    assert_pack fmt, [0x0000_0000], "\x00\x00\x00\x00"
    assert_pack fmt, [0x0000_0001], "\x01\x00\x00\x00"
    assert_pack fmt, [0x7FFF_FFFF], "\xFF\xFF\xFF\x7F"
    assert_pack fmt, [0x8000_0000], "\x00\x00\x00\x80"
    assert_pack fmt, [0xFFFF_FFFF], "\xFF\xFF\xFF\xFF"
  end

  def test_i4
    fmt = FmtNames[:i4]
    assert_pack fmt, [0x0000_0000], "\x00\x00\x00\x00"
    assert_pack fmt, [0x0000_0001], "\x01\x00\x00\x00"
    assert_pack fmt, [0x7FFF_FFFF], "\xFF\xFF\xFF\x7F"
    assert_pack fmt, [-0x8000_0000], "\x00\x00\x00\x80"
    assert_pack fmt, [-1], "\xFF\xFF\xFF\xFF"
  end

  def test_flt
    fmt = FmtNames[:flt]
    assert_pack fmt, [  0.0],  "\x00\x00\x00\x00"
    assert_pack fmt, [ -0.0],  "\x00\x00\x00\x80"
    assert_pack fmt, [  1.0],  "\x00\x00\x80\x3F"
    assert_pack fmt, [ -1.0],  "\x00\x00\x80\xbF"
    assert_pack fmt, [ 0.25],  "\x00\x00\x80\x3e"
    assert_pack fmt, [-0.25],  "\x00\x00\x80\xbe"
    assert_pack fmt, [ 42.0],  "\x00\x00\x28\x42"
    assert_pack fmt, [-42.0],  "\x00\x00\x28\xc2"
  end

  def test_u2
    fmt = FmtNames[:u2]
    assert_pack fmt, [0x0000], "\x00\x00"
    assert_pack fmt, [0x0001], "\x01\x00"
    assert_pack fmt, [0x7FFF], "\xFF\x7F"
    assert_pack fmt, [0x8000], "\x00\x80"
    assert_pack fmt, [0xFFFF], "\xFF\xFF"
  end
  
  def test_i2
    fmt = FmtNames[:i2]
    assert_pack fmt, [0x0000], "\x00\x00"
    assert_pack fmt, [0x0001], "\x01\x00"
    assert_pack fmt, [0x7FFF], "\xFF\x7F"
    assert_pack fmt, [-0x8000], "\x00\x80"
    assert_pack fmt, [-1], "\xFF\xFF"
  end
  

  def test_basic_sizes
    FmtBasicSizes.each{|fmt,sz|
      data0 = ("\x00" * sz)
      assert_equal data0, data0.unpack(fmt).pack(fmt)
      assert_equal [0], [0].pack(fmt).unpack(fmt), "Cannot possibly really work, can it?"
    }
  end

  def test_sizes 
    assert_equal 8, FmtSizes["VV"]
    assert_equal 4, FmtSizes["CvC"]
    assert_equal 24, FmtSizes["VVVVVV"]
    assert_equal 9, FmtSizes["CCCfs"]
  end
end
