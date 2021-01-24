require "rubygems"
require "nokogiri"
require "pp"

class EsfScript
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
    each_xml("factions/*.xml", "//rec[@type='FACTION']") do |faction|
      faction_name = faction.xpath("rec[@type='CAMPAIGN_PLAYER_SETUP']/s")[0].text
      yield(faction, faction_name)
    end
  end

  def each_region
    each_xml('region/*.xml', "//rec[@type='REGION']") do |region|
      yield(region)
    end
  end

  # * stands for arbitrary number of characters
  # everything else is literal
  # entire string much match
  def build_regexp_from_globs(patterns)
    patterns = patterns.map{|pattern| Regexp.escape(pattern).gsub("\\*", ".*")}
    Regexp.compile("\\A(?:" + patterns.join("|") + ")\\z")
  end

  def human_player
    @human_player ||= begin
      result = nil
      each_xml('save_game_header/*.xml', "//rec[@type='SAVE_GAME_HEADER']") do |header|
        raise "Already found one human player" if result
        result = header.xpath("s")[0].text
      end
      result
    end
  end

  def faction_ids
    unless @faction_ids
      @faction_ids = {}
      each_faction do |faction, faction_name|
        id = faction.xpath("i")[0].content
        @faction_ids[id] = faction_name
      end
    end
    @faction_ids
  end
end
