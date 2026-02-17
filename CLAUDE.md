# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Elixir API client library for the AzuPay Payments API. Uses API key authentication (not OAuth2). Follows the same architecture as the sibling `idverse` and `zepto` libraries at `../idverse` and `../zepto`.

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

- **`Azupay.Client`** — Client struct (`environment`, `base_url`, `api_key`, `req_options`). Created via `Client.new(environment: :uat)`. Reads config from `Application.get_env(:azupay, :environments)`.
- **`Azupay.Client.Request`** — Centralized HTTP handling via Req. All resource modules delegate here. Passes `api_key` directly in `Authorization` header (raw value, no Bearer prefix). Standard error mapping: 401→`:unauthorized`, 403→`:forbidden`, 404→`:not_found`, 422→`{:validation_error, body}`.
- **`Azupay.Client.Error`** — Structured error type with `new/1` constructor for all error variants.
- **`Azupay.Client.PaymentRequests`** — Resource module for payment request operations. New resource modules follow this same pattern.
- All functions return `{:ok, data} | {:error, term()}`.

## Configuration

Multi-environment config via `config :azupay, environments: [uat: [...], prod: [...]]`. Each environment has `base_url` and `api_key`. UAT base URL: `https://api-uat.azupay.com.au/v1`, prod: `https://api.azupay.com.au/v1`.

## Testing

Tests use Req's built-in plug adapter for HTTP mocking (no real HTTP calls). Pattern: create a client with `req_options: [plug: fn_plug]` to intercept requests.

## API Reference

AzuPay API docs: https://developer.azupay.com.au/reference/createpayidpaymentrequest
