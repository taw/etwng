DefaultVersions = Hash.new(0).merge({
  :"FAMILY::MONARCHY_INFO_CHARACTER" => 2,
  :"GOVERNMENT::ABSOLUTE_MONARCHY" => 1,
  :"GOVERNMENT::CONSTITUTIONAL_MONARCHY" => 3,
  :"GOVERNMENT::REPUBLIC" => 3,
  :ANCILLARY_UNIQUENESS_MONITOR => 1,
  :ARMY => 2,
  :ARMY_REINFORCEMENT_MANAGER => 1,
  :BARRIER_OBSTACLE => 1,
  :BATTLEFIELD_BUILDING_LIST => 2,
  :BATTLE_DEPLOYMENT_AREA => 2,
  :BATTLE_DEPLOYMENT_AREA_COLLECTION => 1,
  :BATTLE_DEPLOYMENT_AREA_MANAGER => 2,
  :BATTLE_MAP_DEFINITION => 8,
  :BATTLE_MAP_DEFINITION_SETTINGS => 3,
  :BMD_AI_HINT_DIRECTED_POINT_LIST => 1,
  :BMD_TEXTURES => 3,
  :BUILDING => 1,
  :BUILDING_MANAGER => 1,
  :CAI_ACTIVE_RECRUITMENT_ANALYSIS => 1,
  :CAI_BASIC_FACTION_ABSOLUTE_ANALYSIS => 1,
  :CAI_BDIM_ATTACK_SH => 1,
  :CAI_BDIM_OCCUPY_GARRISONABLE_SH => 1,
  :CAI_BDIM_SIEGE_SH => 1,
  :CAI_BDIM_SPLIT => 1,
  :CAI_BDI_COMPONENT_PROPERTY_SET => 1,
  :CAI_BDI_CORRIDOR => 5,
  :CAI_BDI_DESIRE_EXPAND_FACTION => 1,
  :CAI_BDI_DESIRE_RECALL_ASSETS => 1,
  :CAI_BDI_EXCESS_RECRUITMENT_BEHAVIOUR => 1,
  :CAI_BDI_FAILED_REGION_TARGETS => 1,
  :CAI_BDI_FORT_MAINTAINENCE_BEHAVIOUR => 3,
  :CAI_BDI_FORT_TYPE_CONSTRUCTION => 1,
  :CAI_BDI_FRONTIER_REGION_INFORMATION => 1,
  :CAI_BDI_GOAL_ACQUIRE_REGION => 2,
  :CAI_BDI_GOAL_RECRUIT_STRENGTH_IN_REGION => 1,
  :CAI_BDI_GOAL_REGION_DEFENCE => 1,
  :CAI_BDI_GOAL_REGION_DEFENCE_ASSET_BASE => 1,
  :CAI_BDI_GOAL_REGION_DEFENCE_SLOTS => 1,
  :CAI_BDI_GOAL_REGION_GROUP_DEFENCE => 2,
  :CAI_BDI_INVASION_REQUEST => 2,
  :CAI_BDI_POOL => 1,
  :CAI_BDI_RECRUITMENT_NEW_FORCE_OF_OR_REINFORCE_TO_STRENGTH => 2,
  :CAI_BDI_REGISTERED_REGION_TARGET => 1,
  :CAI_BDI_RESERVED_NAVIES => 1,
  :CAI_BDI_RESERVED_NAVY => 1,
  :CAI_BDI_RESERVED_NAVY_RESERVATION => 1,
  :CAI_BDI_TARGET_PATH => 1,
  :CAI_BDI_TARGET_REGION_BASE => 2,
  :CAI_BDI_TARGET_REGION_INVASION => 1,
  :CAI_BDI_WAR => 1,
  :CAI_BDI_WAR_AND_PEACE_MANAGER => 2,
  :CAI_CENTRAL_BDI_POOL => 3,
  :CAI_DEFENCE_AND_INVASION_FORCE_STRENGTH_ANALYSIS_REGION => 1,
  :CAI_DIPLOMATIC_ANALYSIS => 2,
  :CAI_DIPLOMATIC_ANALYSIS_FACTIONINFO => 1,
  :CAI_FACTION => 2,
  :CAI_FACTION_ATTITUDE_PAIR => 1,
  :CAI_FACTION_BDI_POOL => 3,
  :CAI_FACTION_BDI_POOL_FINANCE_MANAGER_BASIC => 3,
  :CAI_FACTION_RESEARCH_TECHNOLOGY_FACTION_ANALYSIS => 1,
  :CAI_FACTION_TRADE_STATUS => 3,
  :CAI_HIGH_LEVEL_PATH => 2,
  :CAI_HIGH_LEVEL_PATHFINDER => 1,
  :CAI_INTERFACE => 13,
  :CAI_INVASION_TRACKING_SYSTEM_INFORMATION => 1,
  :CAI_NAVY_RECRUITMENT_FACTION_ANALYSIS => 2,
  :CAI_REGION => 1,
  :CAI_REGION_TARGET_PATHS_ANALYSIS => 1,
  :CAI_RTPA_REGION_GROUP_INFO => 2,
  :CAMPAIGN_BONUS_VALUE => 1,
  :CAMPAIGN_BONUS_VALUES => 1,
  :CAMPAIGN_CALENDAR => 2,
  :CAMPAIGN_CAMERA => 1,
  :CAMPAIGN_CAMERA_MANAGER => 4,
  :CAMPAIGN_ENV => 2,
  :CAMPAIGN_LOCALISATION => 1,
  :CAMPAIGN_MAP_DATA => 2,
  :CAMPAIGN_MAP_TRANSITION_LINK => 1,
  :CAMPAIGN_MISSION_MANAGER => 1,
  :CAMPAIGN_MODEL => 9,
  :CAMPAIGN_PATHFINDER => 5,
  :CAMPAIGN_PLAYERS_SETUP => 1,
  :CAMPAIGN_PLAYER_SETUP => 3,
  :CAMPAIGN_PLAYER_SETUP_INGAME_MODIFIABLES => 2,
  :CAMPAIGN_PREOPEN_MAP_INFO => 4,
  :CAMPAIGN_SETUP => 2,
  :CAMPAIGN_SETUP_INGAME_MODIFIABLES => 3,
  :CAMPAIGN_SETUP_LOCAL => 1,
  :CAMPAIGN_SETUP_OPTIONS => 4,
  :CAMPAIGN_SHROUD => 1,
  :CAMPAIGN_SPYING => 1,
  :CAMPAIGN_STARTPOS => 5,
  :CAMPAIGN_TRADE_MANAGER => 5,
  :CAMPAIGN_VICTORY_CONDITIONS => 3,
  :CDIR_INTERFACE => 1,
  :CDIR_WORLD => 1,
  :CHARACTER => 6,
  :CHARACTER_DETAILS => 2,
  :CHARACTER_OBSTACLE => 1,
  :CHARACTER_PORTRAIT_PATHS => 1,
  :CHARACTER_POST => 1,
  :COMMANDER_DETAILS => 2,
  :DIPLOMACY_MANAGER => 2,
  :DIPLOMACY_RELATIONSHIP => 9,
  :DOMESTIC_TRADE_ROUTE => 1,
  :ECONOMICS_DATA => 5,
  :EF_LINE => 1,
  :EF_LINE_LIST => 1,
  :EPISODIC_RESTRICTIONS => 8,
  :FACTION => 12,
  :FACTION_ECONOMICS => 6,
  :FACTION_FLAG_AND_COLOURS => 1,
  :FACTION_TECHNOLOGY_MANAGER => 4,
  :FAMILY => 2,
  :FAMOUS_BATTLE_INFO => 1,
  :FARM => 3,
  :FARM_COLLISION => 1,
  :FARM_DATA_COLLECTION => 1,
  :FARM_DATA_ITEM => 1,
  :FARM_DATA_ITEM_LIST => 1,
  :FARM_DATA_ITEM_OWNER => 2,
  :FARM_DATA_ITEM_OWNER_INSTANCE => 1,
  :FARM_DECAL_LIST => 1,
  :FARM_INSTANCE => 2,
  :FARM_LIST => 1,
  :FARM_MANAGER => 3,
  :FARM_TILE_SET => 1,
  :FARM_TILE_TEMPLATE => 4,
  :FARM_TREE => 1,
  :FARM_TREE_LIST => 1,
  :FORT => 4,
  :FORTIFICATION_DAMAGE_INFO => 1,
  :FORT_OBSTACLE => 1,
  :FORT_UPGRADE_MANAGER => 1,
  :GARRISON_RESIDENCE => 1,
  :GOVERNMENT => 1,
  :GOVERNORSHIP => 1,
  :GOVERNORSHIP_TAXES => 1,
  :GROUND_TYPE_FIELD => 1,
  :HEIGHT_FIELD => 1,
  :HISTORICAL_CHARACTER_MANAGER => 1,
  :HISTORICAL_EVENT_MANAGER => 1,
  :ID_LIST => 1,
  :INTERNATIONAL_TRADE_ROUTE => 3,
  :LAND_UNIT => 1,
  :LAND_UNIT_NAME_ALLOCATOR => 1,
  :LINE_OF_SIGHT => 1,
  :LOCOMOTABLE => 1,
  :LOCOMOTION_MANAGER => 2,
  :MANAGED_OBSTACLE_BOUNDARY => 1,
  :MARKER_MANAGER => 1,
  :MILITARY_FORCE => 1,
  :NAME_ALLOCATION_DETAILS => 1,
  :NAVAL_UNIT => 1,
  :NAVAL_UNIT_NAME_ALLOCATOR => 1,
  :NAVY => 1,
  :OBSTACLE => 4,
  :OBSTACLE_BASE_GRID_NODE => 1,
  :OBSTACLE_BOUNDARIES => 1,
  :OBSTACLE_BOUNDARY => 1,
  :OBSTACLE_BOUNDARY_MANAGER => 1,
  :OBSTACLE_LISTS => 1,
  :PATHFINDING_GRID => 4,
  :PENDING_BATTLE => 6,
  :POPULATION => 1,
  :POPULATION_CLASS => 3,
  :PORTRAIT_ALLOCATION => 1,
  :PORTRAIT_ALLOCATOR => 1,
  :PORTRAIT_DETAILS => 1,
  :PORT_GARRISON_MANAGER => 2,
  :POSITIONED_WALL_HANDLE_LIST => 1,
  :PRESTIGE => 2,
  :QUAD_TREE_BIT_ARRAY => 1,
  :QUAD_TREE_BIT_ARRAY_NODE => 1,
  :REGION => 4,
  :REGION_FACTORS => 1,
  :REGION_MANAGER => 1,
  :REGION_RECRUITMENT_MANAGER => 1,
  :REGION_SLOT => 3,
  :REGION_SLOT_MANAGER => 1,
  :ROAD => 2,
  :ROAD_LIST => 1,
  :SAVE_GAME_HEADER => 1,
  :SETTLEMENT => 2,
  :SHIP_DAMAGE_INFO => 1,
  :SIEGEABLE_GARRISON_RESIDENCE => 1,
  :SIMPLE_SOUND_EMITTER_LIST => 1,
  :THEATRE => 2,
  :THEATRE_TRANSITION_INFO => 1,
  :TRAIT => 1,
  :TRAITS => 1,
  :TREE_LIST => 2,
  :TREE_LOD_LIST => 1,
  :TURN_TIMER => 1,
  :UNIT => 2,
  :UNIT_CLASS_NAME_ALLOCATOR => 1,
  :UNIT_HISTORY => 1,
  :WALL => 2,
  :WALL_INSTANCE => 2,
  :WALL_LIST => 1,
  :WALL_POST => 1,
  :WALL_POST_LIST => 1,
  :WEATHER_AUTO_GENERATOR_OUTPUT => 1,
  :WORLD => 4,
})
