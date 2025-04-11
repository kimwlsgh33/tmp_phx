defmodule MyappWeb.Plugs.SentryContext do
  @moduledoc """
  A plug that sets Sentry context information for the current request.
  
  This plug should be placed after authentication plugs to ensure
  user information is available.
  """
  
  @behaviour Plug
  
  import Plug.Conn
  alias Myapp.Monitoring.Sentry
  
  @doc """
  Initialize the plug with options.
  """
  def init(opts), do: opts
  
  @doc """
  Set Sentry context information for the current request.
  """
  def call(conn, _opts) do
    # Set request context
    Sentry.set_request_context(conn)
    
    # Set user context if available
    if conn.assigns[:current_user] do
      Sentry.set_user_context(conn.assigns.current_user)
    end
    
    # Add request ID to tags
    request_id = List.first(get_req_header(conn, "x-request-id"))
    if request_id do
      Sentry.Context.set_tags_context(%{request_id: request_id})
    end
    
    # Continue with the connection
    conn
  end
end
