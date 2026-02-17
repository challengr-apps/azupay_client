defmodule Azupay.Client.AccountsTest do
  use ExUnit.Case, async: true

  alias Azupay.Client
  alias Azupay.Client.Accounts

  defp build_client(plug) do
    Client.new(
      environment: :uat,
      api_key: "test_key",
      client_id: "test_client_id",
      base_url: "http://localhost",
      req_options: [plug: plug]
    )
  end

  describe "check_bsb/2" do
    test "sends POST to /accountEnquiry with BSB" do
      response_body = %{
        "AccountStatus" => %{
          "nppReachable" => true,
          "paytoReachable" => true,
          "accountServices" => ["x2p1"]
        }
      }

      plug = fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/accountEnquiry"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert %{"bsb" => "012306"} = decoded

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response_body))
      end

      client = build_client(plug)
      assert {:ok, ^response_body} = Accounts.check_bsb(client, %{"bsb" => "012306"})
    end
  end

  describe "check_payid/2" do
    test "sends POST to /payIDEnquiry with PayID details" do
      response_body = %{
        "AccountStatus" => %{
          "nppReachable" => true,
          "paytoReachable" => true,
          "aliasName" => "Jane's Account"
        }
      }

      plug = fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/payIDEnquiry"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert %{"payID" => "jane@example.com", "payIDType" => "EMAIL"} = decoded

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response_body))
      end

      client = build_client(plug)

      assert {:ok, ^response_body} =
               Accounts.check_payid(client, %{
                 "payID" => "jane@example.com",
                 "payIDType" => "EMAIL"
               })
    end
  end

  describe "check_account/2" do
    test "sends POST to /accountCheck with CoP details" do
      response_body = %{
        "accountCheckResultCode" => "MTCH",
        "accountCheckResult" => "Match",
        "displayAccountName" => "Jane Smith"
      }

      plug = fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/accountCheck"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert %{"accountCheckId" => "check-001", "bsb" => "012306"} = decoded

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response_body))
      end

      client = build_client(plug)

      assert {:ok, ^response_body} =
               Accounts.check_account(client, %{
                 "accountCheckId" => "check-001",
                 "bsb" => "012306",
                 "accountNumber" => "123456789",
                 "accountName" => "Jane Smith",
                 "purposeCode" => "PYMT",
                 "additionalDetails" => %{
                   "endUserId" => "user-1",
                   "endUserSessionId" => "session-1"
                 }
               })
    end
  end
end
