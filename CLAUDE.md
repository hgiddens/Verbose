# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Building and Running
```bash
# Build the project
swift build

# Run the application
swift run

# Run with specific configuration
swift run -c release
```

### Testing
```bash
# Run all tests
swift test

# Run tests for specific target
swift test --filter SolverTests
swift test --filter VerboseTests
```

### Package Management
```bash
# Update dependencies
swift package update

# Clean build artifacts
swift package clean

# Generate Xcode project (if needed)
swift package generate-xcodeproj
```

### Code Formatting
```bash
# Format the code by default
swift format -ipr .
```

## Code Quality

- Format the code before each commit.
- Source code and text files (CSS, JSON, markdown etc.) should generally end with a newline.
- When order doesn't matter (e.g., dependencies in a dependency list, imports), prefer ASCIIbetical order.
- Prefer British English, although obviously you need to deal with the fact that APIs etc. will want simplified English..

## Architecture Overview

**Verbose** is a Swift web application for solving word puzzles using pattern matching. It's built with the Hummingbird web framework and uses server-side HTML rendering via Elementary.

### Key Components

- **Solver Module** (`Sources/Solver/`): Core pattern matching logic
  - `Pattern`: Regex-based pattern matcher with diacritics support for locale-aware matching
  - `Solver`: Word corpus searcher using pattern matching

- **App Module** (`Sources/App/`): Web application implementation
  - `App.swift`: Main entry point with CLI argument parsing using ArgumentParser
  - `Application+Build.swift`: Application bootstrap, dependency injection, and word list loading
  - `Application+Router.swift`: HTTP routing and request handling with form processing
  - `Pages.swift`: Server-side HTML templates using Elementary framework

### Technical Details

- **Framework Stack**: Hummingbird (web server) + Elementary (HTML DSL) + ArgumentParser (CLI)
- **Architecture Pattern**: Request/response with server-side rendering
- **Localization**: Uses `en_NZ` locale for string comparison and number formatting
- **Word Corpus**: Loaded from `words.txt` resource file at application startup
- **Pattern Format**: Letters with `?` as wildcard (e.g., `v?r?o?e` matches `verbose`)

### Request Flow
1. GET `/` → Renders entry form
2. POST `/` → Processes pattern, runs solver, renders results with timing information

The application uses custom request contexts (`AppRequestContext`) for locale-aware processing and includes request logging middleware.

## Memories

- Don't ignore the instructions that have been provided to you in this file.