require "test/unit"

# This test verifies that Ruby pack and unpack are compatible with assumptions used
class TestPlatform < Test::Unit::TestCase
  def assert_pack(fmt, data_ruby, data_bin)
    assert_equal data_ruby, data_bin.unpack(fmt), "Unpacking #{fmt.inspect} should work"
    assert_equal data_bin, data_ruby.pack(fmt),   "Packing #{fmt.inspect} should work"
  end
  
  def test_byte
    assert_pack "C", [  0], "\x00"
    assert_pack "C", [  1], "\x01"
    assert_pack "C", [127], "\x7F"
    assert_pack "C", [128], "\x80"
    assert_pack "C", [254], "\xFE"
    assert_pack "C", [255], "\xFF"
  end

  def test_u4
    assert_pack "V", [0x0000_0000], "\x00\x00\x00\x00"
    assert_pack "V", [0x0000_0001], "\x01\x00\x00\x00"
    assert_pack "V", [0x7FFF_FFFF], "\xFF\xFF\xFF\x7F"
    assert_pack "V", [0x8000_0000], "\x00\x00\x00\x80"
    assert_pack "V", [0xFFFF_FFFF], "\xFF\xFF\xFF\xFF"
  end

  def test_f
    assert_pack "f", [  0.0],  "\x00\x00\x00\x00"
    assert_pack "f", [ -0.0],  "\x00\x00\x00\x80"
    assert_pack "f", [  1.0],  "\x00\x00\x80\x3F"
    assert_pack "f", [ -1.0],  "\x00\x00\x80\xbF"
    assert_pack "f", [ 0.25],  "\x00\x00\x80\x3e"
    assert_pack "f", [-0.25],  "\x00\x00\x80\xbe"
    assert_pack "f", [ 42.0],  "\x00\x00\x28\x42"
    assert_pack "f", [-42.0],  "\x00\x00\x28\xc2"
  end

  def test_u2
    assert_pack "v", [0x0000], "\x00\x00"
    assert_pack "v", [0x0001], "\x01\x00"
    assert_pack "v", [0x7FFF], "\xFF\x7F"
    assert_pack "v", [0x8000], "\x00\x80"
    assert_pack "v", [0xFFFF], "\xFF\xFF"
  end
end
