defmodule Azupay.Client.ErrorTest do
  use ExUnit.Case, async: true

  alias Azupay.Client.Error

  test "new(:unauthorized)" do
    error = Error.new(:unauthorized)
    assert error.type == :unauthorized
    assert error.status == 401
    assert Error.auth_error?(error)
  end

  test "new(:forbidden)" do
    error = Error.new(:forbidden)
    assert error.type == :forbidden
    assert error.status == 403
    refute Error.auth_error?(error)
  end

  test "new(:not_found)" do
    error = Error.new(:not_found)
    assert error.type == :not_found
    assert error.status == 404
  end

  test "new({:validation_error, details})" do
    details = %{"message" => "Invalid request", "details" => %{"failureCode" => "INVALID"}}
    error = Error.new({:validation_error, details})
    assert error.type == :validation_error
    assert error.status == 422
    assert error.details == details
    assert Error.validation_error?(error)
  end

  test "new({:client_error, status, body})" do
    error = Error.new({:client_error, 400, %{"message" => "Bad request"}})
    assert error.type == :client_error
    assert error.status == 400
    assert error.message =~ "Bad request"
  end

  test "new({:server_error, status, body})" do
    error = Error.new({:server_error, 500, %{"message" => "Internal error"}})
    assert error.type == :server_error
    assert error.status == 500
  end

  test "new({:request_failed, reason})" do
    error = Error.new({:request_failed, :timeout})
    assert error.type == :request_failed
    assert error.message =~ "timeout"
  end

  test "message/1 returns the message string" do
    error = Error.new(:unauthorized)
    assert Error.message(error) == "Unauthorized - invalid or missing API key"
  end

  test "validation_error?/1 returns false for non-validation errors" do
    refute Error.validation_error?(Error.new(:unauthorized))
  end
end
