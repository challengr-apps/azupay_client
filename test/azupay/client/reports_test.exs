defmodule Azupay.Client.ReportsTest do
  use ExUnit.Case, async: true

  alias Azupay.Client
  alias Azupay.Client.Reports

  defp build_client(plug) do
    Client.new(
      environment: :uat,
      api_key: "test_key",
      client_id: "test_client_id",
      base_url: "http://localhost",
      req_options: [plug: plug]
    )
  end

  describe "list/2" do
    test "sends GET to /report with query params" do
      response_body = [%{"reportId" => "rpt-123", "name" => "Monthly Report"}]

      plug = fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/report"

        query = URI.decode_query(conn.query_string)
        assert query["month"] == "2026-01"
        assert query["timezone"] == "Australia/Sydney"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response_body))
      end

      client = build_client(plug)

      assert {:ok, ^response_body} =
               Reports.list(client, month: "2026-01", timezone: "Australia/Sydney")
    end
  end

  describe "download_url/3" do
    test "sends GET to /report/download with clientId and reportId query params" do
      response_body = %{"downloadUrl" => "https://storage.example.com/report.csv"}

      plug = fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/report/download"

        query = URI.decode_query(conn.query_string)
        assert query["clientId"] == "my-client"
        assert query["reportId"] == "rpt-123"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response_body))
      end

      client = build_client(plug)
      assert {:ok, ^response_body} = Reports.download_url(client, "my-client", "rpt-123")
    end
  end
end
