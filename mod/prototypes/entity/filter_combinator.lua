-- Filter Combinator Entity Prototype
-- A combinator that filters signals between red and green wires
-- Outputs either intersection or symmetric difference of signal IDs
-- Factorio 2.0 API

local flib_data_util = require("__flib__.data-util")

-- Copy arithmetic combinator as base (2x1 combinator with input/output terminals)
local filter_combinator = flib_data_util.copy_prototype(
    data.raw["arithmetic-combinator"]["arithmetic-combinator"],
    "filter-combinator"
)

-- Basic properties
filter_combinator.max_health = 150
filter_combinator.corpse = "arithmetic-combinator-remnants"
filter_combinator.dying_explosion = "arithmetic-combinator-explosion"

-- Energy configuration (1kW electric)
filter_combinator.energy_source = {
    type = "electric",
    usage_priority = "secondary-input"
}
filter_combinator.active_energy_usage = "1kW"

-- Minable configuration
filter_combinator.minable = {
    mining_time = 0.1,
    result = "filter-combinator"
}

-- Fast replaceable group
filter_combinator.fast_replaceable_group = "combinator"

-- Ensure proper flags for player interaction
filter_combinator.flags = {
    "placeable-player",
    "player-creation"
}

-- Custom sprites using mod graphics
-- The filter-combinator.png has 4 images (one for each rotation) in a horizontal strip
-- Format: 4 frames of 144x124 each (same as arithmetic combinator)
filter_combinator.sprites = make_4way_animation_from_spritesheet({
    layers = {
        {
            scale = 0.5,
            filename = "__lempi-filter-combinator__/graphics/filter-combinator.png",
            width = 156,
            height = 132,
            shift = util.by_pixel(0.5, 7.5)
        },
        {
            scale = 0.5,
            filename = "__base__/graphics/entity/combinator/decider-combinator-shadow.png",
            width = 156,
            height = 158,
            shift = util.by_pixel(12, 24),
            draw_as_shadow = true
        }
    }
})

-- Activity LED sprites (shows when combinator is processing)
filter_combinator.activity_led_sprites = {
    north = util.draw_as_glow {
        scale = 0.5,
        filename = "__base__/graphics/entity/combinator/activity-leds/decider-combinator-LED-N.png",
        width = 16,
        height = 14,
        shift = util.by_pixel(8.5, -13)
    },
    east = util.draw_as_glow {
        scale = 0.5,
        filename = "__base__/graphics/entity/combinator/activity-leds/decider-combinator-LED-E.png",
        width = 16,
        height = 16,
        shift = util.by_pixel(16, -4)
    },
    south = util.draw_as_glow {
        scale = 0.5,
        filename = "__base__/graphics/entity/combinator/activity-leds/decider-combinator-LED-S.png",
        width = 16,
        height = 14,
        shift = util.by_pixel(-8, 4.5)
    },
    west = util.draw_as_glow {
        scale = 0.5,
        filename = "__base__/graphics/entity/combinator/activity-leds/decider-combinator-LED-W.png",
        width = 16,
        height = 16,
        shift = util.by_pixel(-15, -18.5)
    }
}

-- Display sprites for mode indication
-- combinator-displays.png format: 30x22 per symbol, arranged in rows
-- Row 0 (y=0):  blank(0), intersection(30), difference(60), ...
-- We use:
--   x=0:  blank (no operation displayed)
--   x=30: intersection symbol
--   x=60: difference symbol (we'll use minus as placeholder)

-- Helper to create display sprite for all 4 directions
local function make_display_sprite(x_offset, y_offset)
    y_offset = y_offset or 0
    return {
        north = util.draw_as_glow {
            scale = 0.5,
            filename = "__lempi-filter-combinator__/graphics/combinator-displays.png",
            x = x_offset,
            y = y_offset,
            width = 30,
            height = 22,
            shift = util.by_pixel(0, -4.5)
        },
        east = util.draw_as_glow {
            scale = 0.5,
            filename = "__lempi-filter-combinator__/graphics/combinator-displays.png",
            x = x_offset,
            y = y_offset,
            width = 30,
            height = 22,
            shift = util.by_pixel(0, -13.5)
        },
        south = util.draw_as_glow {
            scale = 0.5,
            filename = "__lempi-filter-combinator__/graphics/combinator-displays.png",
            x = x_offset,
            y = y_offset,
            width = 30,
            height = 22,
            shift = util.by_pixel(0, -4.5)
        },
        west = util.draw_as_glow {
            scale = 0.5,
            filename = "__lempi-filter-combinator__/graphics/combinator-displays.png",
            x = x_offset,
            y = y_offset,
            width = 30,
            height = 22,
            shift = util.by_pixel(0, -13.5)
        }
    }
end

-- Arithmetic combinator symbol sprites (required by prototype)
-- We'll use these to show the current mode on the display
-- Index 0 = blank, 1 = intersection, 2 = difference
filter_combinator.plus_symbol_sprites = make_display_sprite(0)    -- blank (default/idle)
filter_combinator.minus_symbol_sprites = make_display_sprite(60, 0)  -- difference symbol
filter_combinator.multiply_symbol_sprites = make_display_sprite(30, 0)  -- intersection symbol
filter_combinator.divide_symbol_sprites = make_display_sprite(0)  -- unused
filter_combinator.modulo_symbol_sprites = make_display_sprite(0)  -- unused
filter_combinator.power_symbol_sprites = make_display_sprite(0)   -- unused
filter_combinator.left_shift_symbol_sprites = make_display_sprite(0)  -- unused
filter_combinator.right_shift_symbol_sprites = make_display_sprite(0) -- unused
filter_combinator.and_symbol_sprites = make_display_sprite(0)     -- unused
filter_combinator.or_symbol_sprites = make_display_sprite(0)      -- unused
filter_combinator.xor_symbol_sprites = make_display_sprite(0)     -- unused

-- GUI sounds
filter_combinator.open_sound = { filename = "__base__/sound/machine-open.ogg", volume = 0.85 }
filter_combinator.close_sound = { filename = "__base__/sound/machine-close.ogg", volume = 0.75 }

-- Register the entity
data:extend({filter_combinator})

log("[filter-combinator] prototypes/entity/filter_combinator.lua loaded")
