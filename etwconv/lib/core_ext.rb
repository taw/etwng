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