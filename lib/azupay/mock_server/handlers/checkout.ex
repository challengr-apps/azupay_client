defmodule Azupay.MockServer.Handlers.Checkout do
  @moduledoc """
  Handles the checkout payment page for the mock server.
  Serves a single-page app that simulates a bank payment flow.
  """

  import Plug.Conn

  alias Azupay.MockServer.State
  alias Azupay.MockServer.Responses

  @doc """
  Serves the checkout HTML page.
  """
  def page(conn) do
    base_path =
      case conn.script_name do
        [] -> ""
        segments -> "/" <> Enum.join(segments, "/")
      end

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, checkout_html(base_path))
  end

  @doc """
  Verifies a PayID and returns the associated payment request.
  GET /mock/checkout/verify?payId=...
  """
  def verify(conn) do
    pay_id = conn.params["payId"] || ""

    if pay_id == "" do
      Responses.validation_error(conn, %{"payId" => ["is required"]})
    else
      case State.get_payment_request_by_pay_id(pay_id) do
        {:ok, payment_request} ->
          Responses.ok(conn, payment_request)

        {:error, :not_found} ->
          Responses.not_found(conn, "No payment request found for PayID: #{pay_id}")
      end
    end
  end

  @doc """
  Processes a payment for a payment request.
  POST /mock/checkout/pay
  Expects JSON body: {"paymentRequestId": "...", "amount": 100.00, "reference": "..."}
  """
  def pay(conn) do
    id = conn.body_params["paymentRequestId"]

    if is_nil(id) || id == "" do
      Responses.validation_error(conn, %{"paymentRequestId" => ["is required"]})
    else
      case State.simulate_payment(id) do
        {:ok, payment_request} ->
          Responses.ok(conn, %{
            "paymentRequestId" => payment_request["PaymentRequestStatus"]["paymentRequestId"],
            "status" => payment_request["PaymentRequestStatus"]["status"],
            "message" => "Payment completed successfully"
          })

        {:error, :not_found} ->
          Responses.not_found(conn, "Payment request not found")

        {:error, {:invalid_state, message}} ->
          Responses.error(conn, 422, "invalid_state", message)
      end
    end
  end

  defp checkout_html(base_path) do
    """
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Mock Bank - AzuPay Payment</title>
      <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
          background: #f5f7fa;
          color: #333;
          min-height: 100vh;
          display: flex;
          flex-direction: column;
          align-items: center;
        }
        header {
          background: #1a56db;
          color: white;
          width: 100%;
          padding: 1rem 2rem;
          text-align: center;
        }
        header h1 { font-size: 1.25rem; font-weight: 600; }
        header p { font-size: 0.85rem; opacity: 0.85; margin-top: 0.25rem; }
        .container {
          max-width: 480px;
          width: 100%;
          padding: 2rem 1rem;
        }
        .card {
          background: white;
          border-radius: 8px;
          box-shadow: 0 1px 3px rgba(0,0,0,0.1);
          padding: 1.5rem;
          margin-bottom: 1rem;
        }
        .card h2 {
          font-size: 1rem;
          margin-bottom: 1rem;
          color: #1a56db;
        }
        label {
          display: block;
          font-size: 0.85rem;
          font-weight: 500;
          margin-bottom: 0.35rem;
          color: #555;
        }
        input[type="text"],
        input[type="number"] {
          width: 100%;
          padding: 0.6rem 0.75rem;
          border: 1px solid #d1d5db;
          border-radius: 6px;
          font-size: 0.95rem;
          margin-bottom: 1rem;
          transition: border-color 0.15s;
        }
        input:focus {
          outline: none;
          border-color: #1a56db;
          box-shadow: 0 0 0 2px rgba(26,86,219,0.15);
        }
        input:disabled { background: #f3f4f6; color: #9ca3af; }
        button {
          width: 100%;
          padding: 0.7rem;
          border: none;
          border-radius: 6px;
          font-size: 0.95rem;
          font-weight: 600;
          cursor: pointer;
          transition: background 0.15s;
        }
        button:disabled { opacity: 0.5; cursor: not-allowed; }
        .btn-primary { background: #1a56db; color: white; }
        .btn-primary:hover:not(:disabled) { background: #1e40af; }
        .btn-success { background: #059669; color: white; }
        .btn-success:hover:not(:disabled) { background: #047857; }
        .alert {
          padding: 0.75rem 1rem;
          border-radius: 6px;
          font-size: 0.85rem;
          margin-bottom: 1rem;
        }
        .alert-error { background: #fef2f2; color: #991b1b; border: 1px solid #fecaca; }
        .alert-success { background: #f0fdf4; color: #166534; border: 1px solid #bbf7d0; }
        .detail-row {
          display: flex;
          justify-content: space-between;
          padding: 0.5rem 0;
          border-bottom: 1px solid #f3f4f6;
          font-size: 0.9rem;
        }
        .detail-row:last-child { border-bottom: none; }
        .detail-label { color: #6b7280; }
        .detail-value { font-weight: 500; text-align: right; word-break: break-all; max-width: 60%; }
        .status-badge {
          display: inline-block;
          padding: 0.2rem 0.6rem;
          border-radius: 999px;
          font-size: 0.75rem;
          font-weight: 600;
        }
        .status-waiting { background: #fef3c7; color: #92400e; }
        .status-complete { background: #d1fae5; color: #065f46; }
        .status-other { background: #e5e7eb; color: #374151; }
        .hidden { display: none; }
        .spinner {
          display: inline-block;
          width: 1rem;
          height: 1rem;
          border: 2px solid rgba(255,255,255,0.3);
          border-top-color: white;
          border-radius: 50%;
          animation: spin 0.6s linear infinite;
          vertical-align: middle;
          margin-right: 0.5rem;
        }
        @keyframes spin { to { transform: rotate(360deg); } }
        .divider { height: 1px; background: #e5e7eb; margin: 1rem 0; }
      </style>
    </head>
    <body>
      <header>
        <h1>Mock Bank</h1>
        <p>AzuPay Test Payment Simulator</p>
      </header>

      <div class="container">
        <!-- Step 1: Verify PayID -->
        <div id="step-verify" class="card">
          <h2>Step 1: Verify PayID</h2>
          <div id="verify-error" class="alert alert-error hidden"></div>
          <label for="pay-id-input">PayID</label>
          <input type="text" id="pay-id-input" placeholder="e.g. uuid@mock.azupay.com.au">
          <button id="verify-btn" class="btn-primary" onclick="verifyPayId()">Verify</button>
        </div>

        <!-- Step 2: Payment Details (shown after verification) -->
        <div id="step-pay" class="card hidden">
          <h2>Step 2: Make Payment</h2>
          <div id="pay-error" class="alert alert-error hidden"></div>
          <div id="pay-success" class="alert alert-success hidden"></div>

          <div id="pr-details" style="margin-bottom: 1rem;">
            <div class="detail-row">
              <span class="detail-label">Description</span>
              <span class="detail-value" id="detail-description"></span>
            </div>
            <div class="detail-row">
              <span class="detail-label">PayID</span>
              <span class="detail-value" id="detail-payid"></span>
            </div>
            <div class="detail-row" id="detail-amount-row">
              <span class="detail-label">Requested Amount</span>
              <span class="detail-value" id="detail-amount"></span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Status</span>
              <span class="detail-value" id="detail-status"></span>
            </div>
          </div>

          <div class="divider"></div>

          <div id="payment-form">
            <label for="amount-input">Amount ($)</label>
            <input type="number" id="amount-input" placeholder="0.00" step="0.01" min="0.01">
            <label for="reference-input">Reference (optional)</label>
            <input type="text" id="reference-input" placeholder="Payment reference">
            <button id="pay-btn" class="btn-success" onclick="submitPayment()">Submit Payment</button>
          </div>
        </div>

        <!-- Reset link -->
        <div style="text-align: center; margin-top: 0.5rem;">
          <a href="#" onclick="resetPage(); return false;"
             style="color: #6b7280; font-size: 0.8rem; text-decoration: none;">
            Start Over
          </a>
        </div>
      </div>

      <script>
        var BASE = "#{base_path}";
        var currentPaymentRequest = null;

        function verifyPayId() {
          var payId = document.getElementById('pay-id-input').value.trim();
          if (!payId) return;

          var btn = document.getElementById('verify-btn');
          var errorEl = document.getElementById('verify-error');
          errorEl.classList.add('hidden');
          btn.disabled = true;
          btn.innerHTML = '<span class="spinner"></span>Verifying...';

          fetch(BASE + '/mock/checkout/verify?payId=' + encodeURIComponent(payId))
            .then(function(r) { return r.json().then(function(d) { return {ok: r.ok, data: d}; }); })
            .then(function(res) {
              btn.disabled = false;
              btn.textContent = 'Verify';

              if (!res.ok) {
                errorEl.textContent = res.data.message || 'PayID not found';
                errorEl.classList.remove('hidden');
                return;
              }

              currentPaymentRequest = res.data;
              showPaymentStep(res.data);
            })
            .catch(function() {
              btn.disabled = false;
              btn.textContent = 'Verify';
              errorEl.textContent = 'Connection error. Please try again.';
              errorEl.classList.remove('hidden');
            });
        }

        function showPaymentStep(pr) {
          var req = pr.PaymentRequest;
          var status = pr.PaymentRequestStatus;

          document.getElementById('detail-description').textContent = req.paymentDescription;
          document.getElementById('detail-payid').textContent = req.payID;

          if (req.paymentAmount) {
            document.getElementById('detail-amount').textContent = '$' + Number(req.paymentAmount).toFixed(2);
            document.getElementById('detail-amount-row').classList.remove('hidden');
            document.getElementById('amount-input').value = req.paymentAmount;
          } else {
            document.getElementById('detail-amount-row').classList.add('hidden');
          }

          var statusEl = document.getElementById('detail-status');
          var statusClass = status.status === 'WAITING' ? 'status-waiting' :
                            status.status === 'COMPLETE' ? 'status-complete' : 'status-other';
          statusEl.innerHTML = '<span class="status-badge ' + statusClass + '">' + status.status + '</span>';

          // Show/hide the payment form based on status
          var formEl = document.getElementById('payment-form');
          var payError = document.getElementById('pay-error');
          var paySuccess = document.getElementById('pay-success');
          payError.classList.add('hidden');
          paySuccess.classList.add('hidden');

          if (status.status === 'WAITING') {
            formEl.classList.remove('hidden');
          } else {
            formEl.classList.add('hidden');
            if (status.status === 'COMPLETE') {
              paySuccess.textContent = 'This payment request has already been paid.';
              paySuccess.classList.remove('hidden');
            } else {
              payError.textContent = 'This payment request cannot be paid (status: ' + status.status + ').';
              payError.classList.remove('hidden');
            }
          }

          document.getElementById('step-verify').classList.add('hidden');
          document.getElementById('step-pay').classList.remove('hidden');
        }

        function submitPayment() {
          if (!currentPaymentRequest) return;

          var id = currentPaymentRequest.PaymentRequestStatus.paymentRequestId;
          var amount = document.getElementById('amount-input').value;
          var reference = document.getElementById('reference-input').value.trim();

          if (!amount || Number(amount) <= 0) {
            var err = document.getElementById('pay-error');
            err.textContent = 'Please enter a valid amount.';
            err.classList.remove('hidden');
            return;
          }

          var btn = document.getElementById('pay-btn');
          var payError = document.getElementById('pay-error');
          var paySuccess = document.getElementById('pay-success');
          payError.classList.add('hidden');
          paySuccess.classList.add('hidden');
          btn.disabled = true;
          btn.innerHTML = '<span class="spinner"></span>Processing...';

          fetch(BASE + '/mock/checkout/pay', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({
              paymentRequestId: id,
              amount: Number(amount),
              reference: reference
            })
          })
            .then(function(r) { return r.json().then(function(d) { return {ok: r.ok, data: d}; }); })
            .then(function(res) {
              btn.disabled = false;
              btn.textContent = 'Submit Payment';

              if (!res.ok) {
                payError.textContent = res.data.message || 'Payment failed';
                payError.classList.remove('hidden');
                return;
              }

              paySuccess.textContent = 'Payment of $' + Number(amount).toFixed(2) + ' completed successfully!';
              paySuccess.classList.remove('hidden');
              document.getElementById('payment-form').classList.add('hidden');

              // Update status badge
              var statusEl = document.getElementById('detail-status');
              statusEl.innerHTML = '<span class="status-badge status-complete">COMPLETE</span>';
            })
            .catch(function() {
              btn.disabled = false;
              btn.textContent = 'Submit Payment';
              payError.textContent = 'Connection error. Please try again.';
              payError.classList.remove('hidden');
            });
        }

        function resetPage() {
          currentPaymentRequest = null;
          document.getElementById('pay-id-input').value = '';
          document.getElementById('verify-error').classList.add('hidden');
          document.getElementById('step-verify').classList.remove('hidden');
          document.getElementById('step-pay').classList.add('hidden');
          document.getElementById('pay-error').classList.add('hidden');
          document.getElementById('pay-success').classList.add('hidden');
          document.getElementById('payment-form').classList.remove('hidden');
          document.getElementById('amount-input').value = '';
          document.getElementById('reference-input').value = '';
        }

        // Allow Enter key to trigger verify
        document.getElementById('pay-id-input').addEventListener('keydown', function(e) {
          if (e.key === 'Enter') verifyPayId();
        });
      </script>
    </body>
    </html>
    """
  end
end
