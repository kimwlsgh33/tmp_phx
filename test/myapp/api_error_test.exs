defmodule Myapp.ApiErrorTest do
  use ExUnit.Case, async: true
  
  alias Myapp.ApiError
  
  describe "handle_response/4" do
    test "handles successful responses" do
      body = ~s({"data": {"id": "123"}})
      
      assert {:ok, %{"data" => %{"id" => "123"}}} = ApiError.handle_response(200, body, :twitter)
    end
    
    test "handles unauthorized errors" do
      body = ~s({"errors": [{"message": "Unauthorized", "code": 32}]})
      
      {:error, error} = ApiError.handle_response(401, body, :twitter)
      
      assert error.type == :unauthorized
      assert error.message == "Unauthorized"
      assert error.details.provider == :twitter
      assert error.details.status_code == 401
    end
    
    test "handles not found errors" do
      body = ~s({"errors": [{"message": "Resource not found", "code": 34}]})
      
      {:error, error} = ApiError.handle_response(404, body, :twitter)
      
      assert error.type == :not_found
      assert error.message == "Resource not found"
      assert error.details.provider == :twitter
      assert error.details.status_code == 404
    end
    
    test "handles rate limit errors" do
      body = ~s({"errors": [{"message": "Rate limit exceeded", "code": 88}]})
      
      {:error, error} = ApiError.handle_response(429, body, :twitter)
      
      assert error.type == :rate_limited
      assert error.message == "Rate limit exceeded"
      assert error.details.provider == :twitter
      assert error.details.status_code == 429
    end
    
    test "handles server errors" do
      body = ~s({"errors": [{"message": "Internal server error", "code": 500}]})
      
      {:error, error} = ApiError.handle_response(500, body, :twitter)
      
      assert error.type == :service_unavailable
      assert error.message == "Internal server error"
      assert error.details.provider == :twitter
      assert error.details.status_code == 500
    end
    
    test "includes context in error details" do
      body = ~s({"errors": [{"message": "Not found", "code": 34}]})
      context = %{resource_id: 123}
      
      {:error, error} = ApiError.handle_response(404, body, :twitter, context)
      
      assert error.details.resource_id == 123
    end
    
    test "handles non-JSON responses" do
      body = "Internal Server Error"
      
      {:error, error} = ApiError.handle_response(500, body, :twitter)
      
      assert error.type == :service_unavailable
      assert error.message =~ "API error with status code 500"
      assert error.details.provider == :twitter
      assert error.details.body == body
    end
  end
  
  describe "handle_http_error/3" do
    test "handles timeout errors" do
      error = %HTTPoison.Error{reason: :timeout}
      
      {:error, handled_error} = ApiError.handle_http_error(error, :twitter)
      
      assert handled_error.type == :timeout
      assert handled_error.message == "API request timed out"
      assert handled_error.details.provider == :twitter
      assert handled_error.details.reason == :timeout
    end
    
    test "handles connection refused errors" do
      error = %HTTPoison.Error{reason: :econnrefused}
      
      {:error, handled_error} = ApiError.handle_http_error(error, :twitter)
      
      assert handled_error.type == :service_unavailable
      assert handled_error.message == "Connection refused by the server"
      assert handled_error.details.provider == :twitter
      assert handled_error.details.reason == :econnrefused
    end
    
    test "handles other HTTP errors" do
      error = %HTTPoison.Error{reason: :nxdomain}
      
      {:error, handled_error} = ApiError.handle_http_error(error, :twitter)
      
      assert handled_error.type == :http_error
      assert handled_error.message =~ "HTTP request failed"
      assert handled_error.details.provider == :twitter
      assert handled_error.details.reason == :nxdomain
    end
    
    test "includes context in error details" do
      error = %HTTPoison.Error{reason: :timeout}
      context = %{endpoint: "/tweets"}
      
      {:error, handled_error} = ApiError.handle_http_error(error, :twitter, context)
      
      assert handled_error.details.endpoint == "/tweets"
    end
  end
  
  describe "normalize_error/3" do
    test "normalizes Twitter errors" do
      body = ~s({"errors": [{"message": "Rate limit exceeded", "code": 88}]})
      
      error = ApiError.normalize_error(429, body, :twitter)
      
      assert error.type == :rate_limited
      assert error.message == "Rate limit exceeded"
      assert error.details.provider == :twitter
      assert error.details.error_code == 88
    end
    
    test "normalizes TikTok errors" do
      body = ~s({"error_code": 10002, "error_message": "Rate limit reached"})
      
      error = ApiError.normalize_error(429, body, :tiktok)
      
      assert error.type == :rate_limited
      assert error.message == "Rate limit reached"
      assert error.details.provider == :tiktok
      assert error.details.error_code == 10002
    end
    
    test "normalizes Instagram/Facebook errors" do
      body = ~s({"error": {"type": "OAuthException", "message": "Invalid OAuth access token", "code": 190}})
      
      error = ApiError.normalize_error(401, body, :instagram)
      
      assert error.type == :token_expired
      assert error.message == "Invalid OAuth access token"
      assert error.details.provider == :instagram
      assert error.details.error_code == 190
    end
    
    test "normalizes YouTube/Google errors" do
      body = ~s({"error": {"errors": [{"reason": "rateLimitExceeded", "message": "Rate limit exceeded"}], "code": 429}})
      
      error = ApiError.normalize_error(429, body, :youtube)
      
      assert error.type == :rate_limited
      assert error.message == "Rate limit exceeded"
      assert error.details.provider == :youtube
      assert error.details.reason == "rateLimitExceeded"
    end
    
    test "handles non-JSON responses" do
      body = "Internal Server Error"
      
      error = ApiError.normalize_error(500, body, :twitter)
      
      assert error.type == :service_unavailable
      assert error.message =~ "API error with status code 500"
      assert error.details.provider == :twitter
      assert error.details.body == body
    end
    
    test "handles unknown API formats" do
      body = ~s({"unknown_format": true, "message": "Some error"})
      
      error = ApiError.normalize_error(400, body, :unknown_provider)
      
      assert error.type == :bad_request
      assert error.message == "Some error"
      assert error.details.provider == :unknown_provider
    end
  end
end
