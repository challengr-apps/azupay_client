defmodule Azupay.Client.Reports do
  @moduledoc """
  Report resource operations for the AzuPay API.

  Retrieve lists of available reports and obtain time-limited download URLs.
  """

  alias Azupay.Client
  alias Azupay.Client.Request

  @doc """
  Lists available reports.

  The `clientId` param is required. Then provide either `month` + `timezone`,
  or `fromDate` + `toDate`.

  ## Examples

      # By month
      {:ok, reports} = Azupay.Client.Reports.list(client,
        clientId: "my-client-id",
        month: "2026-01",
        timezone: "Australia/Sydney"
      )

      # By date range
      {:ok, reports} = Azupay.Client.Reports.list(client,
        clientId: "my-client-id",
        fromDate: "2026-01-01T00:00:00+11:00",
        toDate: "2026-01-31T23:59:59+11:00"
      )
  """
  @spec list(Client.t(), keyword()) :: Request.response()
  def list(client, params \\ []) do
    Request.get(client, "/report", params: params)
  end

  @doc """
  Gets a time-limited download URL for a report.

  ## Examples

      {:ok, download} = Azupay.Client.Reports.download_url(client, "my-client-id", "report-123")
  """
  @spec download_url(Client.t(), String.t(), String.t()) :: Request.response()
  def download_url(client, client_id, report_id) do
    Request.get(client, "/report/download", params: [clientId: client_id, reportId: report_id])
  end
end
