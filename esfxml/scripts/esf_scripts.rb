require "rubygems"
require "nokogiri"
require "pp"

class File
  def self.write(path, content)
    File.open(path, 'wb') do |fh|
      fh.write(content)
    end
  end
end

class EsfScript
  attr_reader :xmldir
  
  def initialize
    self.xmldir, *argv = *ARGV
    usage_error(args) unless argv.size == args.size and check_args(*argv)
    run!(*argv)
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
    each_file(glob) do |file_name|
      update_xml(file_name, xpath, &blk)
    end
  end

  def update_each_file(glob, &blk)
    each_file(glob) do |file_name|
      update_file(file_name, &blk)
    end
  end

  def region_name_to_id
    unless @region_name_to_id
      @region_name_to_id = {}
      each_region do |region|
        @region_name_to_id[region.xpath("s")[0].content] = region.xpath("i")[0].content
        false
      end
    end
    @region_name_to_id
  end

  def each_region
    update_each_xml('region/*.xml', "//rec[@type='REGION']") do |region|
      yield(region)
    end
  end
  
  def each_faction
    update_each_xml("factions/*.xml", "//rec[@type='FACTION']") do |faction|
      faction_name = faction.xpath("rec[@type='CAMPAIGN_PLAYER_SETUP']/s")[0].text
      yield(faction, faction_name)
    end
  end
  
  def update_faction(faction_to_change)
    each_faction do |faction, faction_name|
      next unless faction_to_change == "*" or faction_to_change == faction_name
      yield(faction)
    end
  end

  def update_factions_technologies(faction_to_change, &blk)
    each_faction do |faction, faction_name|
      next unless faction_to_change == "*" or faction_to_change == faction_name
      tech_includes = faction.xpath("xml_include").map{|node| node['path']}.grep(/\Atechnology\//)
      # Rebel faction ("") has no technologies and it's ok
      # Other factions having no technologies are weird
      if tech_includes.empty? and faction_name != ""
        warn "No technology found for faction #{faction_name.inspect}"
        next
      end
      tech_includes.each do |tech_include|
        update_xml(xmldir+"/"+tech_include, "//ary[@type='techs']", &blk)
      end
      false
    end
  end

  def make_faction_playable(faction_to_change)
    update_each_xml("preopen_map_info/info*.xml", "//rec[@type='FACTION_INFOS']") do |fi|
      next unless fi.xpath("s")[0].content == faction_to_change
      fi.xpath("yes|no")[0].name = 'yes'
      fi.xpath("yes|no")[1].name = 'yes'
      true
    end
    update_each_xml("preopen_map_info/info*.xml", "//rec[@type='CAMPAIGN_PLAYER_SETUP']") do |pa|
      next unless pa.xpath("s")[0].content == faction_to_change
      pa.xpath('yes|no')[1].name = 'yes'
      true
    end
    update_each_xml("campaign_env/campaign_setup*.xml", "//rec[@type='CAMPAIGN_PLAYER_SETUP']") do |pa|
      next unless pa.xpath("s")[0].content == faction_to_change
      pa.xpath('yes|no')[1].name = 'yes'
      true
    end
    update_faction(faction_to_change) do |faction|
      cps = faction.xpath("//rec[@type='CAMPAIGN_PLAYER_SETUP']")[0]
      cps.xpath('yes|no')[1].name = 'yes'
      true
    end
  end
  
  # * stands for arbitrary number of characters
  # everything else is literal
  # entire string much match
  def build_regexp_from_globs(patterns)
    patterns = patterns.map{|pattern| Regexp.escape(pattern).gsub("\\*", ".*")}
    Regexp.compile("\\A(?:" + patterns.join("|") + ")\\z")
  end
end
