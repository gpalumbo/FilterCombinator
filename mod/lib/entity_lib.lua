-- Entity Utilities Library
-- Common entity helper functions used across the mod
-- IMPORTANT: Stateless utility functions only - no storage access

local entity_lib = {}

-----------------------------------------------------------
-- ENTITY NAME UTILITIES
-----------------------------------------------------------

--- Get the effective name of an entity, handling ghosts
--- For ghosts, returns ghost_name; for real entities, returns name
--- @param entity LuaEntity The entity to get the name of
--- @return string|nil The effective entity name, or nil if entity is invalid
function entity_lib.get_name(entity)
    if not entity or not entity.valid then
        return nil
    end

    if entity.type == "entity-ghost" then
        return entity.ghost_name
    end

    return entity.name
end

--- Check if an entity (or ghost) matches a specific entity name
--- @param entity LuaEntity The entity to check
--- @param name string The entity name to match against
--- @return boolean True if entity matches the name (handles ghosts)
function entity_lib.is_type(entity, name)
    if not entity or not entity.valid then
        return false
    end

    if entity.name == name then
        return true
    end

    if entity.type == "entity-ghost" and entity.ghost_name == name then
        return true
    end

    return false
end

--- Check if an entity is a ghost
--- @param entity LuaEntity The entity to check
--- @return boolean True if entity is a ghost
function entity_lib.is_ghost(entity)
    if not entity or not entity.valid then
        return false
    end

    return entity.type == "entity-ghost"
end

-----------------------------------------------------------
-- POWER UTILITIES
-----------------------------------------------------------

--- Check if entity has sufficient power to operate
--- @param entity LuaEntity The entity to check
--- @return boolean True if entity has power and is working
function entity_lib.has_power(entity)
    if not entity or not entity.valid then
        return false
    end

    -- Ghosts don't have power requirements
    if entity.type == "entity-ghost" then
        return false
    end

    -- Check entity status - most reliable way to determine if working
    local status = entity.status
    if status then
        -- Entity is working if status is 'working' or 'low_power' (still functional)
        if status == defines.entity_status.working then
            return true
        end
        if status == defines.entity_status.low_power then
            return true  -- Low power but still functional
        end
        -- Any other status means not working (no_power, disabled, etc.)
        return false
    end

    -- Fallback: check energy directly
    if entity.energy and entity.energy > 0 then
        return true
    end

    return false
end

-----------------------------------------------------------
-- MODULE EXPORTS
-----------------------------------------------------------

return entity_lib