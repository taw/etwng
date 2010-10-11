require "test/unit"

require "lib/esf_file"

class TestEsf < Test::Unit::TestCase
  def assert_esf_xml(xml, esf)
    s = BinaryStreamReader.new(esf)
    e = EsfFile.new(s)
    v = e.get_value_as_xml
    assert_equal xml, v
    
    
  end
  
  def test_esf_xml_bidi
    raise 'conversion not yet bidirectional'
  end
  
  def test_esf_bool
    assert_esf_xml "<no/>", "\x01\x00"
    assert_esf_xml "<yes/>",  "\x01\x01"
  end

  def test_esf_byte
    assert_esf_xml "<byte>0</byte>", "\x06\x00"
    assert_esf_xml "<byte>1</byte>",  "\x06\x01"
    assert_esf_xml "<byte>255</byte>",  "\x06\xFF"
  end

  def test_esf_floats
    assert_esf_xml "<f>0.0</f>", "\x0a\x00\x00\x00\x00"
    assert_esf_xml "<f>-0.0</f>", "\x0a\x00\x00\x00\x80"
    assert_esf_xml "<f>0.0</f>", "\x0a\x00\x00\x00\x00"

    assert_esf_xml "<f>1.0</f>",    "\x0a\x00\x00\x80\x3F"
    assert_esf_xml "<f>-1.0</f>",   "\x0a\x00\x00\x80\xbF"
    assert_esf_xml "<f>0.25</f>",   "\x0a\x00\x00\x80\x3e"
    assert_esf_xml "<f>-0.25</f>",  "\x0a\x00\x00\x80\xbe"
    assert_esf_xml "<f>42.0</f>",   "\x0a\x00\x00\x28\x42"
    assert_esf_xml "<f>-42.0</f>",  "\x0a\x00\x00\x28\xc2"    

    # Silly ones need support too
    assert_esf_xml "<f>9.09494701772928e-13</f>",  "\x0a\x00\x00\x80\x2b"
  end

  def test_esf_v2
    # assert_esf_xml "<v2 x='6.28' y='-4.2'/>", "\x0c\xc3\xf5\xc8\x40\x66\x66\x86\xc0"
    assert_esf_xml "<v2 x='6.28000020980835' y='-4.19999980926514'/>", "\x0c\xc3\xf5\xc8\x40\x66\x66\x86\xc0"
  end

  def test_esf_v3
    #assert_esf_xml "<v3 x='6.28' y='-4.2' z='16.25'/>", "\x0d\xc3\xf5\xc8\x40\x66\x66\x86\xc0\x00\x00\x82\x41"
    assert_esf_xml "<v3 x='6.28000020980835' y='-4.19999980926514' z='16.25'/>", "\x0d\xc3\xf5\xc8\x40\x66\x66\x86\xc0\x00\x00\x82\x41"
  end

  # Does anybody know with any kind of certainty which are signed and which are not?
  def test_esf_16bit
    assert_esf_xml "<i2>0</i2>", "\x00\x00\x00"
    assert_esf_xml "<i2>1</i2>", "\x00\x01\x00"
    assert_esf_xml "<i2>32767</i2>", "\x00\xFF\x7F"
    assert_esf_xml "<i2>-32768</i2>", "\x00\00\x80"
    assert_esf_xml "<i2>-1</i2>", "\x00\xFF\xFF"

    assert_esf_xml "<u2>0</u2>", "\x07\x00\x00"
    assert_esf_xml "<u2>1</u2>", "\x07\x01\x00"
    assert_esf_xml "<u2>32767</u2>", "\x07\xFF\x7F"
    assert_esf_xml "<u2>32768</u2>", "\x07\x00\x80"
    assert_esf_xml "<u2>65535</u2>", "\x07\xFF\xFF"

    assert_esf_xml "<u2x>0</u2x>", "\x10\x00\x00"
    assert_esf_xml "<u2x>1</u2x>", "\x10\x01\x00"
    assert_esf_xml "<u2x>32767</u2x>", "\x10\xFF\x7F"
    assert_esf_xml "<u2x>32768</u2x>", "\x10\00\x80"
    assert_esf_xml "<u2x>65535</u2x>", "\x10\xFF\xFF"
  end
  
  def test_esf_32bit
    assert_esf_xml "<i>0</i>",           "\x04\x00\x00\x00\x00"
    assert_esf_xml "<i>1</i>",           "\x04\x01\x00\x00\x00"
    assert_esf_xml "<i>2147483647</i>",  "\x04\xFF\xFF\xFF\x7F"
    assert_esf_xml "<i>-2147483648</i>", "\x04\x00\x00\x00\x80"
    assert_esf_xml "<i>-1</i>",          "\x04\xFF\xFF\xFF\xFF"

    assert_esf_xml "<u>0</u>",           "\x08\x00\x00\x00\x00"
    assert_esf_xml "<u>1</u>",           "\x08\x01\x00\x00\x00"
    assert_esf_xml "<u>2147483647</u>",  "\x08\xFF\xFF\xFF\x7F"
    assert_esf_xml "<u>2147483648</u>",  "\x08\x00\x00\00\x80"
    assert_esf_xml "<u>4294967295</u>",  "\x08\xFF\xFF\xFF\xFF"
  end
end


__END__
      0x0e => EsfType_Str.new(self),
      0x0f => EsfType_Ascii.new(self),

      0x40 => EsfType_Array.new(self, :i2a, 2, "s*"),
#      0x41 => EsfType_BoolArray.new(self),
      0x41 => EsfType_HexArray.new(self, :bin1),
      0x42 => EsfType_HexArray.new(self, :bin2),
      0x42 => EsfType_HexArray.new(self, :bin2ext),
      0x43 => EsfType_HexArray.new(self, :bin3),
      0x44 => EsfType_Array.new(self, :i4a, 4, "l*"),
      0x45 => EsfType_HexArray.new(self, :bin5),
      0x46 => EsfType_HexArray.new(self, :bin6),
      0x47 => EsfType_Array.new(self, :u2a, 2, "v*"),
      0x48 => EsfType_Array.new(self, :u4a, 4, "V*"),
      0x49 => EsfType_HexArray.new(self, :bin9),
      0x4a => EsfType_Array.new(self, :fla, 4, "f*"),
      0x4b => EsfType_HexArray.new(self, :binB),
      0x4c => EsfType_V2A.new(self),
      0x4d => EsfType_V3A.new(self),
      0x4e => EsfType_HexArray.new(self, :binE),
      0x4f => EsfType_HexArray.new(self, :binF),

      0x80 => EsfType_80.new(self),
      0x81 => EsfType_81.new(self),
