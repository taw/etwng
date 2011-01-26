-- Replace OnWorldCreated in scripting.lua with the following:

local function OnWorldCreated()
  scripting.game_interface:technology_osmosis_for_playables_enable_culture("european")
  scripting.game_interface:technology_osmosis_for_playables_enable_all()
  scripting.game_interface:show_shroud(false)
end
