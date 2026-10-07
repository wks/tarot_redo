local function is_on_rightclick_suppressed(player)
    if not player or not player:is_player() then return false end
    local control = player:get_player_control()
    -- It is hard to use sneak if the player can fly, so we include aux1.
    return control.sneak or control.aux1
end

function tarot_redo.try_process_rightclick(itemstack, player, pointed_thing)
    if pointed_thing.type ~= "node" then return false end

    local under_pos = pointed_thing.under
    local under_node = core.get_node_or_nil(under_pos)
    local under_def = under_node and core.registered_nodes[under_node.name]
    if not under_def then return false end

    if under_def.on_rightclick and not is_on_rightclick_suppressed(player) then
        return true, under_def.on_rightclick(under_pos, under_node, player, itemstack, pointed_thing)
    end

    return false
end
