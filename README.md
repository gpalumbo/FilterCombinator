# Filter Combinator

A Factorio 2.0 mod that filters circuit signals by comparing red and green wire inputs.

## How It Works

Connect red and green wires to the input side. The combinator compares signal types between wires and outputs filtered results.

### Modes

**Difference Mode** (default)
Outputs signals that exist on only one wire.
- Red out: signals on red that aren't on green
- Green out: signals on green that aren't on red

**Intersection Mode**
Outputs signals that exist on both wires.
- Both outputs contain matching signal types (counts preserved per wire)

### Example

Input: Red `[43 iron, 20 copper]` / Green `[1 iron, 1 water]`

| Mode | Red Out | Green Out |
|------|---------|-----------|
| Difference | `[20 copper]` | `[1 water]` |
| Intersection | `[43 iron]` | `[1 iron]` |

## Configuration

Click the combinator to open settings. Toggle between Difference and Intersection modes.

## Requirements

Requires Filter Combinator technology (unlocked with all science packs including space science).