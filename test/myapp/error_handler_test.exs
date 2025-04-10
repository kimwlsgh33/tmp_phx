defmodule Myapp.ErrorHandlerTest do
  use ExUnit.Case, async: true
  
  alias Myapp.ErrorHandler
  
  describe "error/4" do
    test "creates a standard error struct" do
      error = ErrorHandler.error(:not_found, "Resource not found")
      
      assert error.type == :not_found
      assert error.message == "Resource not found"
      assert error.details == %{}
      assert error.source == nil
      assert %DateTime{} = error.timestamp
    end
    
    test "includes details and source when provided" do
      details = %{resource_id: 123}
      source = Myapp.Accounts
      
      error = ErrorHandler.error(:not_found, "User not found", details, source)
      
      assert error.type == :not_found
      assert error.message == "User not found"
      assert error.details == details
      assert error.source == source
      assert %DateTime{} = error.timestamp
    end
  end
  
  describe "normalize/1" do
    test "passes through :ok tuples" do
      assert ErrorHandler.normalize({:ok, "value"}) == {:ok, "value"}
    end
    
    test "normalizes atom error reasons" do
      {:error, error} = ErrorHandler.normalize({:error, :not_found})
      
      assert error.type == :not_found
      assert error.message == "Resource not found"
    end
    
    test "normalizes string error reasons" do
      {:error, error} = ErrorHandler.normalize({:error, "Something went wrong"})
      
      assert error.type == :system_error
      assert error.message == "Something went wrong"
    end
    
    test "normalizes map error reasons" do
      original_error = %{"error" => "API error", "code" => 400}
      {:error, error} = ErrorHandler.normalize({:error, original_error})
      
      assert error.type == :api_error
      assert error.message =~ "API error"
      assert error.details.response == original_error
    end
    
    test "normalizes HTTPoison errors" do
      http_error = %HTTPoison.Error{reason: :timeout}
      {:error, error} = ErrorHandler.normalize({:error, http_error})
      
      assert error.type == :http_error
      assert error.message =~ "HTTP request failed"
      assert error.details.reason == :timeout
    end
    
    test "handles non-standard inputs" do
      {:error, error} = ErrorHandler.normalize("unexpected input")
      
      assert error.type == :unknown_error
      assert error.message =~ "Unknown error"
    end
  end
  
  describe "handle/3" do
    test "adds source to error if not present" do
      error = ErrorHandler.error(:not_found, "Resource not found")
      source = Myapp.Accounts
      
      {:error, handled_error} = ErrorHandler.handle(error, source)
      
      assert handled_error.source == source
    end
    
    test "preserves existing source" do
      original_source = Myapp.Content
      error = ErrorHandler.error(:not_found, "Resource not found", %{}, original_source)
      new_source = Myapp.Accounts
      
      {:error, handled_error} = ErrorHandler.handle(error, new_source)
      
      assert handled_error.source == original_source
    end
    
    test "adds context to details" do
      error = ErrorHandler.error(:not_found, "Resource not found")
      context = %{request_id: "abc123"}
      
      {:error, handled_error} = ErrorHandler.handle(error, nil, context)
      
      assert handled_error.details.request_id == "abc123"
    end
    
    test "normalizes non-standard errors" do
      {:error, handled_error} = ErrorHandler.handle(:not_found, Myapp.Accounts)
      
      assert handled_error.type == :not_found
      assert handled_error.message == "Resource not found"
      assert handled_error.source == Myapp.Accounts
    end
  end
  
  describe "user_message/1" do
    test "returns the error message for simple errors" do
      error = ErrorHandler.error(:not_found, "User not found")
      
      assert ErrorHandler.user_message(error) == "User not found"
    end
    
    test "formats validation errors with field details" do
      error = ErrorHandler.error(
        :validation_error,
        "Validation failed",
        %{fields: %{email: "invalid format", password: "too short"}}
      )
      
      message = ErrorHandler.user_message(error)
      
      assert message =~ "Validation failed"
      assert message =~ "email (invalid format)"
      assert message =~ "password (too short)"
    end
    
    test "normalizes non-standard errors" do
      assert ErrorHandler.user_message(:not_found) =~ "Resource not found"
    end
  end
end
