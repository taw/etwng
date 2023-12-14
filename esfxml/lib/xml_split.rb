# Read XML_SPLIT.txt for explanation
XmlSplit = {
  :ARMY_ARRAY                    => "army/%s-%d",
  :BATTLE_MAP_DEFINITION         => "battle_map_definition",
  :CAI_BDI_POOL                  => "bdi_pool/",
  :CAI_HISTORY                   => "cai_interface/cai_history",
  :CAI_INTERFACE                 => "cai_interface/cai",
  :CAI_INTERFACE_MANAGERS        => "cai_interface_managers/",
  :CAI_WORLD                     => "cai_interface/cai_world",
  :CAI_WORLD_BUILDING_SLOTS      => "cai_building_slots/",
  :CAI_WORLD_CHARACTERS          => "cai_characters/",
  :CAI_WORLD_FACTIONS            => "cai_factions/",
  :CAI_WORLD_FORTS               => "cai_forts/",
  :CAI_WORLD_GOVERNORSHIPS       => "cai_governorships/",
  :CAI_WORLD_REGIONS             => "cai_regions/",
  :CAI_WORLD_REGION_BOUNDARIES   => "cai_boundaries/",
  :CAI_WORLD_REGION_HLCIS        => "cai_region_hlcis/",
  :CAI_WORLD_REGION_SLOTS        => "cai_region_slots/",
  :CAI_WORLD_REOURCE_MOBILES     => "cai_armies/",
  :CAI_WORLD_RESOURCE_MOBILES    => "cai_mobiles/",
  :CAI_WORLD_SEA_GRID_CELLS      => "cai_sea_grid_cells/",
  :CAI_WORLD_SETTLEMENTS         => "cai_settlements/",
  :CAI_WORLD_TECHNOLOGY_TREES    => "cai_tech_trees/",
  :CAI_WORLD_THEATRES             => "cai_theatres/",
  :CAI_WORLD_TRADE_ROUTE_SEGMENTS => "cai_trade_routes/",
  :CAI_WORLD_TRANSITION_AREAS    => "cai_transition_areas/",
  :CAI_WORLD_TRADING_POSTS       => "cai_trading_posts/",
  :CAI_WORLD_UNITS               => "cai_units/",
  :CAMPAIGN_ENV                  => "campaign_env/env",
  :CAMPAIGN_MODEL                => "campaign_env/campaign_model",
  :CAMPAIGN_PATHFINDER           => "campaign-pathfinder/",
  :CAMPAIGN_PREOPEN_MAP_INFO     => "preopen_map_info/info-%s",
  :CAMPAIGN_SETUP                => "campaign_env/campaign_setup",
  :CAMPAIGN_TRADE_MANAGER        => "campaign_env/trade_manager",
  :CHARACTER_ARRAY               => "character/%f-%s-%d",
  :CHARACTER_OBSTACLE            => "campaign-pathfinder/character_obstacle/%d",
  :DIPLOMACY_MANAGER             => "diplomacy/%s",
  :DOMESTIC_TRADE_ROUTES         => "domestic_trade_routes/%s",
  :FACTION                       => "factions/%s",
  :FACTION_TECHNOLOGY_MANAGER    => "technology/%f",
  :FAMILY                        => "family/%s",
  :FARM_MANAGER                  => "farm_manager", # Uses some irrelevant string far inside
  :FORT_OBSTACLE                 => "campaign-pathfinder/fort_obstacle/%d",
  :FORTIFICATION_SLOT            => "region_slot/%s-walls",
  :FORT_ARRAY                    => "region_slot/%s-fort-%d",
  :GOVERNMENT                    => "government/%f-%s",
  :INTERNATIONAL_TRADE_ROUTES    => "international_trade_routes/%s",
  :LAND_UNIT_NAMES_MAP           => "unit_name_alloc/%s-land-%d",
  :MARKER_MANAGER                => "campaign_env/marker_manager",
  :NAVAL_UNIT_NAME_ALLOCATOR     => 'unit_name_alloc/%s-naval-%d',
  :OBSTACLE_BASE_GRID_NODE       => "campaign-pathfinder/obstacle_base_grid_node/%d",
  :OBSTACLE_BOUNDARY_MANAGER     => "campaign-pathfinder/obstacle_boundary/%d",
  :PATHFINDING_GRID              => "campaign-pathfinder/grid-%d",
  :POPULATION                    => "population/%s",
  :PORTRAIT_ALLOCATOR            => "campaign_env/portraits-%s",
  :QUAD_TREE_BIT_ARRAY           => "quadtree/%f-%s-%d",
  :REGION                        => 'region/%s',
  :REGION_SLOT_ARRAY             => "region_slot/%s",
  :ROAD_SLOT                     => "region_slot/%s-road",
  :SAVE_GAME_HEADER              => "save_game_header/%s",
  :SETTLEMENT                    => "region_slot/%s",
  :TRADE_NODE_ROUTES             => "trade_node/%s",
  :TRADE_NODES                   => "campaign_env/trade_nodes/%s",
  :TRADE_ROUTES                  => "campaign_env/trade_routes/%s",
  :TRADE_SEGMENTS                => "campaign_env/trade_segments/%s",
  :TREE_LOD_LIST                 => "tree_lod_list",
  :VICTORY_CONDITION_OPTIONS     => "victory_conditions/%s",
  :WORLD                         => "campaign_env/world",
  :grid_data                     => "grid_data-%d",
  :mountain_data                 => "mountains",
  :pathfinding_areas             => "pathfinding_areas-%d",
  :query_info                    => "query_info-%d",
  :region_data                   => "region_data-%d",
  :regions                       => "regions-%R/%s",
  :theatres                      => "theatre/%s",
  :FARM_LIST                     => "farms/%d",
  :WALL_LIST                     => "walls/%d",
  :ROAD_LIST                     => "roads",
  :EF_LINE_LIST                  => "eflines",
  :areas                         => "area-%R/%s-%D",
  :slot_descriptions             => "slot/%s",
  :HERO_UNIT_NAME_ALLOCATOR      => "HERO_UNIT_NAME_ALLOCATOR/",
}