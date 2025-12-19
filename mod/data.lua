-- Filter Combinator Mod - Data Stage
-- Loads all prototype definitions

-- Load FLib styles
require("__flib__.data")

-- Load entity prototypes
require("prototypes.entity.filter_combinator")
require("prototypes.entity.filter_combinator_output")

-- Load item prototypes
require("prototypes.item.filter_combinator")

-- Load recipe prototypes
require("prototypes.recipe.filter_combinator")

-- Load technology prototypes
require("prototypes.technology.technologies")

log("[filter-combinator] data.lua loaded")

-- Custom input for pipette on signal buttons
data:extend({
    {
        type = "custom-input",
        name = "gui-pipette-signal",
        key_sequence = "Q",
        linked_game_control = "pipette",
        consuming = "none",
        action = "lua"
    }
})
