if Code.ensure_loaded?(Ecto.Migration) do
  defmodule Azupay.MockServer.Migrations do
    @moduledoc """
    Migrations for the AzuPay mock server database tables.

    ## Usage

    Create a migration in your application:

        defmodule MyApp.Repo.Migrations.AddAzupayMockServer do
          use Ecto.Migration

          def up, do: Azupay.MockServer.Migrations.up(version: 1)
          def down, do: Azupay.MockServer.Migrations.down(version: 1)
        end

    Then run `mix ecto.migrate`.

    ## Options

      * `:version` - The migration version to run (required)
      * `:prefix` - Optional schema prefix for multi-tenant setups
    """

    use Ecto.Migration

    @doc """
    Run the up migration for the specified version.
    """
    def up(opts \\ []) do
      version = Keyword.fetch!(opts, :version)
      prefix = Keyword.get(opts, :prefix)

      migrate(version, :up, prefix)
    end

    @doc """
    Run the down migration for the specified version.
    """
    def down(opts \\ []) do
      version = Keyword.fetch!(opts, :version)
      prefix = Keyword.get(opts, :prefix)

      migrate(version, :down, prefix)
    end

    defp migrate(1, :up, prefix) do
      create_if_not_exists table(:azupay_mock_payment_requests,
                             primary_key: false,
                             prefix: prefix
                           ) do
        add(:id, :string, primary_key: true)
        add(:client_id, :string, null: false)
        add(:client_transaction_id, :string, null: false)
        add(:payment_description, :string, null: false)
        add(:pay_id, :string, null: false)
        add(:payment_amount, :float)
        add(:status, :string, null: false, default: "WAITING")
        add(:multi_payment, :boolean, default: false)
        add(:checkout_url, :string, null: false)
        add(:payment_expiry_datetime, :string)
        add(:metadata, :map, default: %{})
        add(:payment_notification, :map)

        timestamps(type: :utc_datetime)
      end

      create_if_not_exists(
        index(:azupay_mock_payment_requests, [:client_transaction_id], prefix: prefix)
      )

      create_if_not_exists(index(:azupay_mock_payment_requests, [:pay_id], prefix: prefix))
      create_if_not_exists(index(:azupay_mock_payment_requests, [:status], prefix: prefix))
    end

    defp migrate(1, :down, prefix) do
      drop_if_exists(table(:azupay_mock_payment_requests, prefix: prefix))
    end
  end
end
