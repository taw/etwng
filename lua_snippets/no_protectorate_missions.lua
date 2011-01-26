-- To disable protectorate missions, edit startpos.lua
-- and replace OnFactionTurnStart function with the following:

local function OnFactionTurnStart(context)
  if conditions.TurnNumber(context) == 5 then
    scripting.game_interface:enable_auto_generated_missions(true)
  end
end
