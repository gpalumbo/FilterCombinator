-- Filter Combinator Mod - Main Control
-- Event registration and routing to entity-specific handlers

local flib_gui = require("__flib__.gui")

-- Entity modules
local fc_control = require("scripts.filter_combinator.control")
local fc_gui = require("scripts.filter_combinator.gui")
local globals = require("scripts.globals")
local entity_lib = require("lib.entity_lib")
local signal_utils = require("lib.signal_utils")

-- Entity name constants
local FILTER_COMBINATOR = "filter-combinator"

-----------------------------------------------------------
-- CUSTOM INPUT HANDLERS
-----------------------------------------------------------

-- Register custom input handler for pipette tool on GUI signal buttons
script.on_event("gui-pipette-signal", function(event)
    -- Check if hovering over a signal sprite-button with signal data
    if event.element and event.element.tags and event.element.tags.signal_sel then
        local signal_id = event.element.tags.signal_sel
        local player = game.get_player(event.player_index)

        if not player then return end

        -- Convert signal_id to PipetteID format
        local pipette_id = signal_utils.signal_to_prototype(signal_id)

        if pipette_id then
            -- Try pipette with error handling
            pcall(function()
                player.pipette(pipette_id, signal_id.quality, true)
            end)
        end
    end
end)

-----------------------------------------------------------
-- LIFECYCLE EVENTS
-----------------------------------------------------------

script.on_init(function()
    log("[filter-combinator] on_init")
    globals.init_storage()
    fc_control.on_init()
end)

script.on_configuration_changed(function(data)
    log("[filter-combinator] on_configuration_changed")
    globals.init_storage()
    fc_control.on_configuration_changed()
end)

-----------------------------------------------------------
-- BUILD EVENT ROUTING
-----------------------------------------------------------

-- Helper to route build events
local function route_build_event(event)
    local entity = event.entity
    if not entity or not entity.valid then return end

    if entity_lib.is_type(entity, FILTER_COMBINATOR) then
        fc_control.on_built(entity, event.player_index and game.get_player(event.player_index) or nil, event.tags)
    end
end

-- Register build events with filters
local build_filter = {
    {filter = "name", name = FILTER_COMBINATOR},
    {filter = "ghost_name", name = FILTER_COMBINATOR}
}

script.on_event(defines.events.on_built_entity, route_build_event, build_filter)
script.on_event(defines.events.on_robot_built_entity, route_build_event, build_filter)
script.on_event(defines.events.on_space_platform_built_entity, route_build_event, build_filter)
script.on_event(defines.events.script_raised_built, route_build_event, build_filter)
script.on_event(defines.events.script_raised_revive, route_build_event, build_filter)

-----------------------------------------------------------
-- DESTROY EVENT ROUTING
-----------------------------------------------------------

local function route_destroy_event(event)
    local entity = event.entity
    if not entity or not entity.valid then return end

    if entity_lib.is_type(entity, FILTER_COMBINATOR) then
        fc_control.on_removed(entity)
    end
end

local destroy_filter = {
    {filter = "name", name = FILTER_COMBINATOR},
    {filter = "ghost_name", name = FILTER_COMBINATOR}
}

script.on_event(defines.events.on_player_mined_entity, route_destroy_event, destroy_filter)
script.on_event(defines.events.on_robot_mined_entity, route_destroy_event, destroy_filter)
script.on_event(defines.events.on_space_platform_mined_entity, route_destroy_event, destroy_filter)
script.on_event(defines.events.on_entity_died, route_destroy_event, destroy_filter)
script.on_event(defines.events.script_raised_destroy, route_destroy_event, destroy_filter)

-----------------------------------------------------------
-- GUI EVENT ROUTING
-----------------------------------------------------------

-- Handle GUI opened events
script.on_event(defines.events.on_gui_opened, function(event)
    fc_gui.on_gui_opened(event)
end)

-- Handle GUI closed events
script.on_event(defines.events.on_gui_closed, function(event)
    fc_gui.on_gui_closed(event)
end)

-- Handle all GUI clicks
script.on_event(defines.events.on_gui_click, function(event)
    fc_gui.on_gui_click(event)
end)

-- Handle switch state changes (for mode toggle)
script.on_event(defines.events.on_gui_switch_state_changed, function(event)
    fc_gui.on_gui_switch_state_changed(event)
end)

-----------------------------------------------------------
-- BLUEPRINT/COPY-PASTE ROUTING
-----------------------------------------------------------

script.on_event(defines.events.on_player_setup_blueprint, function(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then return end

    -- Get the blueprint item stack
    local bp = player.blueprint_to_setup
    if not bp or not bp.valid_for_read then
        bp = player.cursor_stack
    end

    if not bp or not bp.valid_for_read then return end

    -- Get the entity mapping from the event
    local mapping = event.mapping
    if not mapping then return end

    -- Convert mapping to format expected by control module
    local entity_mapping = mapping.get()
    fc_control.on_player_setup_blueprint(bp, entity_mapping)
end)

script.on_event(defines.events.on_entity_settings_pasted, function(event)
    fc_control.on_entity_settings_pasted(event.source, event.destination)
end)

script.on_event(defines.events.on_entity_cloned, function(event)
    fc_control.on_entity_cloned(event.source, event.destination)
end)

-----------------------------------------------------------
-- PERIODIC UPDATES
-----------------------------------------------------------

-- Update every 2 ticks (~33ms) for signal processing
script.on_nth_tick(2, function(event)
    fc_control.on_tick_2()
end)

log("[filter-combinator] control.lua loaded")
