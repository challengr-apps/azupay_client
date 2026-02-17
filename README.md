# Azupay

Elixir client library for the [AzuPay Payments API](https://developer.azupay.com.au/).

## Installation

Add `azupay` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:azupay, "~> 0.2.0"}
  ]
end
```

## Configuration

Configure environments in your `config/runtime.exs`:

```elixir
config :azupay,
  environments: [
    uat: [
      base_url: "https://api-uat.azupay.com.au/v1",
      api_key: System.get_env("AZUPAY_UAT_API_KEY"),
      client_id: System.get_env("AZUPAY_UAT_CLIENT_ID")
    ],
    prod: [
      base_url: "https://api.azupay.com.au/v1",
      api_key: System.get_env("AZUPAY_PROD_API_KEY"),
      client_id: System.get_env("AZUPAY_PROD_CLIENT_ID")
    ]
  ]
```

## Usage

### Creating a Client

```elixir
# Create a client for an environment
client = Azupay.Client.new(environment: :uat)

# Shortcut for UAT
client = Azupay.Client.uat()
```

### Payment Requests

Generate PayID or virtual account details for receiving payments.

```elixir
# Create a payment request
{:ok, response} = Azupay.Client.PaymentRequests.create(client, %{
  "payID" => "user@example.com",
  "payIDType" => "EMAIL",
  "amount" => "100.00",
  "clientTransactionId" => "txn-123"
})

# Get a payment request
{:ok, response} = Azupay.Client.PaymentRequests.get(client, "request-id")

# Search payment requests
{:ok, results} = Azupay.Client.PaymentRequests.search(client, %{
  "fromDate" => "2025-01-01T00:00:00Z",
  "toDate" => "2025-01-31T23:59:59Z"
})

# Refund a payment request (full or partial)
{:ok, response} = Azupay.Client.PaymentRequests.refund(client, "request-id")
{:ok, response} = Azupay.Client.PaymentRequests.refund(client, "request-id", refund_amount: "50.00")

# Delete a payment request
{:ok, response} = Azupay.Client.PaymentRequests.delete(client, "request-id")
```

### Payments

Disburse funds via PayID or BSB/account number.

```elixir
# Create a payment
{:ok, response} = Azupay.Client.Payments.create(client, %{
  "clientPaymentId" => "pay-123",
  "amount" => "250.00",
  "payID" => "recipient@example.com",
  "payIDType" => "EMAIL"
})

# Get a payment
{:ok, response} = Azupay.Client.Payments.get(client, "payment-id")

# Search payments
{:ok, results} = Azupay.Client.Payments.search(client, %{
  "clientPaymentId" => "pay-123"
})
```

### Payment Initiations (PayTo)

Collect funds from payers with active payment agreements.

```elixir
# Create a payment initiation
{:ok, response} = Azupay.Client.PaymentInitiations.create(client, %{
  "clientTransactionId" => "pi-123",
  "amount" => "100.00",
  "paymentAgreementId" => "agreement-id"
})

# Get a payment initiation
{:ok, response} = Azupay.Client.PaymentInitiations.get(client, "initiation-id")

# Refund a payment initiation
{:ok, response} = Azupay.Client.PaymentInitiations.refund(client, "initiation-id")
```

### Payment Agreements (PayTo Mandates)

```elixir
# Create a payment agreement
{:ok, response} = Azupay.Client.PaymentAgreements.create(client, %{
  "contractId" => "contract-123",
  "payerPayID" => "payer@example.com",
  "payerPayIDType" => "EMAIL"
})

# Search agreements
{:ok, results} = Azupay.Client.PaymentAgreements.search(client, %{
  "contractId" => "contract-123"
})

# Amend an agreement
{:ok, response} = Azupay.Client.PaymentAgreements.amend(client, %{
  "paymentAgreementId" => "agreement-id",
  "amount" => "200.00"
})

# Change agreement status (ACTIVE, SUSPENDED, CANCELLED)
{:ok, response} = Azupay.Client.PaymentAgreements.change_status(client, "agreement-id", "SUSPENDED")
```

### Payment Agreement Requests

Initiate payer approval flow for PayTo agreements.

```elixir
{:ok, response} = Azupay.Client.PaymentAgreementRequests.create(client, %{
  "contractId" => "contract-123",
  "payerPayID" => "payer@example.com",
  "payerPayIDType" => "EMAIL"
})
# Response includes `sessionUrl` for redirecting the payer
```

### Account Enquiry

```elixir
# Check BSB reachability
{:ok, response} = Azupay.Client.Accounts.check_bsb(client, %{"bsb" => "062000"})

# Check PayID status
{:ok, response} = Azupay.Client.Accounts.check_payid(client, %{
  "payID" => "user@example.com",
  "payIDType" => "EMAIL"
})

# Confirmation of Payee (CoP)
{:ok, response} = Azupay.Client.Accounts.check_account(client, %{
  "accountCheckId" => "check-123",
  "bsb" => "062000",
  "accountNumber" => "12345678",
  "accountName" => "John Doe",
  "purposeCode" => "SALARY",
  "additionalDetails" => "Payroll"
})
```

### Balances

```elixir
{:ok, balance} = Azupay.Client.Balances.get(client)
```

### Balance Adjustments

```elixir
{:ok, response} = Azupay.Client.BalanceAdjustments.create(client, %{
  "clientTransactionId" => "adj-123",
  "adjustmentAmount" => "500.00",
  "adjustmentType" => "CREDIT",
  "reason" => "Top up",
  "clientId" => "client-id"
})
```

### Reports

```elixir
# List reports
{:ok, reports} = Azupay.Client.Reports.list(client, %{
  "clientId" => "client-id",
  "month" => "2025-01",
  "timezone" => "Australia/Sydney"
})

# Get download URL
{:ok, url} = Azupay.Client.Reports.download_url(client, "client-id", "report-id")
```

### API Keys

```elixir
# Create an API key for a sub-merchant
{:ok, key} = Azupay.Client.ApiKeys.create(client, %{"clientId" => "sub-merchant-id"})

# List all API keys
{:ok, keys} = Azupay.Client.ApiKeys.list(client)

# Get a specific API key
{:ok, key} = Azupay.Client.ApiKeys.get(client, "key-id")

# Update an API key
{:ok, key} = Azupay.Client.ApiKeys.update(client, "key-id", %{"enabled" => false})
```

### Sub-Client Management

```elixir
# Create a sub-client
{:ok, response} = Azupay.Client.Clients.create(client, %{
  "clientTransactionId" => "client-123",
  "name" => "Sub Merchant"
})

# Disable a sub-client
{:ok, response} = Azupay.Client.Clients.disable(client, "sub-client-id")

# Set low balance alert threshold
{:ok, response} = Azupay.Client.Clients.set_low_balance_threshold(client, "client-id", "1000.00")

# Set alert email addresses
{:ok, response} = Azupay.Client.Clients.set_alert_emails(client, "client-id", ["alerts@example.com"])
```

### PayID Domains

```elixir
# List configured PayID domains
{:ok, domains} = Azupay.Client.PayIdDomains.list(client)

# Upsert PayID domains
{:ok, response} = Azupay.Client.PayIdDomains.upsert(client, [
  %{"domain" => "example.com", "clientId" => "client-id"}
])

# Delete a PayID domain
{:ok, response} = Azupay.Client.PayIdDomains.delete(client, "example.com")
```

## API Resources

| Module | Description |
|--------|-------------|
| `Azupay.Client.PaymentRequests` | PayID/virtual account payment collection |
| `Azupay.Client.Payments` | Fund disbursement via PayID or BSB |
| `Azupay.Client.PaymentInitiations` | PayTo fund collection |
| `Azupay.Client.PaymentAgreements` | PayTo recurring mandates |
| `Azupay.Client.PaymentAgreementRequests` | PayTo payer approval flow |
| `Azupay.Client.Accounts` | BSB, PayID, and account enquiry |
| `Azupay.Client.Balances` | Account balance |
| `Azupay.Client.BalanceAdjustments` | Ledger adjustments |
| `Azupay.Client.Reports` | Report listing and download |
| `Azupay.Client.ApiKeys` | API key management |
| `Azupay.Client.Clients` | Sub-client management |
| `Azupay.Client.PayIdDomains` | PayID domain configuration |

## Webhooks

AzuPay sends webhook notifications when payment entity statuses change. This library provides Plug modules to receive and authenticate these webhooks.

AzuPay supports two authentication modes — a simple API key, and an OAuth2 Client Credentials flow where AzuPay fetches a Bearer token from your token endpoint before sending the webhook. You can use either or both simultaneously.

### 1. Implement a handler

```elixir
defmodule MyApp.AzupayWebhookHandler do
  @behaviour Azupay.Webhook.Handler

  @impl true
  def handle_event("PaymentRequest", payload) do
    # Handle payment request status update
    :ok
  end

  def handle_event("Payment", payload) do
    # Handle payment status update
    :ok
  end

  def handle_event(_type, _payload) do
    # Gracefully ignore unknown event types
    :ok
  end
end
```

### 2. Mount the plugs in your router

**API key auth only:**

```elixir
forward "/webhooks/azupay", Azupay.Webhook.Plug,
  auth: {:api_key, System.get_env("AZUPAY_WEBHOOK_KEY")},
  handler: MyApp.AzupayWebhookHandler
```

**OAuth2 auth** (AzuPay fetches tokens from your endpoint):

```elixir
# Token endpoint — AzuPay calls this to obtain Bearer tokens
forward "/webhooks/azupay/token", Azupay.Webhook.TokenEndpoint,
  client_id: "azupay-client",
  client_secret: System.get_env("AZUPAY_WEBHOOK_SECRET"),
  signing_key: System.get_env("WEBHOOK_SIGNING_KEY")

# Webhook receiver — verifies the Bearer token
forward "/webhooks/azupay", Azupay.Webhook.Plug,
  auth: {:oauth2, signing_key: System.get_env("WEBHOOK_SIGNING_KEY")},
  handler: MyApp.AzupayWebhookHandler
```

**Both modes** (accepts either API key or OAuth2 Bearer token):

```elixir
forward "/webhooks/azupay", Azupay.Webhook.Plug,
  auth: [
    {:api_key, System.get_env("AZUPAY_WEBHOOK_KEY")},
    {:oauth2, signing_key: System.get_env("WEBHOOK_SIGNING_KEY")}
  ],
  handler: MyApp.AzupayWebhookHandler
```

### Important notes

- Your webhook endpoint must respond within **5 seconds** (AzuPay requirement).
- AzuPay delivers webhooks **at least once** — handle duplicates gracefully.
- Webhooks may arrive **out of order** — don't assume sequential delivery.
- The `signing_key` must be the same in both `TokenEndpoint` and `Webhook.Plug`.
- Webhook support requires the optional `joken` and `plug` dependencies.

## Error Handling

All functions return `{:ok, data}` or `{:error, reason}`. Error reasons include:

| Error | HTTP Status |
|-------|-------------|
| `:unauthorized` | 401 |
| `:forbidden` | 403 |
| `:not_found` | 404 |
| `{:validation_error, details}` | 422 |
| `{:client_error, status, body}` | Other 4xx |
| `{:server_error, status, body}` | 5xx |
| `{:request_failed, reason}` | Network failure |

Use `Azupay.Client.Error.new/1` for structured error handling:

```elixir
case Azupay.Client.PaymentRequests.create(client, params) do
  {:ok, response} -> handle_success(response)
  {:error, reason} ->
    error = Azupay.Client.Error.new(reason)
    if Azupay.Client.Error.validation_error?(error) do
      handle_validation_error(error)
    else
      handle_error(error)
    end
end
```

## Testing

Tests use Req's built-in plug adapter for HTTP mocking (no real HTTP calls):

```elixir
client = Azupay.Client.new(
  environment: :uat,
  req_options: [
    plug: fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(200, Jason.encode!(%{"status" => "ok"}))
    end
  ]
)
```

## License

MIT
