# My Example Mod 

## Vision Statement
_Typically a general top level for AI to understand hos the module works together_
This is a factorio combinator. It takes signals from red and green a either outputs the intersection or the symmetric difference

## Core Components

### 1. Technologies

#### Filter Combinator  Technology
- **Name:** `Filter Combinator`
- **Cost:** 100x each science pack (automation, logistic, military, chemical, production, utility, space)
- **Prerequisites:** Space Science, Logistic system
- **Unlocks:** Filter Combinator
- **Icon:** Filter combinator combinator Icon


### 2. Receiver Combinator

**Entity Specifications:**
- **Size:** 2x1 combinator
- **Recipe:** 5x electronic circuits , 5x advanced circuits
- **Placement:** any surface
- **Health:** 150 (same as arithmetic combinator, scales with quality)
- **Power:** 1kW 
- **Circuit Connections:** 4 terminals (red in, red out, green in, green out)
- **Mode:** Always bidirectional 
- **Graphics:** Similar to arithmetic combinator
- **Stack Size:** 50
- **Rocket Capacity:** 50

## graphics
- Graphics are in mod/graphics
    - filter-combinator-icon.png has 4 sizes of icons, ensure confiured properly
    - filter-combinator.png has 4 images one for each rotation.
    - see "C:\Program Files (x86)\Steam\steamapps\common\Factorio\data\base\prototypes\entity\combinator-pictures.lua" for standard combinator prototype image setup.
    - combinator-displays.png has the same format as the standard but we will only use the first three on the top row.
       0. blank
       1. intersection
       2. difference

**Configuration UI:**
- Title: "Filter Settings"
- A toggle for Difference vs Intersection .  Defaults to difference.
- Input and output signal grids should be on the bottom of the gui

**Signal Behavior:**
- Input signals are compared between wires. 
- If the mode is difference, 
    - then red signals whose signal id do not match any signal id on the green wire will pass through to the red output
    - like wise for green signals id that do not match any red signal id will pass through
    - the counts are preserved by wire color! 
    - example RED ID [ 43 iron ore, 20 copper ore] green in [ 1 iron ore, 1 water] then red out [ 20 coppor ore] gree out [ 1 water]
- If the mode is intersection
    - then the signal ids are compares an only signals that are on both green and red are passed, BUT the counts remain distinct!
    - example RED ID [ 43 iron ore, 20 copper ore] green in [ 1 iron ore, 1 water] then red out [ 43 iron ore] gree out [ 1 iron ore]

**Implementation Critical:**
```lua
-- Use standard combinator prototype as base
-- Persist state across save/load
-- Update GUI layout dynamically when and_or toggled
```

### Key Principles
1. **Preserve wire separation** - Red and green networks never mix

## Critical Implementation Warnings

### MUST Handle:
1. **Entity lifecycle events** - Cleanup when entities destroyed
2. **Save/Load** - Properly serialize global state
3. **Multiplayer** - Ensure signal sync across players
4. **Quality scaling** - Apply quality bonuses to health/power
*CRITICAL* use docs/eneity_creation_checklist.md as a guide

## Architecture Notes

### LIbraries
**🚨 CRITICAL: 🚨**
- Reuse functions in mod/lib. They work and should be updated only after confirmation!  Use them extensively

Ensure proper API usage is strictly adhered to.  
- use @docs\flib_api_reference.md to find premade utilities
- Use Context7 to view "Factorio Lua API"  also use 
- Use https://github.com/wube/factorio-data/blob/master/core/prototypes/utility-sprites.lua
VERY IMPORATANT: ALWAYS MAKE SURE YOU ARE USING 2.0 LATEST APIs.  It wastes time and gets everyone upset when you use older apis!

###  State Structure
#### GLOBAL storiage
```lua
storage.<modname> = {
  lem_filter_combinators = {
    [unit_number] = {
      entity = entity
      mode = 'diff' | 'inter'
    }
  },
```
#### Ghost tags
the same innter structure
```lua
    {
      entity = entity
      mode = 'diff' | 'inter'
    }
```


### Performance Optimizations
1. Use filters when registering events where possible
2. Limit GUI updates to when GUI is open

## Edge Cases & Solutions

| Edge Case | Solution |
|-----------|----------|
*TBD*

## Validation Checklist

### Core Functionality
- [ ] Red/green wire separation preserved through transmission  
- [ ] All entities require appropriate tech unlock

### Entity Behavior
- [ ] Health values scale with quality
- [ ] Power consumption scales with quality
- [ ] Entities can be blueprinted and copy/pasted
- [ ] Rotation works correctly for all entities
- [ ] Circuit connections preserved in blueprints

### UI/UX
- [ ] LED indicators show active state
- [ ] GUI responsive to changes

### Events & Lifecycle
- [ ] Platform lifecycle events handled
- [ ] Entity destroyed events cleanup global state
- [ ] Save/load preserves all state
- [ ] Multiplayer synchronized properly

## Success Criteria

Players can successfully:
1. Build Passthrough Combinators on the planet
2. Configure receiver combinators to connect to specific planets
5. See clear visual feedback (LEDs, status text) of system state
6. Create blueprints incorporating the new entities
7. Scale up to multiple planets and platforms without issues
8. Use familiar Factorio UI patterns throughout

## Final Notes

- This mod extends vanilla without replacing functionality
- All vanilla platform behaviors remain intact
- Circuit control is optional - players can ignore it entirely
- Focus on intuitive, Factorio-like user experience
- Prioritize stability ond performancever feature complexity
- When in doubt, follow vanilla factorio patterns
