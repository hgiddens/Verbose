# CLAUDE.md

## Project Overview

**Verbose** is a multilingual Swift web application for solving word puzzles using pattern matching. It's built with the Hummingbird web framework and uses server-side HTML rendering via Elementary.

### Key Components

- **Solver Module** (`Sources/Solver/`): Core pattern matching logic
  - `Pattern`: Regex-based pattern matcher with diacritics support for locale-aware matching
  - `CompiledPattern`: Internal regex compilation with locale-specific folding
  - `Solver`: Word corpus searcher using pattern matching, organised by word length

- **App Module** (`Sources/App/`): Web application implementation
  - `App.swift`: Main entry point with CLI argument parsing using ArgumentParser
  - `Application+Build.swift`: Application bootstrap, dependency injection, and language loading
  - `Application+Router.swift`: HTTP routing, language negotiation, form processing
  - `Pages.swift`: Server-side HTML templates using Elementary framework
  - `SupportedLanguage.swift`: Language configuration with localisation support
  - `SecurityHeadersMiddleware.swift`: Security headers middleware

### Technical Details

- **Framework Stack**: [Hummingbird](https://hummingbird.codes) (web server) + [Elementary](https://github.com/sliemeobn/elementary) (HTML DSL) + ArgumentParser (CLI) + Lingo (i18n)
- **Architecture Pattern**: Request/response with server-side rendering
- **Multilingual Support**: Content negotiation via Accept-Language headers, localised content via Lingo
- **Word Corpora**: Language-specific word lists (`words-en.txt`, `words-de.txt`) loaded at startup
- **Pattern Format**: Letters with `?` as wildcard (e.g., `v?r?o?e` matches `verbose`)
- **Performance**: Words indexed by length for efficient pattern matching

### Request Flow
1. GET `/` → Language negotiation via Accept-Language → Redirect to `/[lang]`
2. GET `/[lang]` → Renders localised entry form
3. POST `/[lang]` → Processes pattern, runs solver, renders results with timing information

The application supports multiple languages simultaneously via command-line arguments and uses custom request contexts (`AppRequestContext`) for form processing.

## Development Commands

### Building and Running
```bash
# Build the project
swift build

# Run the application (requires language arguments)
swift run Verbose --languages en de

# Run with specific configuration
swift run -c release Verbose --languages en de

# Run with custom hostname/port
swift run Verbose --hostname 0.0.0.0 --port 3000 --languages en de
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

# Reset build directory
swift package reset
```

### Code Formatting
```bash
# Format the code by default
swift format -ipr .
```

## Code Quality

- Source code and text files (CSS, JSON, markdown etc.) should generally end with a newline.
- When order doesn't matter (e.g., dependencies in a dependency list, imports), prefer ASCIIbetical order.
- Prefer British English, although obviously you need to deal with the fact that APIs etc. will want simplified English.

## Development process

Try to create a plan for work before starting coding. In the event of ambiguity or a lack of clarity, ask questions to improve your understanding.

When asked to implement a feature, research the codebase first to understand the current state of the project.

### Use multiple agents

Use subagents when you can:
- To explore different parts of the code base.
- Have separate subagents implement the features and the tests.
- Delegate research tasks.
- For complex refactoring, have one agent identify the changes necessary, and another implement the changes.

### Validate assumptions

If things start unexpectedly failing, or things seem wrong, stop and validate (e.g., re-inspect the code base, run the tests) to understand what's happened, rather than continuing speculatively.

## Source control

- **Format the code before each commit**. This is mandatory.
- Commit messages should have a first line that is less than 80 characters long, is a complete sentence, starts with a verb and ends with a period.
- Commit messages should be wrapped at 80 characters.

## Memories

- Don't ignore the instructions that have been provided to you in this file.
