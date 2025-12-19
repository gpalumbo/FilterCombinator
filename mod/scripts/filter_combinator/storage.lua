-- Filter Combinator Storage Module
-- Entity-specific storage management for filter combinators
-- CRITICAL: Uses Factorio 2.0 APIs - storage NOT global!
--
-- Storage Structure:
-- storage.filter_combinators = {
--     [unit_number] = {
--         entity = entity_reference,
--         mode = 'diff' | 'inter',  -- Default: 'diff'
--         match_quality = boolean,  -- Default: true (match quality when filtering)
--         output_red = entity_reference,   -- Hidden constant combinator for red output
--         output_green = entity_reference  -- Hidden constant combinator for green output
--     }
-- }
--
-- Ghost Tags Structure:
-- {
--     filter_combinator_config = {
--         mode = 'diff' | 'inter',
--         match_quality = boolean
--     }
-- }

local entity_lib = require("lib.entity_lib")

local fc_storage = {}

-- Entity name constant
local FILTER_COMBINATOR = "filter-combinator"

-- Mode enum (use these constants throughout the codebase)
local ModeType = {
    DIFF = "diff",
    INTER = "inter"
}
fc_storage.ModeType = ModeType

-- Default mode
local DEFAULT_MODE = ModeType.DIFF

-- Default match quality setting (true = match quality when filtering)
local DEFAULT_MATCH_QUALITY = true

--------------------------------------------------------------------------------
-- Storage Initialization
--------------------------------------------------------------------------------

--- Initialize filter combinator storage table
--- Called during on_init and on_configuration_changed events
function fc_storage.init_storage()
    storage.filter_combinators = storage.filter_combinators or {}
end

--------------------------------------------------------------------------------
-- Entity Registration
--------------------------------------------------------------------------------

--- Register a filter combinator entity in storage
--- CRITICAL: Only register real entities, NEVER ghosts!
--- @param entity LuaEntity The combinator entity to register
--- @param output_red LuaEntity|nil Hidden constant combinator for red output
--- @param output_green LuaEntity|nil Hidden constant combinator for green output
--- @return table|nil The created data table, or nil if registration failed
function fc_storage.register(entity, output_red, output_green)
    if not entity or not entity.valid then
        return nil
    end

    if entity_lib.is_ghost(entity) then
        -- Ghosts use entity.tags, not storage
        return nil
    end

    if not entity_lib.is_type(entity, FILTER_COMBINATOR) then
        return nil
    end

    local unit_number = entity.unit_number
    if not unit_number then
        return nil
    end

    -- Initialize storage if needed
    if not storage.filter_combinators then
        fc_storage.init_storage()
    end

    -- Create data structure with default mode and output combinator references
    local data = {
        entity = entity,
        mode = DEFAULT_MODE,
        match_quality = DEFAULT_MATCH_QUALITY,
        output_red = output_red,
        output_green = output_green
    }

    storage.filter_combinators[unit_number] = data
    return data
end

--- Unregister a filter combinator from storage
--- Called when entity is destroyed/removed
--- Returns the output combinator references so they can be destroyed by the caller
--- @param unit_number number The unit_number of the entity to unregister
--- @return LuaEntity|nil output_red The red output combinator (or nil)
--- @return LuaEntity|nil output_green The green output combinator (or nil)
function fc_storage.unregister(unit_number)
    if not unit_number then
        return nil, nil
    end

    if not storage.filter_combinators then
        return nil, nil
    end

    local data = storage.filter_combinators[unit_number]
    if not data then
        return nil, nil
    end

    -- Capture output combinator references before removing
    local output_red = data.output_red
    local output_green = data.output_green

    -- Remove from storage
    storage.filter_combinators[unit_number] = nil

    return output_red, output_green
end

--- Get the output combinators for a filter combinator
--- @param entity_or_unit_number LuaEntity|number Entity reference or unit_number
--- @return LuaEntity|nil output_red The red output combinator (or nil)
--- @return LuaEntity|nil output_green The green output combinator (or nil)
function fc_storage.get_output_combinators(entity_or_unit_number)
    local data = fc_storage.get_data(entity_or_unit_number)
    if not data then
        return nil, nil
    end
    return data.output_red, data.output_green
end

--- Set the output combinators for a filter combinator
--- Used when creating output combinators after initial registration
--- @param entity LuaEntity The filter combinator entity
--- @param output_red LuaEntity The red output combinator
--- @param output_green LuaEntity The green output combinator
function fc_storage.set_output_combinators(entity, output_red, output_green)
    if not entity or not entity.valid then
        return
    end

    local unit_number = entity.unit_number
    if not unit_number then
        return
    end

    if not storage.filter_combinators then
        return
    end

    local data = storage.filter_combinators[unit_number]
    if not data then
        return
    end

    data.output_red = output_red
    data.output_green = output_green
end

--------------------------------------------------------------------------------
-- Data Access Functions (Universal - Ghost/Real Transparent)
--------------------------------------------------------------------------------

--- Get filter combinator data from storage or ghost tags
--- Handles both entity references and unit_numbers
--- CRITICAL: Ghosts read from entity.tags, real entities from storage
--- @param entity_or_unit_number LuaEntity|number Entity reference or unit_number
--- @return table|nil The entity data, or nil if not found
function fc_storage.get_data(entity_or_unit_number)
    -- Handle nil input
    if not entity_or_unit_number then
        return nil
    end

    -- Determine if we have an entity or a unit_number
    local entity = nil
    local unit_number = nil

    if type(entity_or_unit_number) == "number" then
        unit_number = entity_or_unit_number
    else
        entity = entity_or_unit_number
        if not entity.valid then
            return nil
        end
        unit_number = entity.unit_number
    end

    -- Handle ghost entities - read from tags
    if entity and entity_lib.is_ghost(entity) then
        return fc_storage.get_ghost_config(entity)
    end

    -- Handle real entities - read from storage
    if not storage.filter_combinators then
        return nil
    end

    return storage.filter_combinators[unit_number]
end

--- Update filter combinator data (works for both ghosts and real entities)
--- For ghosts: updates entity.tags
--- For real entities: updates storage entry
--- @param entity LuaEntity The entity to update (can be ghost or real)
--- @param data table The data to set/merge
function fc_storage.update_data(entity, data)
    if not entity or not entity.valid then
        return
    end

    if not data then
        return
    end

    -- Handle ghost entities
    if entity_lib.is_ghost(entity) then
        -- Get existing config and merge
        local existing_config = fc_storage.get_ghost_config(entity) or {mode = DEFAULT_MODE}
        for key, value in pairs(data) do
            existing_config[key] = value
        end
        fc_storage.save_ghost_config(entity, existing_config)
        return
    end

    -- Handle real entities
    local unit_number = entity.unit_number
    if not unit_number then
        return
    end

    if not storage.filter_combinators then
        fc_storage.init_storage()
    end

    -- Get existing data or create new entry
    local existing_data = storage.filter_combinators[unit_number]
    if not existing_data then
        existing_data = fc_storage.register(entity)
    end

    -- Merge data (preserve entity reference)
    if existing_data then
        for key, value in pairs(data) do
            if key ~= "entity" then  -- Never overwrite entity reference
                existing_data[key] = value
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Blueprint/Copy-Paste Support
--------------------------------------------------------------------------------

--- Serialize filter combinator configuration for blueprints
--- Works for both ghost and real entities
--- @param entity LuaEntity The entity to serialize (can be ghost or real)
--- @return table|nil Blueprint-compatible configuration table
function fc_storage.serialize_config(entity)
    if not entity or not entity.valid then
        return nil
    end

    local data = fc_storage.get_data(entity)
    if not data then
        -- Return default config
        return {
            mode = DEFAULT_MODE,
            match_quality = DEFAULT_MATCH_QUALITY
        }
    end

    return {
        mode = data.mode or DEFAULT_MODE,
        match_quality = (data.match_quality ~= nil) and data.match_quality or DEFAULT_MATCH_QUALITY
    }
end

--- Restore filter combinator configuration from blueprint
--- Applies configuration to a newly built entity
--- @param entity LuaEntity The entity to configure
--- @param config table Blueprint configuration table
function fc_storage.restore_config(entity, config)
    if not entity or not entity.valid then
        return
    end

    if not config then
        return
    end

    -- Handle ghost entities
    if entity_lib.is_ghost(entity) then
        fc_storage.save_ghost_config(entity, config)
        return
    end

    -- Handle real entities
    local unit_number = entity.unit_number
    if not unit_number then
        return
    end

    -- Get or create data entry
    local data = storage.filter_combinators and storage.filter_combinators[unit_number]
    if not data then
        data = fc_storage.register(entity)
    end

    if not data then
        return
    end

    -- Restore mode and match_quality
    data.mode = config.mode or DEFAULT_MODE
    data.match_quality = (config.match_quality ~= nil) and config.match_quality or DEFAULT_MATCH_QUALITY

    -- Sync display sprite to match restored mode
    fc_storage.sync_display_to_mode(entity)
end

--------------------------------------------------------------------------------
-- Ghost Entity Support
--------------------------------------------------------------------------------

--- Get configuration from ghost entity tags
--- Ghosts store their configuration in entity.tags, NOT in storage
--- @param ghost_entity LuaEntity The ghost entity
--- @return table|nil Configuration data
function fc_storage.get_ghost_config(ghost_entity)
    if not ghost_entity or not ghost_entity.valid then
        return nil
    end

    if not entity_lib.is_ghost(ghost_entity) then
        return nil
    end

    if not entity_lib.is_type(ghost_entity, FILTER_COMBINATOR) then
        return nil
    end

    local tags = ghost_entity.tags
    if not tags or not tags.filter_combinator_config then
        -- Return default config
        return {
            mode = DEFAULT_MODE,
            match_quality = DEFAULT_MATCH_QUALITY
        }
    end

    return tags.filter_combinator_config
end

--- Save configuration to ghost entity tags
--- CRITICAL: Use complete table replacement pattern for tags
--- @param ghost_entity LuaEntity The ghost entity
--- @param config table Configuration to save
function fc_storage.save_ghost_config(ghost_entity, config)
    if not ghost_entity or not ghost_entity.valid then
        return
    end

    if not entity_lib.is_ghost(ghost_entity) then
        return
    end

    if not entity_lib.is_type(ghost_entity, FILTER_COMBINATOR) then
        return
    end

    -- Ensure config has required fields
    config = config or {}
    config.mode = config.mode or DEFAULT_MODE
    if config.match_quality == nil then
        config.match_quality = DEFAULT_MATCH_QUALITY
    end

    -- Use complete table replacement pattern for ghost tags
    local new_tags = ghost_entity.tags or {}
    new_tags.filter_combinator_config = config
    ghost_entity.tags = new_tags
end

--------------------------------------------------------------------------------
-- Mode-Specific Functions
--------------------------------------------------------------------------------

--- Get the current mode for an entity (universal - ghost/real)
--- @param entity LuaEntity The entity
--- @return string 'diff' or 'inter'
function fc_storage.get_mode(entity)
    local data = fc_storage.get_data(entity)
    if data and data.mode then
        return data.mode
    end
    return DEFAULT_MODE
end

--- Sync the entity's display sprite to match its current mode
--- Updates the arithmetic combinator operation to show the correct symbol:
---   minus_symbol_sprites = difference mode
---   multiply_symbol_sprites = intersection mode
--- Call this after any operation that might change mode or create/restore an entity
--- @param entity LuaEntity The entity to sync (must be valid, non-ghost)
function fc_storage.sync_display_to_mode(entity)
    if not entity or not entity.valid then
        return
    end

    -- Ghosts don't have control behaviors - skip them
    if entity_lib.is_ghost(entity) then
        return
    end

    local mode = fc_storage.get_mode(entity)
    local control = entity.get_or_create_control_behavior()
    if control then
        local params = control.parameters or {}
        -- Use "-" for difference mode, "*" for intersection mode
        params.operation = (mode == ModeType.INTER) and "*" or "-"
        control.parameters = params
    end
end

--- Set the mode for an entity (universal - ghost/real)
--- Also syncs the display sprite for real entities
--- @param entity LuaEntity The entity
--- @param mode string 'diff' or 'inter'
function fc_storage.set_mode(entity, mode)
    if mode ~= ModeType.DIFF and mode ~= ModeType.INTER then
        mode = DEFAULT_MODE
    end
    fc_storage.update_data(entity, {mode = mode})

    -- Sync display for real entities
    fc_storage.sync_display_to_mode(entity)
end

--- Get the match_quality setting for an entity (universal - ghost/real)
--- @param entity LuaEntity The entity
--- @return boolean true if quality should be matched, false otherwise
function fc_storage.get_match_quality(entity)
    local data = fc_storage.get_data(entity)
    if data and data.match_quality ~= nil then
        return data.match_quality
    end
    return DEFAULT_MATCH_QUALITY
end

--- Set the match_quality setting for an entity (universal - ghost/real)
--- @param entity LuaEntity The entity
--- @param match_quality boolean true to match quality, false to ignore quality
function fc_storage.set_match_quality(entity, match_quality)
    if match_quality == nil then
        match_quality = DEFAULT_MATCH_QUALITY
    end
    fc_storage.update_data(entity, {match_quality = match_quality})
end

--------------------------------------------------------------------------------
-- Cleanup Functions
--------------------------------------------------------------------------------

--- Validate and clean up invalid entities from storage
--- Also destroys any orphaned output combinators and syncs display sprites
--- Should be called periodically or on load to ensure storage integrity
function fc_storage.validate_and_cleanup()
    if not storage.filter_combinators then
        return
    end

    local invalid_units = {}

    -- Find invalid entities and collect their output combinators
    -- Also sync display sprites for valid entities (migration/load fix)
    for unit_number, data in pairs(storage.filter_combinators) do
        if not data.entity or not data.entity.valid then
            table.insert(invalid_units, unit_number)
            -- Destroy orphaned output combinators
            if data.output_red and data.output_red.valid then
                data.output_red.destroy({raise_destroy = false})
            end
            if data.output_green and data.output_green.valid then
                data.output_green.destroy({raise_destroy = false})
            end
        else
            -- Valid entity - ensure display sprite matches mode
            fc_storage.sync_display_to_mode(data.entity)
        end
    end

    -- Remove invalid entries
    for _, unit_number in ipairs(invalid_units) do
        storage.filter_combinators[unit_number] = nil
    end
end

return fc_storage
