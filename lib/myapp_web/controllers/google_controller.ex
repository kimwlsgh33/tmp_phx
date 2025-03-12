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
        |> put_flash(:info, "Google로 성공적으로 로그인했습니다.")
        |> UserAuth.log_in_user(user)

      {:error, :invalid_data} ->
        conn
        |> put_flash(:error, "Google 계정 데이터가 유효하지 않습니다.")
        |> redirect(to: ~p"/users/log_in")

      {:error, :account_creation_failed} ->
        conn
        |> put_flash(:error, "계정 생성 중 오류가 발생했습니다. 다시 시도해 주세요.")
        |> redirect(to: ~p"/users/log_in")

      {:error, changeset} when is_struct(changeset, Ecto.Changeset) ->
        errors = format_changeset_errors(changeset)
        conn
        |> put_flash(:error, "로그인 실패: #{errors}")
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

  # Helper to format changeset errors for display
  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.map(fn {key, value} -> "#{key}: #{Enum.join(value, ", ")}" end)
    |> Enum.join("; ")
  end
end
