FmtNames = Hash.new{|ht,fmt| raise "Unknown format name #{fmt}"}.merge({
  :byte => "C",
  :u2 => "v", :u4 => "V",
  :i2 => "s", :i4 => "i",
  :flt  => "f"
})
FmtBasicSizes = Hash.new{|ht,fmt| raise "Unknown format #{fmt}"}.merge({
  'C' => 1,
  "V" => 4, "v" => 2,
  "s" => 2, "i" => 4,
  "f" => 4,
})
FmtSizes = Hash.new{|ht,fmt|
  ht[fmt] = fmt.chars.map{|fmc| FmtBasicSizes[fmc]}.inject(0, &:+)
}
