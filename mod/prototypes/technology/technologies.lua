-- Technology Definitions for Filter Combinator Mod
-- Defines all technologies and their unlocks for the filter combinator
--
-- Factorio 2.0 API Reference: https://lua-api.factorio.com/latest/prototypes/TechnologyPrototype.html

data:extend({
    {
        -- Technology type identifier (Factorio 2.0 prototype type)
        type = "technology",

        -- Internal name used for references and prerequisites
        name = "filter-combinator",

        -- Technology icon displayed in the research queue
        -- Using the filter combinator icon
        icon = "__lempi-filter-combinator__/graphics/filter-combinator-icon.png",
        icon_size = 64,

        -- Technologies that must be researched before this one becomes available
        -- space-science-pack: Ensures player has reached space platform stage
        -- logistic-system: Ensures player has basic logistics infrastructure
        prerequisites = {
            "space-science-pack",
            "logistic-system"
        },

        -- Research cost configuration
        unit = {
            -- 100 research cycles as per spec
            count = 100,

            -- Science packs required per research cycle
            -- Each cycle consumes 1 of each pack listed below
            ingredients = {
                {"automation-science-pack", 1},
                {"logistic-science-pack", 1},
                {"military-science-pack", 1},
                {"chemical-science-pack", 1},
                {"production-science-pack", 1},
                {"utility-science-pack", 1},
                {"space-science-pack", 1}
            },

            -- Time in ticks for each research cycle (60 ticks = 1 second)
            time = 60
        },

        -- Effects applied when technology is researched
        effects = {
            {
                type = "unlock-recipe",
                recipe = "filter-combinator"
            }
        }
    }
})

log("[filter-combinator] prototypes/technology/technologies.lua loaded")
