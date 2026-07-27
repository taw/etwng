class String
  def to_utf16
    encode("UTF-16LE").b
  end
  def from_utf16
    dup.force_encoding("UTF-16LE").encode("UTF-8")
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
