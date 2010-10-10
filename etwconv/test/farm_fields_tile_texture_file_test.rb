require "test/unit"

require "lib/farm_fields_tile_texture_file"

class TestFarmFieldsTileTextureFile < Test::Unit::TestCase
  def assert_fftt(data_ruby, data_bin)
    ffttc = FarmFieldsTileTextureConverter.new
    assert_equal data_ruby, ffttc.unpack(data_bin)
    assert_equal data_bin, ffttc.pack(data_ruby)
  end
  
  # Note: Nobody observed empty one in practice, but it sounds sensible
  def test_empty
    assert_fftt [], [0,8].pack("VV")
  end

  def test_one_pair
    xs = "x"*217
    ys = "y"*109
    assert_fftt [[xs,ys]],
      [1, 12, 12+8+217+109].pack("VVV") +
      [217, 109].pack("VV") + xs + ys
  end

  def test_two_pairs
    xs = "x"*217
    ys = "y"*109
    as = "a"*1029
    bs = "b"*220
    
    sz1 = 8+217+109
    sz2 = 8+1029+220
    
    assert_fftt [[xs,ys],[as,bs]],
       [2, 16, 16+sz1, 16+sz1+sz2].pack("VVVV") +
       [217, 109].pack("VV") + xs + ys +
       [1029, 220].pack("VV") + as + bs
  end

  def test_empty_files
    data = [["x"*217, "y"*109],
            ["a" * 0, "b"*0],
            ["c"*14, "d"*0],
            ["e"*199, "f"*8504]]
    sz = [8+217+109, 8, 8+14, 8+199+8504]
    assert_fftt data,
       [4, 24, 24+sz[0], 24+sz[0]+sz[1], 24+sz[0]+sz[1]+sz[2], 24+sz[0]+sz[1]+sz[2]+sz[3]].pack("VVVVVV") +
       [217, 109].pack("VV") + data[0].join +
       [0, 0].pack("VV") + data[1].join +
       [14, 0].pack("VV") + data[2].join +
       [199, 8504].pack("VV") + data[3].join
  end
end
