-- Filter Combinator Logic Module
-- Handles signal filtering operations for filter combinators
--
-- Signal Processing:
-- - Difference mode: Output signals unique to each wire (preserves counts by wire)
-- - Intersection mode: Output signals present on both wires (preserves counts by wire)
--
-- IMPORTANT: Wire separation is preserved! Red signals stay on red output,
-- green signals stay on green output. Only signal IDs are compared.

local circuit_utils = require("lib.circuit_utils")
local entity_lib = require("lib.entity_lib")
local fc_storage = require("scripts.filter_combinator.storage")

local logic = {}

--------------------------------------------------------------------------------
-- Signal ID Set Operations
--------------------------------------------------------------------------------

--- Build a set of signal IDs from a signals array
--- @param signals table Array of {signal = SignalID, count = number}
--- @return table Set of signal keys for fast lookup
local function build_signal_id_set(signals)
    local id_set = {}
    if not signals then return id_set end

    for _, signal_data in ipairs(signals) do
        if signal_data.signal then
            -- Create unique key from type:name
            local key = (signal_data.signal.type or "item") .. ":" .. signal_data.signal.name
            -- Store the full signal_data (not just `true`) so callers can access count/metadata
            id_set[key] = signal_data
        end
    end

    return id_set
end

--- Check if a signal ID is in a set
--- @param signal SignalID The signal to check
--- @param id_set table Set of signal keys
--- @return boolean True if signal is in set
local function signal_in_set(signal, id_set)
    if not signal or not id_set then return false end
    local key = (signal.type or "item") .. ":" .. signal.name
    -- check presence (non-nil)
    return id_set[key] ~= nil
end

--------------------------------------------------------------------------------
-- Filtering Operations
--------------------------------------------------------------------------------

--- Compute difference: signals unique to source (not in other)
--- @param source_signals table Array of {signal = SignalID, count = number}
--- @param other_signals table Array of {signal = SignalID, count = number}
--- @return table Array of signals from source that are NOT in other
local function compute_difference(source_signals, other_signals)
    local result = {}

    if not source_signals then return result end

    -- Build set of signal IDs from the other wire
    local other_ids = build_signal_id_set(other_signals)

    -- Filter source signals: keep only those NOT in other
    for _, signal_data in ipairs(source_signals) do
        if signal_data.signal and not signal_in_set(signal_data.signal, other_ids) then
            table.insert(result, signal_data)
        end
    end

    return result
end


--- Compute intersection for both wires in a single pass
--- @param red_signals table Array of {signal = SignalID, count = number}
--- @param green_signals table Array of {signal = SignalID, count = number}
--- @return table red_out Array of signals from red that are also in green (with red counts)
--- @return table green_out Array of signals from green that are also in red (with green counts)
local function compute_intersection(red_signals, green_signals)
    local red_result = {}
    local green_result = {}

    if not red_signals or not green_signals then
        return red_result, green_result
    end

    -- Build set of green signal IDs mapping to their signal_data
    local green_ids = build_signal_id_set(green_signals)

    -- Iterate red signals once; when a match is found add to both outputs
    for _, r in ipairs(red_signals) do
        if r.signal then
            local key = (r.signal.type or "item") .. ":" .. r.signal.name
            local g = green_ids[key]
            if g then
                -- Insert original signal_data objects directly to avoid extra allocations
                table.insert(red_result, r)
                table.insert(green_result, g)
            end
        end
    end

    return red_result, green_result
end

--------------------------------------------------------------------------------
-- Output Signal Writing
--------------------------------------------------------------------------------

--- Write signals to a hidden constant combinator using Factorio 2.0 LuaLogisticSection API
--- @param output_combinator LuaEntity The hidden constant combinator
--- @param signals table Array of {signal = SignalID, count = number}
local function write_signals_to_combinator(output_combinator, signals)
    if not output_combinator or not output_combinator.valid then
        return
    end

    local behavior = output_combinator.get_or_create_control_behavior()
    if not behavior then
        return
    end

    -- Get or create a section for our signals
    local section = behavior.get_section(1)
    if not section then
        section = behavior.add_section()
    end

    if not section then
        return
    end

    -- Clear existing slots first by setting empty values
    -- We need to track which slots are in use
    local slot_index = 1

    -- Write each signal to a slot
    for _, signal_data in ipairs(signals) do
        if signal_data.signal and signal_data.count then
            -- Factorio 2.0 requires quality field on SignalID
            signal_data.signal.quality = signal_data.signal.quality or "normal"
            section.set_slot(slot_index, {
                value = signal_data.signal,
                min = signal_data.count
            })
            slot_index = slot_index + 1
        end
    end

    -- Clear any remaining slots that may have old signals
    -- Section slots go up to the section's slot count
    local max_slots = section.filters_count or 0
    for i = slot_index, max_slots do
        section.clear_slot(i)
    end
end

--- Clear all signals from a hidden constant combinator
--- @param output_combinator LuaEntity The hidden constant combinator
local function clear_combinator_signals(output_combinator)
    if not output_combinator or not output_combinator.valid then
        return
    end

    local behavior = output_combinator.get_or_create_control_behavior()
    if not behavior then
        return
    end

    local section = behavior.get_section(1)
    if not section then
        return
    end

    -- Clear all slots
    local max_slots = section.filters_count or 0
    for i = 1, max_slots do
        section.clear_slot(i)
    end
end

--------------------------------------------------------------------------------
-- Main Processing
--------------------------------------------------------------------------------

--- Process a filter combinator and output filtered signals
--- Returns empty outputs if entity has no power
--- @param entity LuaEntity The combinator entity
--- @param mode string 'diff' for difference, 'inter' for intersection
--- @return table {red_out = signals, green_out = signals} or nil if invalid
function logic.process_filter(entity, mode)
    if not entity or not entity.valid then
        return nil
    end

    -- Check power - no power means no output
    if not entity_lib.has_power(entity) then
        return {
            red_out = {},
            green_out = {}
        }
    end

    -- Get input signals from both wires
    local input_signals = circuit_utils.get_input_signals_raw(entity)
    local red_in = input_signals.red or {}
    local green_in = input_signals.green or {}

    local red_out = {}
    local green_out = {}

    if mode == fc_storage.ModeType.INTER then
        -- Intersection mode: compute both red and green outputs in one pass
        red_out, green_out = compute_intersection(red_in, green_in)
    else
        -- Difference mode (default): signals unique to each wire
        -- Red out: red signals whose IDs are NOT on green
        -- Green out: green signals whose IDs are NOT on red
        red_out = compute_difference(red_in, green_in)
        green_out = compute_difference(green_in, red_in)
    end

    return {
        red_out = red_out,
        green_out = green_out
    }
end

--- Get output signals for GUI display
--- @param entity LuaEntity The combinator entity
--- @return table {red = signals, green = signals}
function logic.get_output_signals(entity)
    if not entity or not entity.valid then
        return {red = {}, green = {}}
    end

    local mode = fc_storage.get_mode(entity)
    local result = logic.process_filter(entity, mode)

    if result then
        return {
            red = result.red_out,
            green = result.green_out
        }
    end

    return {red = {}, green = {}}
end

--- Process all registered filter combinators
--- Called every N ticks to update outputs
--- Writes filtered signals to hidden output combinators
function logic.process_all_combinators()
    if not storage.filter_combinators then
        return
    end

    for unit_number, data in pairs(storage.filter_combinators) do
        local entity = data.entity

        if entity and entity.valid then
            local mode = data.mode or fc_storage.ModeType.DIFF

            -- Get filtered signals
            local result = logic.process_filter(entity, mode)

            if result then
                -- Get hidden output combinators
                local output_red = data.output_red
                local output_green = data.output_green

                -- Write red signals to red output combinator
                if output_red and output_red.valid then
                    if #result.red_out > 0 then
                        write_signals_to_combinator(output_red, result.red_out)
                    else
                        clear_combinator_signals(output_red)
                    end
                end

                -- Write green signals to green output combinator
                if output_green and output_green.valid then
                    if #result.green_out > 0 then
                        write_signals_to_combinator(output_green, result.green_out)
                    else
                        clear_combinator_signals(output_green)
                    end
                end

                -- Store computed results in storage for GUI display
                data.last_red_out = result.red_out
                data.last_green_out = result.green_out
                data.has_output = true
            end
        else
            -- Entity became invalid, clean up (including output combinators)
            if data.output_red and data.output_red.valid then
                data.output_red.destroy({raise_destroy = false})
            end
            if data.output_green and data.output_green.valid then
                data.output_green.destroy({raise_destroy = false})
            end
            storage.filter_combinators[unit_number] = nil
        end
    end
end

return logic
