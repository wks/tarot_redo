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

    sounds = tarot_redo.metal_sounds,

    groups = {
        -- Populated later.
    },

    -- MCL
    _mcl_hardness = 2,

    on_use = function(itemstack, user, pointed_thing)
        open_reading_ui(user)
    end,
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        open_reading_ui(clicker)
    end,
}

tarot_redo.popluate_reading_device_groups(reading_device_def.groups)

core.register_node("tarot_redo:reading_device", reading_device_def)

-- Remove the original "tarot:deck" item.
-- We can't just create an alias because "tarot:deck" is a tool while "tarot_redo:reading_device" is a node.
core.unregister_item("tarot:deck")

-- Clear the original recipe for "tarot:deck",
-- otherwise the old recipe can still be used for the reading device due to of aliasing.
core.clear_craft({
    output = "tarot:deck",
})

-- Existing tarot decks from the tarot mod become reading devices.
core.register_alias("tarot:deck", "tarot_redo:reading_device")

--- Recipies

local m = tarot_redo.materials

-- m can be nil if the game is unsupported.
-- Don't register recipies if m is nil.
if m then
    local tb = "tarot_redo:tarot_book"
    core.register_craft({
        output = "tarot_redo:reading_device",
        recipe = {
            { m.steel, m.steel, m.steel },
            { m.glass, tb,      m.glass },
            { m.steel, m.steel, m.steel },
        }
    })
end
