local materials = nil
local metal_sounds = nil

if core.get_modpath("default") and core.get_modpath("dye") then
    -- Minetest Game
    materials = {
        dye = {
            red = "dye:red",
            yellow = "dye:yellow",
            green = "dye:green",
            blue = "dye:blue",
            violet = "dye:violet",
            black = "dye:black",
        },
        paper = "default:paper",
        book = "default:book",
        steel = "default:steel_ingot",
        glass = "default:glass",
    }

    metal_sounds = default.node_sound_metal_defaults()
end

if core.get_modpath("mcl_core") and core.get_modpath("mcl_books") then
    -- Mineclonia or VoxeLibre
    local dye = nil
    if core.get_modpath("mcl_dyes") then
        -- Mineclonia
        dye = {
            red = "mcl_dyes:red",
            yellow = "mcl_dyes:yellow",
            green = "mcl_dyes:green",
            blue = "mcl_dyes:blue",
            violet = "mcl_dyes:purple",
            black = "mcl_dyes:black",
        }
    elseif core.get_modpath("mcl_dye") then
        -- VoxeLibre
        dye = {
            red = "mcl_dye:red",
            yellow = "mcl_dye:yellow",
            green = "mcl_dye:green",
            blue = "mcl_dye:blue",
            violet = "mcl_dye:violet",
            black = "mcl_dye:black",
        }
    end

    -- Leave materials as nil if dye is nil
    if dye then
        materials = {
            dye = dye,
            paper = "mcl_core:paper",
            book = "mcl_books:book",
            steel = "mcl_core:iron_ingot",
            glass = "mcl_core:glass",
        }
    end

    metal_sounds = mcl_sounds.node_sound_metal_defaults()
end

tarot_redo.materials = materials
tarot_redo.metal_sounds = metal_sounds
