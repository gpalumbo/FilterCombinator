-- Filter Combinator GUI Module
-- Handles the custom GUI for filter combinator entities
-- Supports both ghost entities (via tags) and real entities (via storage)

local flib_gui = require("__flib__.gui")
local circuit_utils = require("lib.circuit_utils")
local gui_circuit_inputs = require("lib.gui.gui_circuit_inputs")
local gui_entity = require("lib.gui.gui_entity")
local entity_lib = require("lib.entity_lib")
local globals = require("scripts.globals")
local fc_storage = require("scripts.filter_combinator.storage")
local logic = require("scripts.filter_combinator.logic")

local gui = {}

-- Entity name constant
local FILTER_COMBINATOR = "filter-combinator"

-- GUI element names
local GUI_FRAME_NAME = "filter_combinator_gui"

--------------------------------------------------------------------------------
-- GUI Creation
--------------------------------------------------------------------------------

--- Create the GUI for a filter combinator
--- @param player LuaPlayer
--- @param entity LuaEntity The entity to create GUI for (can be ghost or real)
--- @return table|nil Table of created elements, or nil on failure
function gui.create_gui(player, entity)
    if not player or not player.valid then
        return nil
    end

    if not entity or not entity.valid then
        return nil
    end

    -- Close existing GUI if open
    gui.close_gui(player)

    local is_ghost = entity_lib.is_ghost(entity)

    -- Get current mode and match_quality setting
    local current_mode = fc_storage.get_mode(entity)
    local is_intersection = (current_mode == fc_storage.ModeType.INTER)
    local match_quality = fc_storage.get_match_quality(entity)

    -- Get power status for real entities
    local power_status = {sprite = "utility/bar_gray_pip", text = "Ghost"}
    if not is_ghost then
        power_status = gui_entity.get_power_status(entity)
    end

    -- Build GUI structure using flib
    local elems = flib_gui.add(player.gui.screen, {
        type = "frame",
        name = GUI_FRAME_NAME,
        direction = "vertical",
        tags = {
            entity_unit_number = entity.unit_number,
            entity_position = entity.position,
            entity_surface_index = entity.surface.index
        },
        children = {
            -- Titlebar
            {
                type = "flow",
                style = "flib_titlebar_flow",
                drag_target = GUI_FRAME_NAME,
                children = {
                    {
                        type = "label",
                        style = "frame_title",
                        caption = {"gui.filter-combinator-title"},
                        ignored_by_interaction = true
                    },
                    {type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true},
                    {
                        type = "sprite-button",
                        name = "filter_close_button",
                        style = "frame_action_button",
                        sprite = "utility/close",
                        hovered_sprite = "utility/close_black",
                        clicked_sprite = "utility/close_black",
                        tooltip = {"gui.filter-combinator-close"},
                        tags = {action = "close"}
                    }
                }
            },
            -- Content frame
            {
                type = "frame",
                style = "inside_shallow_frame_with_padding",
                direction = "vertical",
                children = {
                    -- Status indicator (for real entities only)
                    {
                        type = "flow",
                        direction = "horizontal",
                        style_mods = {
                            vertical_align = "center",
                            bottom_margin = 8
                        },
                        visible = not is_ghost,
                        children = {
                            {
                                type = "label",
                                caption = {"gui.filter-combinator-status"},
                                style_mods = {
                                    font = "default-semibold",
                                    right_margin = 8
                                }
                            },
                            {
                                type = "sprite",
                                name = "status_sprite",
                                sprite = power_status.sprite,
                                style_mods = {
                                    width = 16,
                                    height = 16,
                                    right_margin = 4
                                }
                            },
                            {
                                type = "label",
                                name = "status_label",
                                caption = power_status.text
                            }
                        }
                    },
                    -- Mode selection section
                    {
                        type = "flow",
                        direction = "vertical",
                        style_mods = {
                            bottom_margin = 12
                        },
                        children = {
                            {
                                type = "label",
                                caption = {"gui.filter-combinator-mode-header"},
                                style_mods = {
                                    font = "default-semibold",
                                    bottom_margin = 4
                                }
                            },
                            -- Mode switch
                            {
                                type = "flow",
                                direction = "horizontal",
                                style_mods = {
                                    vertical_align = "center"
                                },
                                children = {
                                    {
                                        type = "label",
                                        caption = {"gui.filter-combinator-mode-difference"}
                                    },
                                    {
                                        type = "switch",
                                        name = "mode_switch",
                                        switch_state = is_intersection and "right" or "left",
                                        left_label_caption = "",
                                        right_label_caption = "",
                                        tags = {action = "mode_switch"}
                                    },
                                    {
                                        type = "label",
                                        caption = {"gui.filter-combinator-mode-intersection"}
                                    },
                                    -- Match quality checkbox
                                    {
                                        type = "checkbox",
                                        name = "match_quality_checkbox",
                                        state = match_quality,
                                        caption = {"gui.filter-combinator-match-quality"},
                                        tooltip = {"gui.filter-combinator-match-quality-tooltip"},
                                        tags = {action = "match_quality_toggle"},
                                        style_mods = {
                                            left_margin = 30
                                        }
                                    }
                                }
                            },
                            -- Mode description
                            {
                                type = "label",
                                name = "mode_description",
                                caption = is_intersection
                                    and {"gui.filter-combinator-mode-intersection-desc"}
                                    or {"gui.filter-combinator-mode-difference-desc"},
                                style_mods = {
                                    font_color = {r = 0.7, g = 0.7, b = 0.7},
                                    single_line = false,
                                    maximal_width = 300,
                                    top_margin = 4
                                }
                            },

                        }
                    },
                    -- Signal grids section (only for real entities with connections)
                    {
                        type = "flow",
                        name = "signal_section",
                        direction = "vertical",
                        visible = not is_ghost,
                        children = {
                            -- Input signals
                            {
                                type = "frame",
                                name = "input_signals_frame",
                                direction = "vertical",
                                style = "inside_shallow_frame",
                                style_mods = {
                                    padding = 8,
                                    top_margin = 4
                                },
                                children = {
                                    {
                                        type = "label",
                                        caption = {"gui.filter-combinator-input-signals"},
                                        style_mods = {
                                            font = "default-semibold",
                                            bottom_margin = 4
                                        }
                                    }
                                }
                            },
                            -- Output signals
                            {
                                type = "frame",
                                name = "output_signals_frame",
                                direction = "vertical",
                                style = "inside_shallow_frame",
                                style_mods = {
                                    padding = 8,
                                    top_margin = 8
                                },
                                children = {
                                    {
                                        type = "label",
                                        caption = {"gui.filter-combinator-output-signals"},
                                        style_mods = {
                                            font = "default-semibold",
                                            bottom_margin = 4
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    })

    -- Add signal grids for real entities
    if not is_ghost then
        -- Get input signals
        local input_signals = circuit_utils.get_input_signals_raw(entity)

        -- Create input signal grids
        if elems.input_signals_frame then
            local has_red = input_signals.red and #input_signals.red > 0
            local has_green = input_signals.green and #input_signals.green > 0

            if has_red then
                gui_circuit_inputs.create_signal_sub_grid(elems.input_signals_frame, input_signals.red, "red", "input_red_grid")
            end

            if has_green then
                gui_circuit_inputs.create_signal_sub_grid(elems.input_signals_frame, input_signals.green, "green", "input_green_grid")
            end

            if not has_red and not has_green then
                elems.input_signals_frame.add{
                    type = "label",
                    caption = {"gui.filter-combinator-no-signals"},
                    style_mods = {
                        font_color = {r = 0.6, g = 0.6, b = 0.6}
                    }
                }
            end
        end

        -- Get output signals (computed by logic)
        local output_signals = logic.get_output_signals(entity)

        -- Create output signal grids
        if elems.output_signals_frame then
            local has_red_out = output_signals.red and #output_signals.red > 0
            local has_green_out = output_signals.green and #output_signals.green > 0

            if has_red_out then
                gui_circuit_inputs.create_signal_sub_grid(elems.output_signals_frame, output_signals.red, "red", "output_red_grid")
            end

            if has_green_out then
                gui_circuit_inputs.create_signal_sub_grid(elems.output_signals_frame, output_signals.green, "green", "output_green_grid")
            end

            if not has_red_out and not has_green_out then
                elems.output_signals_frame.add{
                    type = "label",
                    caption = {"gui.filter-combinator-no-output"},
                    style_mods = {
                        font_color = {r = 0.6, g = 0.6, b = 0.6}
                    }
                }
            end
        end
    end

    -- Center the GUI
    if elems[GUI_FRAME_NAME] then
        elems[GUI_FRAME_NAME].force_auto_center()
    end

    -- Make the GUI respond to ESC key
    player.opened = elems[GUI_FRAME_NAME]

    -- Store GUI state
    globals.set_player_gui_entity(player.index, entity, "filter_combinator")

    return elems
end

--- Close the GUI for a player
--- @param player LuaPlayer
function gui.close_gui(player)
    if not player or not player.valid then
        return
    end

    local frame = player.gui.screen[GUI_FRAME_NAME]
    if frame and frame.valid then
        frame.destroy()
    end

    -- Clear the opened GUI reference
    if player.opened and player.opened.name == GUI_FRAME_NAME then
        player.opened = nil
    end

    -- Clear player GUI state
    globals.clear_player_gui_entity(player.index)
end

--------------------------------------------------------------------------------
-- GUI Helper Functions
--------------------------------------------------------------------------------

--- Get entity from GUI tags
--- @param frame LuaGuiElement The GUI frame
--- @return LuaEntity|nil The entity, or nil if not found/invalid
local function get_entity_from_gui(frame)
    if not frame or not frame.valid or not frame.tags then
        return nil
    end

    local tags = frame.tags
    local surface_index = tags.entity_surface_index
    local position = tags.entity_position

    if not surface_index or not position then
        return nil
    end

    local surface = game.surfaces[surface_index]
    if not surface then
        return nil
    end

    -- Find entity at position
    local entities = surface.find_entities_filtered{
        position = position,
        radius = 0.5,
        name = {FILTER_COMBINATOR, "entity-ghost"}
    }

    for _, entity in ipairs(entities) do
        if entity_lib.is_type(entity, FILTER_COMBINATOR) then
            return entity
        end
    end

    return nil
end

--------------------------------------------------------------------------------
-- GUI Event Handlers
--------------------------------------------------------------------------------

--- Handle GUI click events
--- @param event EventData.on_gui_click
function gui.on_gui_click(event)
    local element = event.element
    if not element or not element.valid then return end

    local tags = element.tags
    if not tags or not tags.action then return end

    local player = game.get_player(event.player_index)
    if not player then return end

    local action = tags.action

    if action == "close" then
        gui.close_gui(player)
    end
end

--- Handle switch state changed events
--- @param event EventData.on_gui_switch_state_changed
function gui.on_gui_switch_state_changed(event)
    local element = event.element
    if not element or not element.valid then return end

    local tags = element.tags
    if not tags or tags.action ~= "mode_switch" then return end

    local player = game.get_player(event.player_index)
    if not player then return end

    -- Find the GUI frame
    local frame = player.gui.screen[GUI_FRAME_NAME]
    if not frame or not frame.valid then return end

    -- Get entity
    local entity = get_entity_from_gui(frame)
    if not entity or not entity.valid then
        gui.close_gui(player)
        return
    end

    -- Determine new mode based on switch state
    local new_mode = (element.switch_state == "right") and fc_storage.ModeType.INTER or fc_storage.ModeType.DIFF

    -- Update entity mode
    fc_storage.set_mode(entity, new_mode)

    -- Recreate GUI to reflect changes
    gui.create_gui(player, entity)
end

--- Handle checkbox state changed events
--- @param event EventData.on_gui_checked_state_changed
function gui.on_gui_checked_state_changed(event)
    local element = event.element
    if not element or not element.valid then return end

    local tags = element.tags
    if not tags or tags.action ~= "match_quality_toggle" then return end

    local player = game.get_player(event.player_index)
    if not player then return end

    -- Find the GUI frame
    local frame = player.gui.screen[GUI_FRAME_NAME]
    if not frame or not frame.valid then return end

    -- Get entity
    local entity = get_entity_from_gui(frame)
    if not entity or not entity.valid then
        gui.close_gui(player)
        return
    end

    -- Update match_quality setting
    fc_storage.set_match_quality(entity, element.state)

    -- Recreate GUI to reflect changes in output signals
    gui.create_gui(player, entity)
end

--- Handle GUI opened event
--- @param event EventData.on_gui_opened
function gui.on_gui_opened(event)
    local entity = event.entity
    if not entity or not entity.valid then return end
    if not entity_lib.is_type(entity, FILTER_COMBINATOR) then return end

    local player = game.get_player(event.player_index)
    if not player then return end

    -- Close the default entity GUI that Factorio opened
    if player.opened == entity then
        player.opened = nil
    end

    -- Create our custom GUI
    gui.create_gui(player, entity)
end

--- Handle GUI closed event
--- @param event EventData.on_gui_closed
function gui.on_gui_closed(event)
    local element = event.element
    if not element or not element.valid then return end

    -- Check if this is our GUI
    if element.name ~= GUI_FRAME_NAME then return end

    local player = game.get_player(event.player_index)
    if not player then return end

    gui.close_gui(player)
end

return gui
