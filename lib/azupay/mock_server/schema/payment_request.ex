if Code.ensure_loaded?(Ecto) do
  defmodule Azupay.MockServer.Schema.PaymentRequest do
    @moduledoc """
    Ecto schema for mock payment requests stored in the database.
    """

    use Ecto.Schema
    import Ecto.Changeset

    @primary_key {:id, :string, autogenerate: false}
    @timestamps_opts [type: :utc_datetime]

    schema "azupay_mock_payment_requests" do
      field(:client_id, :string)
      field(:client_transaction_id, :string)
      field(:payment_description, :string)
      field(:pay_id, :string)
      field(:payment_amount, :float)
      field(:status, :string, default: "WAITING")
      field(:multi_payment, :boolean, default: false)
      field(:checkout_url, :string)
      field(:payment_expiry_datetime, :string)
      field(:metadata, :map, default: %{})
      field(:payment_notification, :map)

      timestamps()
    end

    @required_fields [
      :id,
      :client_id,
      :client_transaction_id,
      :payment_description,
      :pay_id,
      :status,
      :checkout_url
    ]
    @optional_fields [
      :payment_amount,
      :multi_payment,
      :payment_expiry_datetime,
      :metadata,
      :payment_notification
    ]

    @doc """
    Changeset for creating a new payment request.
    """
    def create_changeset(payment_request, attrs) do
      payment_request
      |> cast(attrs, @required_fields ++ @optional_fields)
      |> validate_required(@required_fields)
      |> unique_constraint(:client_transaction_id)
      |> unique_constraint(:pay_id)
    end

    @doc """
    Changeset for updating a payment request (e.g. status changes).
    """
    def update_changeset(payment_request, attrs) do
      payment_request
      |> cast(attrs, [:status])
      |> validate_required([:status])
    end

    @doc """
    Converts schema to a map matching the AzuPay API response format.

    The response uses two top-level wrappers per the OpenAPI spec:
    - `"PaymentRequest"` — request configuration fields
    - `"PaymentRequestStatus"` — status and lifecycle fields
    """
    def to_api_response(%__MODULE__{} = pr) do
      payment_request =
        %{
          "payID" => pr.pay_id,
          "clientId" => pr.client_id,
          "clientTransactionId" => pr.client_transaction_id,
          "paymentDescription" => pr.payment_description,
          "checkoutUrl" => pr.checkout_url
        }
        |> maybe_add("paymentAmount", pr.payment_amount)
        |> maybe_add("multiPayment", pr.multi_payment)
        |> maybe_add("paymentExpiryDatetime", pr.payment_expiry_datetime)
        |> maybe_add("metaData", if(pr.metadata == %{}, do: nil, else: pr.metadata))
        |> maybe_add("paymentNotification", pr.payment_notification)

      payment_request_status = %{
        "paymentRequestId" => pr.id,
        "status" => pr.status,
        "createdDateTime" => format_datetime(pr.inserted_at)
      }

      %{
        "PaymentRequest" => payment_request,
        "PaymentRequestStatus" => payment_request_status
      }
    end

    defp format_datetime(nil), do: nil
    defp format_datetime(datetime), do: DateTime.to_iso8601(datetime)

    defp maybe_add(map, _key, nil), do: map
    defp maybe_add(map, _key, false), do: map
    defp maybe_add(map, key, value), do: Map.put(map, key, value)
  end
end
