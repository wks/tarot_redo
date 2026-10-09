local modname = core.get_current_modname()
local S = core.get_translator(modname)

tarot_redo = {
    image_w = 300,
    image_h = 527,
}

tarot_redo.dedup_radius = tonumber(core.settings:get("tarot_redo.dedup_radius")) or 25

local path = core.get_modpath(modname) .. "/"

dofile(path .. "settings.lua")
dofile(path .. "utils.lua")
dofile(path .. "dictionary.lua")
dofile(path .. "catalog.lua")
dofile(path .. "forms.lua")
dofile(path .. "placement.lua")
dofile(path .. "nodes.lua")
dofile(path .. "crafts.lua")

core.register_chatcommand("tarot_book", {
    description = S("Open the Tarot Book user interface."),
    func = function(name)
        local player = core.get_player_by_name(name)
        tarot_redo.open_main_ui(player)
    end
})
