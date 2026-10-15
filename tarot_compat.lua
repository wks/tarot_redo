local modname = core.get_current_modname()
local S = core.get_translator(modname)

--- To avoid confusion, we replace the "tarot:deck" with a "Tarot Reading Device".
--- It looks like a television and can be placed in the world.

local function open_reading_ui(player)
    if not player then return end

    local name = player:get_player_name()
    if not player then return end

    tarot.select_reading(name)
end

local reading_device_def = {
    description = S("Tarot Reading Device"),
    _tt_help = table.concat({
        S("Use (left-click) to open the Tarot reading interface from the original Tarot mod."),
        S("Can be placed in the world.  Then right-click to open the Tarot reading interface."),
        S("Note: The UI can also be opened using the '/select_reading' chat command."),
    }, "\n"),
    tiles = {
        "tarot_redo_reader_top.png",
        "tarot_redo_reader_bottom.png",
        "tarot_redo_reader_left.png^[transformFX",
        "tarot_redo_reader_left.png",
        "tarot_redo_reader_back.png",
        "tarot_redo_reader_front.png",
    },

    drawtype = "normal",
    paramtype = "light",
    paramtype2 = "facedir",

    light_source = core.LIGHT_MAX - 1,

    groups = {
        -- MTG
        oddly_breakable_by_hand = 2,
        cracky = 3,
        -- MCL
        handy = 1,
        pickaxey = 1,
    },

    -- MCL
    _mcl_hardness = 1,

    on_use = function(itemstack, user, pointed_thing)
        open_reading_ui(user)
    end,
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        open_reading_ui(clicker)
    end,
}

if core.get_modpath("default") then
    reading_device_def.sounds = default.node_sound_metal_defaults()
elseif core.get_modpath("mcl_sounds") and mcl_sounds then
    reading_device_def.sounds = mcl_sounds.node_sound_metal_defaults()
end

core.register_node("tarot_redo:reading_device", reading_device_def)

-- core.unregister_item("tarot:deck")

-- Clear the original recipe for "tarot:deck" to avoid confusion.
core.clear_craft({
    output = "tarot:deck",
})

core.register_alias("tarot:deck", "tarot_redo:reading_device")
