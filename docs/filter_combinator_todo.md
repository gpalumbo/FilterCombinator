# Filter Combinator Implementation Plan

## Overview
Implement a Filter Combinator that compares signals between red and green wires and outputs either:
- **Difference mode**: Signals unique to each wire (red-only to red out, green-only to green out)
- **Intersection mode**: Signals present on both wires (preserved by wire color)

## Entity Specifications
- **Size**: 2x1 combinator
- **Recipe**: 5x electronic circuits, 5x advanced circuits
- **Health**: 150 (scales with quality)
- **Power**: 1kW
- **Circuit Connections**: 4 terminals (red in, red out, green in, green out)
- **Default Mode**: Difference

## Implementation Tasks

### Phase 1: Project Setup
- [x] Read existing codebase structure
- [x] Read LogisticsCombinator reference project
- [x] Create implementation plan
- [ ] Update info.json
- [ ] Remove passthrough combinator files

### Phase 2: Prototypes (Data Stage)
- [ ] Create filter_combinator entity prototype
  - Copy arithmetic combinator as base
  - Configure sprites from mod/graphics/filter-combinator.png
  - Configure display sprites from mod/graphics/combinator-displays.png
  - Set up 4 wire connection points
- [ ] Create filter_combinator item prototype
- [ ] Create filter_combinator recipe prototype
- [ ] Update technology prototype
- [ ] Update data.lua

### Phase 3: Storage Architecture (scripts/filter_combinator/)
- [ ] Create storage.lua
  - init_storage()
  - register(entity)
  - unregister(unit_number)
  - get_data(entity_or_unit_number) - universal ghost/real
  - update_data(entity, data) - universal ghost/real
  - serialize_config(entity)
  - restore_config(entity, config)
  - get_ghost_config(ghost_entity)
  - save_ghost_config(ghost_entity, config)

### Phase 4: Logic Implementation
- [ ] Create logic.lua
  - process_filter(entity, mode) - main signal processing
  - compute_difference(red_signals, green_signals)
  - compute_intersection(red_signals, green_signals)
  - write_output_signals(entity, red_out, green_out)

### Phase 5: Event Handlers (scripts/filter_combinator/)
- [ ] Create control.lua
  - on_built(entity, player, tags)
  - on_removed(entity)
  - on_tick_2() - process signals every other tick (~33ms)
  - on_init()
  - on_configuration_changed()

### Phase 6: GUI Implementation
- [ ] Create gui.lua
  - create_gui(player, entity)
  - close_gui(player)
  - on_gui_opened(event)
  - on_gui_closed(event)
  - on_gui_switch_state_changed(event) - mode toggle
  - Mode toggle: Difference vs Intersection
  - Signal display grids for inputs and outputs

### Phase 7: Integration
- [ ] Update globals.lua
  - Add filter combinator storage functions
  - Re-export with prefixed names
- [ ] Update main control.lua
  - Add routing for filter-combinator entity
  - Register GUI events
  - Register blueprint events
- [ ] Create locale strings

### Phase 8: Testing
- [ ] Manual placement works
- [ ] Blueprint copy/paste works
- [ ] Ghost entity configuration preserved
- [ ] Mode toggle persists
- [ ] Difference mode outputs correctly
- [ ] Intersection mode outputs correctly
- [ ] Red/green wire separation preserved
- [ ] GUI displays input/output signals

## Signal Processing Logic

### Difference Mode
```lua
-- For each signal on red wire:
--   If signal ID NOT on green wire -> output to red out
-- For each signal on green wire:
--   If signal ID NOT on red wire -> output to green out
-- Counts are preserved!

-- Example:
-- Red in: [43 iron, 20 copper]
-- Green in: [1 iron, 1 water]
-- Red out: [20 copper]  -- copper not on green
-- Green out: [1 water]  -- water not on red
```

### Intersection Mode
```lua
-- For each signal on red wire:
--   If signal ID IS on green wire -> output to red out (with red count)
-- For each signal on green wire:
--   If signal ID IS on red wire -> output to green out (with green count)
-- Counts remain distinct per wire!

-- Example:
-- Red in: [43 iron, 20 copper]
-- Green in: [1 iron, 1 water]
-- Red out: [43 iron]   -- iron is on both, use red count
-- Green out: [1 iron]  -- iron is on both, use green count
```

## Storage Structure

```lua
storage.filter_combinators = {
  [unit_number] = {
    entity = entity_reference,
    mode = 'diff' | 'inter'  -- Default: 'diff'
  }
}
```

## Ghost Tags Structure
```lua
{
  filter_combinator_config = {
    mode = 'diff' | 'inter'
  }
}
```

## File Structure After Implementation
```
mod/
├── info.json
├── data.lua
├── control.lua
├── lib/
│   ├── entity_lib.lua
│   ├── circuit_utils.lua
│   ├── signal_utils.lua
│   └── gui/
│       ├── gui_entity.lua
│       └── gui_circuit_inputs.lua
├── scripts/
│   ├── globals.lua
│   └── filter_combinator/
│       ├── storage.lua
│       ├── control.lua
│       ├── logic.lua
│       └── gui.lua
├── locale/
│   └── en/
│       └── filter-combinator.cfg
├── prototypes/
│   ├── technology/
│   │   └── technologies.lua
│   ├── entity/
│   │   └── filter_combinator.lua
│   ├── item/
│   │   └── filter_combinator.lua
│   └── recipe/
│       └── filter_combinator.lua
└── graphics/
    ├── filter-combinator.png
    ├── filter-combinator-icon.png
    └── combinator-displays.png
```
