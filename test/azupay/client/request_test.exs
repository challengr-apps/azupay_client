defmodule Azupay.Client.RequestTest do
  use ExUnit.Case, async: true

  alias Azupay.Client
  alias Azupay.Client.Request

  defp build_client(plug) do
    Client.new(
      environment: :uat,
      api_key: "test_key",
      client_id: "test_client_id",
      base_url: "http://localhost",
      req_options: [plug: plug]
    )
  end

  test "successful POST returns {:ok, body}" do
    plug = fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(201, Jason.encode!(%{"id" => "123"}))
    end

    client = build_client(plug)
    assert {:ok, %{"id" => "123"}} = Request.post(client, "/test", json: %{})
  end

  test "sets authorization header to raw api_key" do
    plug = fn conn ->
      [auth] = Plug.Conn.get_req_header(conn, "authorization")
      body = Jason.encode!(%{"auth" => auth})

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(200, body)
    end

    client = build_client(plug)
    assert {:ok, %{"auth" => "test_key"}} = Request.get(client, "/test")
  end

  test "401 returns {:error, :unauthorized}" do
    plug = fn conn -> Plug.Conn.send_resp(conn, 401, "") end
    client = build_client(plug)
    assert {:error, :unauthorized} = Request.get(client, "/test")
  end

  test "403 returns {:error, :forbidden}" do
    plug = fn conn -> Plug.Conn.send_resp(conn, 403, "") end
    client = build_client(plug)
    assert {:error, :forbidden} = Request.get(client, "/test")
  end

  test "404 returns {:error, :not_found}" do
    plug = fn conn -> Plug.Conn.send_resp(conn, 404, "") end
    client = build_client(plug)
    assert {:error, :not_found} = Request.get(client, "/test")
  end

  test "422 returns {:error, {:validation_error, body}}" do
    body = %{"message" => "Validation failed", "details" => %{"failureCode" => "INVALID"}}

    plug = fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(422, Jason.encode!(body))
    end

    client = build_client(plug)
    assert {:error, {:validation_error, ^body}} = Request.get(client, "/test")
  end

  test "500 returns {:error, {:server_error, 500, body}}" do
    plug = fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(500, Jason.encode!(%{"message" => "Internal error"}))
    end

    client = build_client(plug)
    assert {:error, {:server_error, 500, _body}} = Request.get(client, "/test")
  end

  test "builds URL with leading slash" do
    plug = fn conn ->
      body = Jason.encode!(%{"path" => conn.request_path})

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(200, body)
    end

    client = build_client(plug)
    assert {:ok, %{"path" => "/test"}} = Request.get(client, "test")
  end
end
