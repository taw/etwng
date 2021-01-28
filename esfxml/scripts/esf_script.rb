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

  BuildingNames = {
    "school" => "school (1)",
    "college" => "school (2)",
    "university" => "school (3)",
    "enlightened_university" => "school (4)",

    "conservatorium" => "culture (1)",
    "opera_house" => "culture (2)",
    "grand_opera_house" => "culture (3; fun)",
    "royal_observatory" => "culture (3; science)",
    "great_museum" => "culture (4; fun)",
    "prest_austria_albertina" => "culture (5; fun; austria)",
    "prest_britain_british_museum" => "culture (5; fun; britain)",
    "prest_ottomans_nur-u_osmaniye_mosque" => "culture (5; fun; ottomans)",
    "prest_poland_lazienki_park" => "culture (5; fun; poland)",
    "prest_russia_kunstkamara" => "culture (5; fun; russia)",
    "prest_sweden_konglig_museum" => "culture (5; fun; sweden)",
    "prest_unitedprovinces_teylers_museum" => "culture (5; fun; netherlands)",
    "prest_usa_smithsonian" => "culture (5; fun; usa)",
    "royal_academy" => "culture (4; science)",
    "prest_prussia_berlin_academy" => "culture (5; science; prussia)",
    "prest_spain_academia" => "culture (5; science; spain)",

    "magistrate" => "government (1)",
    "governors_residence" => "government (2)",
    "governors_mansion" => "government (3)",
    "governors_palace" => "government (4)",
    "royal_palace" => "government (5)",
    "imperial_palace" => "government (6)",
    "prest_austria_hofburg" => "government (7; austria)",
    "prest_britain_somerset_house" => "government (7; britain)",
    "prest_france_palais_bourbon" => "government (7; france)",
    "prest_maratha_shaniwarwada" => "government (7; maratha)",
    "prest_russia_winter_palace" => "government (7; russia)",
    "prest_spain_palacio_real_de_madrid" => "government (7; spain)",
    "prest_sweden_slott" => "government (7; sweden)",
    "prest_usa_independence_hall" => "government (7; usa)",

    "minor_magistrate" => "government minor (1)",
    "minor_governors_residence" => "government minor (2)",
    "minor_governors_encampment" => "government minor (3; military)",
    "minor_governors_barracks" => "government minor (4; military)",
    "minor_governors_mansion" => "government minor (3; civ)",
    "minor_governors_palace" => "government minor (4; civ)",
    "minor_royal_palace" => "government minor (5; civ)",

    "army_encampment" => "army (1)",
    "army_barracks" => "army (2)",
    "drill_school" => "army (3)",
    "military_academy" => "army (4)",
    "army_board" => "army (5)",
    "army_staff_college" => "army (6)",
    "prest_france_arc_de_triomphe" => "army (7; france)",
    "prest_maratha_ajinkyatara" => "army (7; marathas)",
    "prest_poland_akademia" => "army (7; poland)",
    "prest_prussia_brandenburg_gate" => "army (7; prussia)",

    "cannon_foundry" => "artillery (1)",
    "ordnance_factory" => "artillery (2)",
    "great_arsenal" => "artillery (3)",
    "gunnery_school" => "artillery (4)",
    "ordnance_board" => "artillery (5)",
    "engineer_school" => "artillery (6)",

    "admiralty" => "admirality (1)",
    "naval_board" => "admirality (2)",
    "naval_college" => "admirality (3)",
    "prest_ottomans_naval_engineering_school" => "admirality (4; ottoman)",
    "prest_unitedprovinces_kweekschool" => "admirality (4; netherlands)",

    "coaching_inn" => "inn (1)",
    "bawdy_house" => "inn (2)",
    "theatre" => "inn (3)",
    "pleasure_gardens" => "inn (4)",

    "local_fishery" => "fish (1)",
    "fishing_fleet" => "fish (2)",
    "major_fishery" => "fish (3)",

    "fur_merchant" => "plantation fur (1)",
    "fur_market" => "plantation fur (2)",
    "fur_exchange" => "plantation fur (3)",

    "shipyard" => "dock (1)",
    "dockyard" => "dock (2)",
    "drydock" => "dock (3)",

    "open_gem_pit" => "mine gems (1)",
    "deep_gem_shaft" => "mine gems (2)",

    "timber_logging_camp" => "timber (1)",
    "timber_lumber_mill" => "timber (2)",

    "craft_workshops_textiles" => "factory textiles (1)",
    "weavers_cottages" => "factory textiles (2)",
    "water-powered_cloth_mill" => "factory textiles (3)",
    "steam-powered_cloth_mill" => "factory textiles (4)",

    "craft_workshops_metal" => "factory iron (1)",
    "iron_workshops" => "factory iron (2)",
    "ironmasters_works" => "factory iron (3)",
    "steam_engine_factory" => "factory iron (4)",

    "basic_roads" => "road (1)",
    "improved_roads" => "road (2)",
    "tarmac_roads" => "road (3)",

    "trading_port" => "port (1)",
    "commercial_port" => "port (2)",
    "commercial_basin" => "port (3)",
    "trading_company" => "port (4)",

    "corn_peasant_farms" => "farm corn (1)",
    "corn_tenanted_farms" => "farm corn (2)",
    "corn_clearances" => "farm corn (3)",
    "corn_great_estates" => "farm corn (4)",
    "corn_great_royal_palace" => "farm corn (5)",

    "wheat_peasant_farms" => "farm wheat (1)",
    "wheat_tenanted_farms" => "farm wheat (2)",
    "wheat_clearances" => "farm wheat (3)",
    "wheat_great_estates" => "farm wheat (4)",
    "wheat_great_royal_palace" => "farm wheat (5)",

    "sheep_peasant_farms" => "farm sheep (1)",
    "sheep_tenanted_farms" => "farm sheep (2)",
    "sheep_clearances" => "farm sheep (3)",
    "sheep_great_estates" => "farm sheep (4)",
    "sheep_great_royal_palace" => "farm sheep (5)",

    "small_spices_plantation" => "plantation spices (1)",
    "large_spices_plantation" => "plantation spices (2)",
    "spices_warehouse" => "plantation spices (3)",

    "small_tea_plantation" => "plantation tea (1)",
    "large_tea_plantation" => "plantation tea (2)",
    "tea_warehouse" => "plantation tea (3)",

    "small_cotton_plantation" => "plantation cotton (1)",
    "large_cotton_plantation" => "plantation cotton (2)",
    "cotton_warehouse" => "plantation cotton (3)",

    "small_tobacco_plantation" => "plantation tobacco (1)",
    "large_tobacco_plantation" => "plantation tobacco (2)",
    "tobacco_warehouse" => "plantation tobacco (3)",

    "small_coffee_plantation" => "plantation coffee (1)",
    "large_coffee_plantation" => "plantation coffee (2)",
    "coffee_warehouse" => "plantation coffee (3)",

    "small_sugar_plantation" => "plantation sugar (1)",
    "large_sugar_plantation" => "plantation sugar (2)",
    "sugar_warehouse" => "plantation sugar (3)",

    "rel_protestant_0" => "church protestant (1)",
    "rel_protestant_1" => "church protestant (2)",
    "rel_protestant_2" => "church protestant (3)",

    "rel_catholic_0" => "church catholic (1)",
    "rel_catholic_1" => "church catholic (2)",
    "rel_catholic_2" => "church catholic (3)",

    "rel_islam_0" => "church islam (1)",
    "rel_islam_1" => "church islam (2)",
    "rel_islam_2" => "church islam (3)",

    "rel_orthodox_0" => "church orthodox (1)",
    "rel_orthodox_1" => "church orthodox (2)",
    "rel_orthodox_2" => "church orthodox (3)",

    "rel_hindu_0" => "church hindu (1)",
    "rel_hindu_1" => "church hindu (2)",
    "rel_hindu_2" => "church hindu (3)",

    "vineyards" => "wine (1)",
    "wineries" => "wine (2)",
    "wine_estates" => "wine (3)",

    "rice_paddies" => "rice (1)",
    "rice_farms" => "rice (2)",
    "rice_farming_commune" => "rice (3)",

    "settlement_fortifications" => "fort (1)",
    "improved_settlement_fortifications" => "fort (2)",

    "iron_mine" => "mine iron (1)",
    "steam-pumped_iron_mine" => "mine iron (2)",
    "industrial_iron_mining_complex" => "mine iron (3)",

    "gold_mine" => "mine gold (1)",
    "steam-pumped_gold_mine" => "mine gold (2)",
    "industrial_gold_mining_complex" => "mine gold (3)",

    "silver_mine" => "mine silver (1)",
    "steam-pumped_silver_mine" => "mine silver (2)",
    "industrial_silver_mining_complex" => "mine silver (3)",
  }

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
      else
        building = BuildingNames[building] || "#{building}"
        # Give all buildings systematic names
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
