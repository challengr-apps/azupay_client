# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Azupay is an Elixir OTP application (v0.1.0) using Elixir ~> 1.18 with a supervision tree entry point at `Azupay.Application`.

## Commands

- `mix compile` - Compile the project
- `mix test` - Run all tests
- `mix test test/path/to/test_file.exs` - Run a single test file
- `mix test test/path/to/test_file.exs:LINE` - Run a specific test by line number
- `mix format` - Format all code
- `mix format --check-formatted` - Check formatting without modifying files
- `mix deps.get` - Fetch dependencies
- `iex -S mix` - Start interactive shell with the application loaded

## Architecture

- **Standard Elixir/OTP structure** with supervised application
- Entry point: `Azupay.Application` starts a supervisor with `:one_for_one` strategy
- Source code lives in `lib/azupay/`, tests in `test/`
- No external dependencies, web framework, or database configured yet
