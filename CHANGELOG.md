# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-02-17

### Added

- Webhook support for receiving AzuPay payment notifications (`Azupay.Webhook`)
- `Azupay.Webhook.Plug` - Plug for receiving and verifying webhook requests
- `Azupay.Webhook.TokenEndpoint` - OAuth2 token endpoint Plug (Client Credentials grant)
- `Azupay.Webhook.Handler` - Behaviour for implementing webhook event handlers
- `Azupay.Webhook.Token` - JWT generation and verification (HS256)
- Support for both API key and OAuth2 Bearer token authentication, including simultaneously
- New dependencies: `joken` (optional), `plug` promoted from test-only to optional runtime

## [0.1.0] - 2026-02-17

### Added

- Initial release
- API key authentication via `Azupay.Client`
- Multi-environment support (UAT, production)
- Centralized HTTP handling via `Azupay.Client.Request` using Req
- Structured error handling via `Azupay.Client.Error`
- API resources:
  - `Azupay.Client.PaymentRequests` - PayID/virtual account payment collection
  - `Azupay.Client.Payments` - Fund disbursement via PayID or BSB
  - `Azupay.Client.PaymentInitiations` - PayTo fund collection
  - `Azupay.Client.PaymentAgreements` - PayTo recurring mandates
  - `Azupay.Client.PaymentAgreementRequests` - PayTo payer approval flow
  - `Azupay.Client.Accounts` - BSB reachability, PayID status, Confirmation of Payee
  - `Azupay.Client.Balances` - Account balance
  - `Azupay.Client.BalanceAdjustments` - Ledger adjustments
  - `Azupay.Client.Reports` - Report listing and download
  - `Azupay.Client.ApiKeys` - API key management
  - `Azupay.Client.Clients` - Sub-client management
  - `Azupay.Client.PayIdDomains` - PayID domain configuration
