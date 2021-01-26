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

  def update_each_faction
    update_each_xml("factions/*.xml", "//rec[@type='FACTION']") do |faction|
      faction_name = faction.xpath("rec[@type='CAMPAIGN_PLAYER_SETUP']/s")[0].text
      yield(faction, faction_name)
    end
  end

  def update_faction(faction_to_change)
    update_each_faction do |faction, faction_name|
      next unless faction_to_change == "*" or faction_to_change == faction_name
      yield(faction)
    end
  end

  def each_region
    each_xml('region/*.xml', "//rec[@type='REGION']") do |region|
      yield(region)
    end
  end

  def update_factions_technologies(faction_to_change, &blk)
    update_each_faction do |faction, faction_name|
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

  def region_name_to_id
    unless @region_name_to_id
      @region_name_to_id = {}
      each_region do |region|
        @region_name_to_id[region.xpath("s")[0].content] = region.xpath("i")[0].content
      end
    end
    @region_name_to_id
  end


  def regions_by_faction
    unless @regions_by_faction
      @regions_by_faction = {}
      each_region do |region|
        name = region.xpath("s")[0].content
        faction_name = faction_ids[region.xpath("u")[9].text]
        theater = region.xpath("s")[1].text

        @regions_by_faction[faction_name] ||= []
        @regions_by_faction[faction_name] << name
      end
    end
    @regions_by_faction
  end

  def faction_active?(name)
    !!regions_by_faction[name]
  end

  def each_faction_diplomatic_relation
    each_faction do |faction, faction_name|
      diplomacy_include = faction.xpath("xml_include").map{|xi| xi["path"]}.grep(/\Adiplomacy/)[0]
      next unless diplomacy_include
      path = "#{@xmldir}/#{diplomacy_include}"
      iter_xml(path, "//rec[@type='DIPLOMACY_RELATIONSHIP']") do |dr|
        second_faction_id = dr.xpath("i")[0].content
        second_faction_name = faction_ids[second_faction_id]
        next unless faction_active?(second_faction_name)
        relation = dr.xpath("s")[0].text
        next if relation == "neutral"
        yield(faction_name, second_faction_name, relation)
      end
    end
  end

  def region_ownership
    unless @region_ownership
      @region_ownership = {}
      each_region do |region|
        name = region.xpath("s")[0].content
        faction_name = faction_ids[region.xpath("u")[9].text]
        theater = region.xpath("s")[1].text
        @region_ownership[name] = faction_name
      end
    end
    @region_ownership
  end

  def each_building_slot_xml
    each_file("region_slot/*.xml") do |file_name|
      update_xml(file_name, "/rec") do |node|
        yield(file_name, node)
        false
      end
    end
  end

  def each_building_slot
    each_building_slot_xml do |file_name, node|
      case node["type"]
      when "FORT_ARRAY"
        next
      when "SETTLEMENT"
        next
      when "REGION_SLOT_ARRAY"
        type = "slot"
      when "ROAD_SLOT"
        type = "road"
      when "FORTIFICATION_SLOT"
        type = "fort"
      else
        raise "Unknown node type #{node["type"]}"
      end
      loc = node.xpath("//rec[@type='REGION_SLOT']/s").text.split(":")
      loc.push loc.shift
      resource_yield = Integer(node.xpath("//rec[@type='REGION_SLOT']/i")[2].text)
      wealth = Integer(node.xpath("//rec[@type='REGION_SLOT']/i")[3].text)
      building = node.xpath("//building")[0]
      building = building["name"] if building
      emerged = (node.xpath("//rec[@type='REGION_SLOT']/*")[9].name == "yes")
      emergence_order = Integer(node.xpath("//rec[@type='REGION_SLOT']/u")[2].text)
      owner = region_ownership[loc[0]]
      not_yet = (emergence_order > 0) && (!emerged)
      constructing = !!node.xpath("//rec[@type='BUILDING_CONSTRUCTION_ITEM']")[0]

      raise "Building in town that did not emerge yet" if not_yet and building

      # building mapping is a lot of fun here
      if not_yet
        building = "not yet"
      elsif building == nil
        case type
        when "fort"
          building = "no fort (0)"
        when "road"
          building = "no road (0)"
        when "slot"
          building = "no building (0)"
        else
          raise
        end
      end

      yield({
        loc: loc.join(":"),
        building: building,
        owner: owner,
        constructing: constructing ? true : nil,
        resource_yield: resource_yield > 0 ? resource_yield : nil,
        wealth: wealth > 0 ? wealth : nil,
      }.compact)
    end
  end
end
