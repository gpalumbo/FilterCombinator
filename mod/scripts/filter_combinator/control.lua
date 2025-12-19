-- Filter Combinator Control Module
-- Handles all entity lifecycle events for the filter combinator
-- CRITICAL: Uses Factorio 2.0 APIs only!

local globals = require("scripts.globals")
local entity_lib = require("lib.entity_lib")
local fc_storage = require("scripts.filter_combinator.storage")
local logic = require("scripts.filter_combinator.logic")

local control = {}

-- Entity name constants
local FILTER_COMBINATOR = "filter-combinator"
local OUTPUT_COMBINATOR = "filter-combinator-output"

-----------------------------------------------------------
-- HIDDEN OUTPUT COMBINATOR CREATION
-----------------------------------------------------------

--- Create hidden constant combinators for signal output
--- One for red wire output, one for green wire output
--- @param entity LuaEntity The filter combinator entity
--- @return LuaEntity|nil output_red The red output combinator
--- @return LuaEntity|nil output_green The green output combinator
local function create_output_combinators(entity)
    local surface = entity.surface
    local position = entity.position
    local force = entity.force

    -- Create red wire output combinator
    local output_red = surface.create_entity({
        name = OUTPUT_COMBINATOR,
        position = position,
        force = force,
        create_build_effect_smoke = false,
        raise_built = false  -- Don't trigger build events for hidden entity
    })

    -- Create green wire output combinator
    local output_green = surface.create_entity({
        name = OUTPUT_COMBINATOR,
        position = position,
        force = force,
        create_build_effect_smoke = false,
        raise_built = false
    })

    if not output_red or not output_green then
        -- Cleanup on failure
        if output_red and output_red.valid then output_red.destroy() end
        if output_green and output_green.valid then output_green.destroy() end
        return nil, nil
    end

    -- Make them indestructible and non-interactable
    output_red.destructible = false
    output_red.minable = false
    output_red.rotatable = false

    output_green.destructible = false
    output_green.minable = false
    output_green.rotatable = false

    -- Connect red output combinator to main entity's red output wire
    local main_output_red = entity.get_wire_connector(defines.wire_connector_id.combinator_output_red, false)
    local hidden_red = output_red.get_wire_connector(defines.wire_connector_id.circuit_red, false)

    if main_output_red and hidden_red then
        hidden_red.connect_to(main_output_red, false, defines.wire_origin.script)
    end

    -- Connect green output combinator to main entity's green output wire
    local main_output_green = entity.get_wire_connector(defines.wire_connector_id.combinator_output_green, false)
    local hidden_green = output_green.get_wire_connector(defines.wire_connector_id.circuit_green, false)

    if main_output_green and hidden_green then
        hidden_green.connect_to(main_output_green, false, defines.wire_origin.script)
    end

    return output_red, output_green
end

--- Destroy the hidden output combinators for an entity
--- @param output_red LuaEntity|nil The red output combinator
--- @param output_green LuaEntity|nil The green output combinator
local function destroy_output_combinators(output_red, output_green)
    if output_red and output_red.valid then
        output_red.destroy({raise_destroy = false})
    end
    if output_green and output_green.valid then
        output_green.destroy({raise_destroy = false})
    end
end

-----------------------------------------------------------
-- BUILD EVENT HANDLERS
-----------------------------------------------------------

--- Shared handler for all entity build events
--- Handles both real entities and ghosts, with blueprint tag support
--- @param entity LuaEntity The built entity
--- @param player LuaPlayer|nil The player who built it (nil for robots)
--- @param tags table|nil Blueprint tags (if built from blueprint)
function control.on_built(entity, player, tags)
    if not entity or not entity.valid then return end

    -- Skip ghosts - they use tags not storage
    if entity_lib.is_ghost(entity) then
        if entity_lib.is_type(entity, FILTER_COMBINATOR) then
            if tags and tags.filter_combinator_config then
                fc_storage.save_ghost_config(entity, tags.filter_combinator_config)
            end
        end
        return
    end

    -- Only handle our entity
    if entity.name ~= FILTER_COMBINATOR then return end

    -- Create hidden output combinators for circuit output
    local output_red, output_green = create_output_combinators(entity)
    if not output_red or not output_green then
        log("[filter-combinator] Warning: Failed to create output combinators")
    end

    -- Register the entity in storage with output combinator references
    local state = fc_storage.register(entity, output_red, output_green)
    if not state then
        -- Cleanup output combinators if registration failed
        destroy_output_combinators(output_red, output_green)
        return
    end

    -- Restore config from blueprint tags if present
    if tags and tags.filter_combinator_config then
        -- restore_config calls sync_display_to_mode internally
        fc_storage.restore_config(entity, tags.filter_combinator_config)
    else
        -- Fresh build without tags - sync display to default mode
        fc_storage.sync_display_to_mode(entity)
    end
end

-----------------------------------------------------------
-- DESTROY EVENT HANDLERS
-----------------------------------------------------------

--- Shared handler for all entity removal events
--- Handles cleanup of storage, player GUIs, and hidden output combinators
--- @param entity LuaEntity The removed entity
function control.on_removed(entity)
    if not entity or not entity.valid then return end

    if not entity_lib.is_type(entity, FILTER_COMBINATOR) then
        return
    end

    -- Handle ghost destruction
    if entity_lib.is_ghost(entity) then
        return
    end

    local unit_number = entity.unit_number
    if not unit_number then return end

    -- Close any open GUIs for this entity
    globals.cleanup_player_gui_states_for_entity(entity, "filter_combinator_gui")

    -- Unregister from storage (returns output combinator references)
    local output_red, output_green = fc_storage.unregister(unit_number)

    -- Destroy hidden output combinators
    destroy_output_combinators(output_red, output_green)
end

-----------------------------------------------------------
-- BLUEPRINT AND COPY-PASTE HANDLERS
-----------------------------------------------------------

--- Handle entity settings pasted event
--- @param event EventData.on_entity_settings_pasted
function control.on_entity_settings_pasted(source, destination)
    if not source or not source.valid then return end
    if not destination or not destination.valid then return end

    -- Check if both are our entity
    if not entity_lib.is_type(source, FILTER_COMBINATOR) then return end
    if not entity_lib.is_type(destination, FILTER_COMBINATOR) then return end

    -- Get source configuration (handles both ghosts and real entities)
    local source_config = fc_storage.serialize_config(source)
    if not source_config then return end

    -- Apply to destination (handles both real entities and ghosts)
    fc_storage.restore_config(destination, source_config)
end

--- Handle entity cloned event
--- @param source LuaEntity Source entity
--- @param destination LuaEntity Cloned entity
function control.on_entity_cloned(source, destination)
    if not source or not source.valid then return end
    if not destination or not destination.valid then return end

    -- Check if source is our entity
    if not entity_lib.is_type(source, FILTER_COMBINATOR) then return end
    if not entity_lib.is_type(destination, FILTER_COMBINATOR) then return end

    -- Get source configuration
    local source_config = fc_storage.serialize_config(source)

    -- Register destination if it's a real entity (with output combinators)
    if not entity_lib.is_ghost(destination) then
        -- Create hidden output combinators for the cloned entity
        local output_red, output_green = create_output_combinators(destination)
        fc_storage.register(destination, output_red, output_green)
    end

    -- Restore config if available
    if source_config then
        fc_storage.restore_config(destination, source_config)
    end
end

--- Handle blueprint setup - serialize config to tags
--- @param blueprint LuaItemStack The blueprint being set up
--- @param mapping table Blueprint index to real entity mapping
function control.on_player_setup_blueprint(blueprint, mapping)
    if not blueprint or not blueprint.valid_for_read then return end
    if not mapping then return end

    for blueprint_index, real_entity in pairs(mapping) do
        if real_entity.valid and real_entity.name == FILTER_COMBINATOR then
            local config = fc_storage.serialize_config(real_entity)
            if config then
                blueprint.set_blueprint_entity_tag(blueprint_index, "filter_combinator_config", config)
            end
        end
    end
end

-----------------------------------------------------------
-- PERIODIC UPDATE HANDLERS
-----------------------------------------------------------

--- Called every 2 ticks (~33ms) to process signals
function control.on_tick_2()
    logic.process_all_combinators()
end

-----------------------------------------------------------
-- LIFECYCLE HANDLERS
-----------------------------------------------------------

--- Initialize on mod load
function control.on_init()
    fc_storage.init_storage()
end

--- Handle configuration changes
function control.on_configuration_changed()
    fc_storage.init_storage()
    fc_storage.validate_and_cleanup()
end

return control
