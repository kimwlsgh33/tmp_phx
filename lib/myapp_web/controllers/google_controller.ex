defmodule MyappWeb.GoogleController do
  use MyappWeb, :controller
  plug Ueberauth

  alias Myapp.Accounts
  alias MyappWeb.UserAuth

  @doc """
  Handles the initial request to Google OAuth.
  Ueberauth will automatically redirect to the Google login page,
  but we render a loading template while the redirect happens.
  """
  def request(conn, _params) do
    IO.puts("\n----------------------------------------------")
    IO.puts("🔍 GoogleController.request/2 function called")
    IO.puts("----------------------------------------------\n")
    
    client_id = System.get_env("GOOGLE_CLIENT_ID")
    
    if is_nil(client_id) do
      IO.puts("⚠️  WARNING: GOOGLE_CLIENT_ID environment variable is NIL")
      IO.puts("    Make sure the environment variable is properly set")
      IO.puts("    Current environment variables:")
      System.get_env() |> Enum.filter(fn {k, _} -> String.contains?(k, "GOOGLE") end) |> IO.inspect(label: "Google-related env vars")
    else
      IO.puts("✅ GOOGLE_CLIENT_ID environment variable is set")
      IO.inspect(client_id, label: "🔑 Client ID value")
    end
    
    IO.puts("\n----------------------------------------------\n")
    conn
  end

  @doc """
  Handles the callback from Google OAuth.

  There are three scenarios:
  1. Authentication is successful - processes user data and logs them in
  2. Authentication fails with explicit error - displays the error message
  3. Other unexpected callback scenarios - displays a generic error
  """
  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case Accounts.register_oauth_user(auth) do
      {:ok, user} ->
        conn
        |> UserAuth.log_in_user(user)
        |> put_flash(:info, "Google로 성공적으로 로그인했습니다.")
        |> redirect(to: "/")

      {:error, :invalid_data} ->
        conn
        |> put_flash(:error, "Google 계정 데이터가 유효하지 않습니다.")
        |> redirect(to: ~p"/users/log_in")

      {:error, :account_creation_failed} ->
        conn
        |> put_flash(:error, "계정 생성 중 오류가 발생했습니다. 다시 시도해 주세요.")
        |> redirect(to: ~p"/users/log_in")

      {:error, reason} ->
        conn
        |> put_flash(:error, "로그인 실패: #{inspect(reason)}")
        |> redirect(to: ~p"/users/log_in")
    end
  end

  def callback(%{assigns: %{ueberauth_failure: failure}} = conn, _params) do
    error_message = extract_error_message(failure)

    conn
    |> put_flash(:error, "Google 로그인 실패: #{error_message}")
    |> redirect(to: ~p"/users/log_in")
  end

  def callback(conn, _params) do
    conn
    |> put_flash(:error, "Google 인증 중 문제가 발생했습니다. 다시 시도해 주세요.")
    |> redirect(to: ~p"/users/log_in")
  end

  @doc """
  Logs out the current user.
  """
  def delete(conn, _params) do
    conn
    |> UserAuth.log_out_user()
    |> put_flash(:info, "로그아웃되었습니다.")
    |> redirect(to: "/")
  end

  # Helper function to extract meaningful error messages from Ueberauth failure
  defp extract_error_message(%{errors: errors}) do
    errors
    |> Enum.map(fn %{message: message} -> message end)
    |> Enum.join(", ")
  end

  defp extract_error_message(_), do: "알 수 없는 오류"
end
