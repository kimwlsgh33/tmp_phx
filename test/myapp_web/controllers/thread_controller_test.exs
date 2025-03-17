defmodule MyappWeb.ThreadControllerTest do
  use MyappWeb.ConnCase

  import Mox
  
  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  # Setup for JSON API requests
  setup %{conn: conn} do
    conn = conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")
    
    {:ok, conn: conn}
  end

  # Mock the Threads module
  setup do
    # Define the path to the mock module in the test configuration
    Application.put_env(:myapp, :threads_module, Myapp.MockThreads)
    
    # This is important for controller tests to know which module to use
    :ok
  end

  describe "create/2" do
    test "creates and returns a thread when data is valid", %{conn: conn} do
      # Define the response from the mock
      thread_response = %{
        "id" => "123456789",
        "text" => "Hello, world!",
        "created_at" => "2023-04-01T12:00:00Z"
      }
      
      # Setup the mock expectation
      expect(Myapp.MockThreads, :create_thread, fn "Hello, world!" -> 
        {:ok, thread_response} 
      end)
      
      # Make the request
      conn = post(conn, ~p"/api/threads", %{text: "Hello, world!"})
      
      # Assert on the response
      assert json_response(conn, 201) == thread_response
    end
    
    test "returns error when text is empty", %{conn: conn} do
      # Setup the mock expectation
      expect(Myapp.MockThreads, :create_thread, fn "" -> 
        {:error, "Text is required"} 
      end)
      
      # Make the request
      conn = post(conn, ~p"/api/threads", %{text: ""})
      
      # Assert on the response
      assert json_response(conn, 422) == %{"errors" => %{"detail" => "Text is required"}}
    end
    
    test "returns error when text is missing", %{conn: conn} do
      # Make the request without text parameter
      conn = post(conn, ~p"/api/threads", %{})
      
      # Assert on the response
      assert json_response(conn, 400) == %{"errors" => %{"detail" => "Bad Request"}}
    end

    test "handles API errors properly", %{conn: conn} do
      api_error = %{"error" => %{"message" => "Service temporarily unavailable", "code" => 1}}
      
      # Setup the mock expectation
      expect(Myapp.MockThreads, :create_thread, fn _text -> 
        {:error, api_error} 
      end)
      
      # Make the request
      conn = post(conn, ~p"/api/threads", %{text: "Hello, world!"})
      
      # Assert on the response
      assert json_response(conn, 422) == %{"errors" => %{"detail" => api_error}}
    end
  end
  
  describe "show/2" do
    test "returns thread when it exists", %{conn: conn} do
      thread_id = "123456789"
      thread_response = %{
        "id" => thread_id,
        "text" => "Hello, world!",
        "created_at" => "2023-04-01T12:00:00Z",
        "replies" => []
      }
      
      # Setup the mock expectation
      expect(Myapp.MockThreads, :get_thread, fn ^thread_id -> 
        {:ok, thread_response} 
      end)
      
      # Make the request
      conn = get(conn, ~p"/api/threads/#{thread_id}")
      
      # Assert on the response
      assert json_response(conn, 200) == thread_response
    end
    
    test "returns error when thread does not exist", %{conn: conn} do
      thread_id = "nonexistent"
      error_response = %{"error" => %{"message" => "Thread not found", "code" => 404}}
      
      # Setup the mock expectation
      expect(Myapp.MockThreads, :get_thread, fn ^thread_id -> 
        {:error, error_response} 
      end)
      
      # Make the request
      conn = get(conn, ~p"/api/threads/#{thread_id}")
      
      # Assert on the response
      assert json_response(conn, 422) == %{"errors" => %{"detail" => error_response}}
    end
    
    test "returns error when thread ID is invalid", %{conn: conn} do
      thread_id = nil
      
      # Setup the mock expectation
      expect(Myapp.MockThreads, :get_thread, fn nil -> 
        {:error, "Thread ID is required"} 
      end)
      
      # Make the request (the router will coerce nil to a string)
      conn = get(conn, ~p"/api/threads/nil")
      
      # Assert on the response
      assert json_response(conn, 422) == %{"errors" => %{"detail" => "Thread ID is required"}}
    end
  end
  
  describe "reply/2" do
    test "creates and returns a reply when data is valid", %{conn: conn} do
      thread_id = "123456789"
      reply_text = "This is a reply"
      reply_response = %{
        "id" => "987654321",
        "thread_id" => thread_id,
        "text" => reply_text,
        "created_at" => "2023-04-01T12:30:00Z"
      }
      
      # Setup the mock expectation
      expect(Myapp.MockThreads, :reply_to_thread, fn ^thread_id, ^reply_text -> 
        {:ok, reply_response} 
      end)
      
      # Make the request
      conn = post(conn, ~p"/api/threads/#{thread_id}/reply", %{text: reply_text})
      
      # Assert on the response
      assert json_response(conn, 201) == reply_response
    end
    
    test "returns error when reply text is empty", %{conn: conn} do
      thread_id = "123456789"
      
      # Setup the mock expectation
      expect(Myapp.MockThreads, :reply_to_thread, fn ^thread_id, "" -> 
        {:error, "Thread ID and text are required"} 
      end)
      
      # Make the request
      conn = post(conn, ~p"/api/threads/#{thread_id}/reply", %{text: ""})
      
      # Assert on the response
      assert json_response(conn, 422) == %{"errors" => %{"detail" => "Thread ID and text are required"}}
    end
    
    test "returns error when thread does not exist", %{conn: conn} do
      thread_id = "nonexistent"
      reply_text = "This is a reply"
      error_response = %{"error" => %{"message" => "Thread not found", "code" => 404}}
      
      # Setup the mock expectation
      expect(Myapp.MockThreads, :reply_to_thread, fn ^thread_id, ^reply_text -> 
        {:error, error_response} 
      end)
      
      # Make the request
      conn = post(conn, ~p"/api/threads/#{thread_id}/reply", %{text: reply_text})
      
      # Assert on the response
      assert json_response(conn, 422) == %{"errors" => %{"detail" => error_response}}
    end
    
    test "returns error when text is missing", %{conn: conn} do
      thread_id = "123456789"
      
      # Make the request without text parameter
      conn = post(conn, ~p"/api/threads/#{thread_id}/reply", %{})
      
      # Assert on the response
      assert json_response(conn, 400) == %{"errors" => %{"detail" => "Bad Request"}}
    end
  end
  
  describe "delete/2" do
    test "deletes a thread when it exists", %{conn: conn} do
      thread_id = "123456789"
      success_response = %{"success" => true}
      
      # Setup the mock expectation
      expect(Myapp.MockThreads, :delete_thread, fn ^thread_id -> 
        {:ok, success_response} 
      end)
      
      # Make the request
      conn = delete(conn, ~p"/api/threads/#{thread_id}")
      
      # Assert on the response (No Content is 204)
      assert response(conn, 204) == ""
    end
    
    test "returns error when thread does not exist", %{conn: conn} do
      thread_id = "nonexistent"
      error_response = %{"error" => %{"message" => "Thread not found", "code" => 404}}
      
      # Setup the mock expectation
      expect(Myapp.MockThreads, :delete_thread, fn ^thread_id -> 
        {:error, error_response} 
      end)
      
      # Make the request
      conn = delete(conn, ~p"/api/threads/#{thread_id}")
      
      # Assert on the response
      assert json_response(conn, 422) == %{"errors" => %{"detail" => error_response}}
    end
    
    test "returns error when thread ID is invalid", %{conn: conn} do
      thread_id = nil
      
      # Setup the mock expectation
      expect(Myapp.MockThreads, :delete_thread, fn nil -> 
        {:error, "Thread ID is required"} 
      end)
      
      # Make the request (the router will coerce nil to a string)
      conn = delete(conn, ~p"/api/threads/nil")
      
      # Assert on the response
      assert json_response(conn, 422) == %{"errors" => %{"detail" => "Thread ID is required"}}
    end
  end
end

