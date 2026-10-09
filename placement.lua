local modname = core.get_current_modname()
local S = core.get_translator(modname)

function tarot_redo.place_tarot_card(itemstack, player, pointed_thing)
    local debug = false

    local handled, result = tarot_redo.try_process_rightclick(itemstack, player, pointed_thing)
    if handled then return result end

    if not player or not player:is_player() then return end

    local player_name = player:get_player_name()

    if pointed_thing.type ~= "node" then return end

    local under_pos = pointed_thing.under
    local under_node = core.get_node_or_nil(under_pos)
    local under_def = under_node and core.registered_nodes[under_node.name]
    if debug then
        core.debug("under", under_pos, under_node.name)
    end
    if not under_def then return end

    -- Ignore if the node above is not air.
    -- Tarot cards cannot replace buildable_to nodes.
    local above_pos = pointed_thing.above
    local above_node = core.get_node(above_pos)
    if debug then
        core.debug("above", above_pos, above_node.name)
    end
    if above_node.name ~= "air" then return end

    if core.is_protected(above_pos, player_name) then return end

    local tarot_pos = above_pos

    local vec_out = above_pos - under_pos
    if debug then
        core.debug("vec_out:", vec_out)
    end

    local look_dir = player:get_look_dir()
    local look_yaw = player:get_look_horizontal()
    if debug then
        core.debug("look_dir:", look_dir, "look_yaw:", look_yaw)
    end

    local facedir = 8
    if vec_out.y > 0 then
        -- Tarot card faces up (+Y).  Rotate the card to the player's look yaw.
        -- The look yaw is right-handed rotation from +N w.r.t. upward axis,
        -- but the facedir is left-hand rotation from +N w.r.t. upward axis.
        if look_yaw < math.pi / 4 then
            facedir = 0
        elseif look_yaw < math.pi * 3 / 4 then
            facedir = 3
        elseif look_yaw < math.pi * 5 / 4 then
            facedir = 2
        elseif look_yaw < math.pi * 7 / 4 then
            facedir = 1
        else
            facedir = 0
        end
    elseif vec_out.y < 0 then
        -- Tarot card faces down (-Y).  Rotate the card to the player's look yaw.
        -- Both the look_dir yaw and the facedir are right-handed rotation from +N w.r.t. upward axis.
        -- But the card should still look upright from the player's perspective.
        -- It means if the player is facing north, the card's top should point to south.
        -- So a 180 degree phase is added to the facedir.
        if look_yaw < math.pi / 4 then
            facedir = 2
        elseif look_yaw < math.pi * 3 / 4 then
            facedir = 3
        elseif look_yaw < math.pi * 5 / 4 then
            facedir = 0
        elseif look_yaw < math.pi * 7 / 4 then
            facedir = 1
        else
            facedir = 2
        end
        facedir = facedir + 5 * 4 -- 5 in the high bits means -Y.
    elseif vec_out.x > 0 then
        -- East (+X), on the wall.  Put the card upward and face east.
        -- 3*4 is obtained by rotating 0 by 90 degrees around the Z axis,
        -- so when facedir == 3 * 4, the head is towards north.
        -- We rotate 270 degrees left-handed around +X.
        facedir = 3 * 4 + 3
    elseif vec_out.x < 0 then
        -- west (-X)
        -- 4*4 is obtained by rotating 0 by 90 deg around Z.  Top points north.
        -- Rotate 90 degrees left-handed around -X.
        facedir = 4 * 4 + 1
    elseif vec_out.z > 0 then
        -- north (+Z)
        -- 1*4 is obtained by rotating 0 by 90 deg around X.  Top points down.
        -- Rotate 180 degrees
        facedir = 1 * 4 + 2
    elseif vec_out.z < 0 then
        -- south (-Z)
        -- 2*4 is obtained by rotating 0 by 90 deg around X.  Is still upright.
        facedir = 2 * 4
    else
        -- This should be unreachable.  It is an error if this happens.
        -- Log the error and fall back to 0
        if debug then
            core.debug("Unexpected vec_out: ", vec_out)
        end
        facedir = 0
    end

    local tarot_table, table_too_large

    local node_name = itemstack:get_name()
    if node_name == "tarot_redo:tarot_card" then
        -- If it is the unrevealed Tarot Card item, draw a concrete card.
        -- Make sure it is different from all cards on the table.

        tarot_table, table_too_large = tarot_redo.find_table(above_pos, under_pos)
        -- We will give "table too large" warning and highlighting after placing card to reduce perceived lag.

        local excluded = {}
        local num_excluded = 0
        local total_cards = #tarot_redo.deck
        local major_arcana_only = tarot_redo.settings_map.major_arcana_only:get(player)
        local major_arcana_max = #tarot_redo.catalog.major.cards
        for i = 1, total_cards do
            excluded[i] = false
        end
        if major_arcana_only then
            for i = major_arcana_max + 1, total_cards do
                excluded[i] = true
            end
            num_excluded = total_cards - major_arcana_max
        end
        for _, table_pos in ipairs(tarot_table) do
            local above_table_pos = table_pos + vec_out
            local above_table_node_name = core.get_node(above_table_pos).name
            local global_ordinal = core.get_item_group(above_table_node_name, "tarot_card")
            if global_ordinal ~= 0 and not excluded[global_ordinal] then
                excluded[global_ordinal] = true
                num_excluded = num_excluded + 1
                if debug then
                    core.debug("global_ordinal:", global_ordinal)
                    local card = tarot_redo.deck[global_ordinal]
                    core.debug("Card", card.title, "at", above_table_pos, "excludes", global_ordinal, "total excluded",
                        num_excluded)
                end
            end
        end

        local available = #tarot_redo.deck - num_excluded

        local random_ordinal
        if available == 0 then
            local message = major_arcana_only and
                S("WARNING: All major arcana can be found on the table.  Drawing at random.") or
                S("WARNING: All Tarot cards can be found on the table.  Drawing at random.")
            core.chat_send_player(player_name, message)
            random_ordinal = math.random(#tarot_redo.deck)
        else
            if debug then
                core.debug("Drawing from remaining", available, "available cards")
            end
            local available_index = math.random(available)
            local found_available = 0
            for i, v in ipairs(excluded) do
                if not v then
                    found_available = found_available + 1
                end
                if found_available == available_index then
                    random_ordinal = i
                    break
                end
            end
            if not random_ordinal then
                -- This is impossible.  But if this really happens, we fall back to 1 (The Fool).
                random_ordinal = 1
            end
        end

        local card = tarot_redo.deck[random_ordinal]
        node_name = tarot_redo.card_to_node_name(card)

        -- Randomly drawn cards have a 50% chance to be reversed if allowed.
        if tarot_redo.settings_map.allow_reversed:get(player) then
            local should_reverse = math.random(2)
            if should_reverse == 2 then
                -- Filp the second lowest bit so that it is flipped 180 degrees.
                facedir = facedir ~ 2
                if debug then
                    core.debug("Reversed.  facedir:", facedir)
                end
            end
        end
    end

    core.set_node(tarot_pos, {
        name = node_name,
        param1 = 0,
        param2 = facedir,
    })

    itemstack:take_item()

    -- Warn the player after placing card.
    if table_too_large and tarot_redo.settings_map.warn_table_too_large:get(player) then
        tarot_redo.warn_table_too_large(player_name, true)
        tarot_redo.highlight_table_inner(tarot_table, vec_out, true)
    end

    return itemstack
end

-- Get a vector basis on the plane perpendicular to the vector v.
-- The returned vectors are guaranteed to point to the positive directions of their respective axes.
local function get_perpendicular_vector_basis(v)
    local v1, v2
    if v.x ~= 0 then
        v1 = vector.new(0, 1, 0)
        v2 = vector.new(0, 0, 1)
    elseif v.z ~= 0 then
        v1 = vector.new(1, 0, 0)
        v2 = vector.new(0, 1, 0)
    else
        v1 = vector.new(1, 0, 0)
        v2 = vector.new(0, 0, 1)
    end
    return v1, v2
end

local NOT_VISITED = 0
local PART_OF_TABLE = 1
local NOT_PART_OF_TABLE = 2

-- Find a contiguous surface that consists of nodes of the same kind.
function tarot_redo.find_table(above, under)
    local debug = false

    local node_name_under = core.get_node(under).name

    local vec_out = above - under
    local v1, v2 = get_perpendicular_vector_basis(vec_out)

    if debug then
        core.debug("under:", under, "vec_out:", vec_out, "v1:", v1, "v2:", v2, "node_name_under:", node_name_under)
    end

    -- The radius is the max distance allowed to go in each dimension.
    local radius = tarot_redo.dedup_radius
    local width = radius * 2 + 1
    local array_size = width * width

    -- (s, t) is the coordinate of a block in the table plane.
    -- The pos of a block is `s * v1 + t * v2`

    -- This function gives each (s, t) coordinate an array index.
    -- Note that Lua array indices start at 1.
    local function st_to_index(s, t)
        return (s + radius) * width + (t + radius) + 1
    end

    -- This converts index back to the (s, t) coordinate.
    local function index_to_st(index)
        local s = math.floor((index - 1) / width) - radius
        local t = (index - 1) % width - radius
        return s, t
    end

    -- Check if the (s, t) coordinate is within the radius
    local function is_in_bound(s, t)
        return -radius <= s and s <= radius and -radius <= t and t <= radius
    end

    -- Convert (s, t) to 3D pos
    local function st_to_pos(s, t)
        return under + s * v1 + t * v2
    end

    local function is_part_of_table(s, t)
        local pos = st_to_pos(s, t)
        local node_name_pos = core.get_node(pos).name
        if debug then
            core.debug("s:", s, "t:", t, "pos:", pos, "node_name_pos:", node_name_pos)
        end
        return node_name_pos == node_name_under
    end

    -- Search from `under`.
    -- We use depth-first search for the ease of implementation.
    -- It doesn't really matter.
    if debug then
        core.debug("Commencing search...")
    end
    local starting_index = st_to_index(0, 0)
    local queue = { starting_index }

    local visited = {}
    for index = 1, array_size do
        visited[index] = NOT_VISITED
    end
    visited[starting_index] = PART_OF_TABLE

    local found_out_of_bound_block = false

    while #queue > 0 do
        local current_index = table.remove(queue)
        local cs, ct = index_to_st(current_index)

        if debug then
            core.debug("Visiting node. current_index:", current_index, "cs:", cs, "ct:", ct)
        end

        local function try_enqueue(ns, nt)
            if not is_in_bound(ns, nt) and not found_out_of_bound_block then
                found_out_of_bound_block = true
                return
            end

            local new_index = st_to_index(ns, nt)
            if visited[new_index] ~= NOT_VISITED then return end

            if is_part_of_table(ns, nt) then
                visited[new_index] = PART_OF_TABLE
                table.insert(queue, new_index)
            else
                visited[new_index] = NOT_PART_OF_TABLE
            end
        end

        try_enqueue(cs + 1, ct)
        try_enqueue(cs - 1, ct)
        try_enqueue(cs, ct + 1)
        try_enqueue(cs, ct - 1)
    end

    local result = {}
    for index = 1, array_size do
        if visited[index] == PART_OF_TABLE then
            local s, t = index_to_st(index)
            local pos = st_to_pos(s, t)
            table.insert(result, pos)
        end
    end

    return result, found_out_of_bound_block
end

function tarot_redo.highlight_table(itemstack, player, pointed_thing)
    if pointed_thing.type ~= "node" then return false end

    local table_poses, table_too_large = tarot_redo.find_table(pointed_thing.above, pointed_thing.under)
    local vec_out = pointed_thing.above - pointed_thing.under
    tarot_redo.highlight_table_inner(table_poses, vec_out)

    if table_too_large then
        tarot_redo.warn_table_too_large(player:get_player_name())
    end

    return true
end

function tarot_redo.highlight_table_inner(table_poses, vec_out, simple)
    local v1, v2 = get_perpendicular_vector_basis(vec_out)
    for _, pos in ipairs(table_poses) do
        if simple then
            -- Simple effect for warning when the table is too large.
            core.add_particle({
                pos = pos + vec_out * 0.5,
                velocity = vec_out * 0.05,
                expirationtime = 1.5,
                size = 3,
                texture = "plus.png^[multiply:#cc88ff",
                glow = 14,
                collisiondetection = false,
            })
        else
            -- Full effect for highlighting table area using Tarot Book.
            core.add_particlespawner({
                amount = 20,
                time = 0.1,
                pos = {
                    min = pos + vec_out * 0.5 - v1 * 0.5 - v2 * 0.5,
                    max = pos + vec_out * 0.5 + v1 * 0.5 + v2 * 0.5,
                },
                minsize = 1,
                maxsize = 3,
                minvel = vec_out * 0.05,
                maxvel = vec_out * 0.1,
                minexptime = 1,
                maxexptime = 2,
                texpool = {
                    { name = "plus.png^[multiply:#8800ff", alpha = 0.7, },
                    { name = "plus.png^[multiply:#aa44ff", alpha = 0.7, },
                    { name = "plus.png^[multiply:#cc88ff", alpha = 0.7, },
                    { name = "plus.png^[multiply:#eeccff", alpha = 0.7, },
                },
                glow = 14,
                collisiondetection = false,
            })
        end
    end
end

function tarot_redo.warn_table_too_large(player_name, suppressable)
    local max_table_size = tarot_redo.dedup_radius + 1
    local message = S("WARNING: Your table is too large.  The maximum supported size is @1x@2.",
        max_table_size, max_table_size)
    if suppressable then
        message = message .. S(" (You can suppress this warning in settings. Open with /tarot_book)")
    end
    core.chat_send_player(player_name, message)
end
