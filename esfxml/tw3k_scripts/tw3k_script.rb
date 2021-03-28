require "rubygems"
require "nokogiri"
require "pp"
require "set"

class Tw3kScript
  attr_reader :xmldir

  def initialize
    self.xmldir, *argv = *ARGV
    usage_error(args) unless argv.size == args.size and check_args(*argv)
    call(*argv)
  end

  def usage_error(args_spec)
    STDERR.puts "Usage: #{$0} extracted_esf_directory #{args_spec}"
    exit 1
  end

  def xmldir=(xmldir)
    usage_error(args) if xmldir.nil?
    raise "#{xmldir} doesn't exist" unless File.directory?(xmldir)
    raise "#{xmldir} doesn't look like unpacked esf file" unless File.exist?(xmldir + "/esf.xml")
    @xmldir = xmldir
  end

  def args
    []
  end

  def check_args(*argv)
    true
  end

  def each_file(glob, &blk)
    Dir[xmldir + "/" + glob].sort.select{|file_name| File.file?(file_name)}.each(&blk)
  end

  def update_file(file_name)
    content = File.open(file_name, 'rb', &:read)
    new_content = yield(content)
    if content != new_content
      File.write(file_name, new_content)
    end
  end

  def create_new_file(file_name, doc)
    warn "File already exists: #{file_name}" if File.exist?(file_name)
    File.write(file_name, doc.to_s)
  end

  def update_xml(file_name, xpath)
#    STDERR.puts(file_name)
    content = File.open(file_name, 'rb', &:read)
    doc = Nokogiri::XML.parse(content)
    changed = false
    doc.xpath(xpath).each do |elem|
      changed = true if yield(elem)
    end
    File.write(file_name, doc.to_s) if changed
  end

  def update_each_xml(glob, xpath, &blk)
    each_file(glob) do |path|
      update_xml(path, xpath, &blk)
    end
  end

  def iter_xml(path, xpath)
    content = File.open(path, 'rb', &:read)
    doc = Nokogiri::XML.parse(content)
    doc.xpath(xpath).each do |elem|
      yield(elem)
    end
  end

  def each_xml(glob, xpath, &blk)
    each_file(glob) do |file_name|
      iter_xml(file_name, xpath, &blk)
    end
  end

  def update_each_file(glob, &blk)
    each_file(glob) do |file_name|
      update_file(file_name, &blk)
    end
  end

  def each_faction
    each_xml("compressed_data/factions/3k*.xml", "//rec[@type='FACTION']") do |faction|
      faction_name = faction.xpath("rec[@type='CAMPAIGN_PLAYER_SETUP']/asc")[0].text
      yield(faction, faction_name)
    end
  end

  def update_each_faction
    update_each_xml("compressed_data/factions/3k*.xml", "//rec[@type='FACTION']") do |faction|
      faction_name = faction.xpath("rec[@type='CAMPAIGN_PLAYER_SETUP']/asc")[0].text
      yield(faction, faction_name)
    end
  end

  def update_faction(faction_to_change)
    update_each_faction do |faction, faction_name|
      next unless faction_to_change == "*" or faction_to_change == faction_name
      yield(faction)
    end
  end

  def each_army
    each_xml("compressed_data/army/*.xml", "//rec[@type='ARMY_ARRAY']") do |army|
      army_faction = army.xpath("//rec[@type='UNIT_COMMANDER_DETAILS']/asc")[0].text
      yield(army, army_faction)
    end
  end

  def update_each_army
    update_each_xml("compressed_data/army/*.xml", "//rec[@type='ARMY_ARRAY']") do |army|
      army_faction = army.xpath("//rec[@type='UNIT_COMMANDER_DETAILS']/asc")[0].text
      yield(army, army_faction)
    end
  end

  def update_armies(faction_to_change)
    update_each_army do |army, army_faction|
      next unless faction_to_change == "*" or faction_to_change == army_faction
      yield(army)
    end
  end

end
