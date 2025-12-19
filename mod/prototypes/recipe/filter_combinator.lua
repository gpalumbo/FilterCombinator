-- Filter Combinator Recipe Prototype
-- Factorio 2.0 API

local filter_combinator_recipe = {
    type = "recipe",
    name = "filter-combinator",

    -- Unlocked via technology
    enabled = false,

    -- Ingredients: 5x electronic circuits, 5x advanced circuits
    ingredients = {
        {type = "item", name = "electronic-circuit", amount = 5},
        {type = "item", name = "advanced-circuit", amount = 5}
    },

    -- Output
    results = {
        {type = "item", name = "filter-combinator", amount = 1}
    },

    -- Crafting time (slightly longer than basic combinators due to advanced circuits)
    energy_required = 1,

    -- Category
    category = "crafting"
}

data:extend({filter_combinator_recipe})

log("[filter-combinator] prototypes/recipe/filter_combinator.lua loaded")
