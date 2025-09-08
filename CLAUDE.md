# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a WezTerm terminal configuration written in Lua. WezTerm is a GPU-accelerated cross-platform terminal emulator and multiplexer. This configuration uses a modular architecture with organized directories for different functionality.

## Architecture

The configuration uses a custom `Config` class (`config/init.lua`) that provides a fluent interface for building configuration options. The main entry point is `wezterm.lua` which:

1. Initializes backdrop management with support for image cycling
2. Sets up event handlers for status bars and tab management  
3. Builds the final configuration by appending modules in this order: appearance → bindings → domains → fonts → general → launch

### Core Components

- **Config System**: Centralized configuration management with duplicate detection warnings
- **Backdrop Management**: Advanced background image system supporting 3 modes:
  - Mode 0: Origin images with background color overlay
  - Mode 1: Acrylic images (preprocessed with blur effects)
  - Mode 2: Focus mode with solid color background
- **Event System**: Modular event handlers for UI components
- **Utility Libraries**: Reusable components for platform detection, math operations, and cell rendering

### Directory Structure

- `config/` - Core configuration modules (appearance, bindings, fonts, etc.)
- `events/` - Event handlers for status bars and tab management
- `utils/` - Utility modules (backdrops, platform detection, GPU adapter selection)
- `colors/` - Color scheme definitions
- `backdrops/` - Background images directory

## Key Features

### Backdrop System
The backdrop system (`utils/backdrops.lua`) automatically scans for images in the `backdrops/` directory and supports:
- Automatic acrylic image detection (files containing `.acrylic.`)
- Runtime mode switching between regular images, acrylic images, and focus mode
- Dynamic image cycling and random selection
- Window-level background overrides

### Event-Driven UI
Status bars and tab titles are managed through WezTerm's event system with dedicated modules for left status, right status, tab titles, and new tab buttons.

## Development Notes

- The backdrop system requires `set_images()` to be called from `wezterm.lua` due to WezTerm's coroutine restrictions
- All modules return configuration tables that get merged through the `Config:append()` method
- The configuration supports both integrated and discrete GPU selection through `utils/gpu-adapter.lua`
- Color schemes are centralized in `colors/custom.lua` and referenced throughout the configuration