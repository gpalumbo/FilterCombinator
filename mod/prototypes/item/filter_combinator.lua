-- Filter Combinator Item Prototype
-- Factorio 2.0 API

local filter_combinator_item = {
    type = "item",
    name = "filter-combinator",

    -- Icon with mipmaps (4 sizes in filter-combinator-icon.png)
    -- Standard Factorio icon sizes: 64, 32, 16, 8 (or 64, 48, 32, 16)
    icon = "__filter-combinator__/graphics/filter-combinator-icon.png",
    icon_size = 64,
    icon_mipmaps = 4,

    -- Placement links item to entity
    place_result = "filter-combinator",

    -- Inventory settings
    stack_size = 50,

    -- Category in crafting menu (same as other combinators)
    subgroup = "circuit-network",
    order = "c[combinators]-e[filter-combinator]",

    -- Rocket capacity (for space logistics)
    weight = 2000,  -- 2kg, same as arithmetic combinator
}

data:extend({filter_combinator_item})

log("[filter-combinator] prototypes/item/filter_combinator.lua loaded")
