require "iconv"

class String
  def to_utf16
    Iconv.conv("UTF-16LE", "UTF-8", self)
  end
  def from_utf16
    Iconv.conv("UTF-8", "UTF-16LE", self)
  end
  def xml_escape
    escape_codes = {"&" => "&amp;", "<" => "&lt;", ">" => "&gt;", "'" => "&apos;", '"' => "&quot"}
    gsub(/[&<>'"]/){ escape_codes[$&] }
  end
end

class Float
  def pretty_single
    rv = (((100_000.0 * self).round / 100_000.0) rescue self)
    return rv if [self].pack("f") == [rv].pack("f")
    self
  end
end
