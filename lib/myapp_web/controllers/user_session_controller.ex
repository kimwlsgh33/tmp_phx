defmodule MyappWeb.UserSessionController do
  use MyappWeb, :controller
  #
  alias Myapp.Accounts
  alias Myapp.Accounts.LinkedAccount
  alias MyappWeb.UserAuth

  # Redirect to login screen with link parameter
  def new_link(conn, _params) do
    # Redirect to the login LiveView with link=true parameter
    redirect(conn, to: ~p"/users/log_in?link=true")
  end
  
  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:user_return_to, ~p"/users/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    IO.puts("UserSessionController create called with params: #{inspect(params)}")
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"user" => user_params} = params, info) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      # If 'link=true' is in the params, call link_account instead
      if Map.get(params, "link") == "true" do
        link_account(conn, params)
      else
        conn
        |> put_flash(:info, info)
        |> UserAuth.log_in_user(user, user_params)
      end
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/users/log_in")
    end
  end

  #
  def delete(conn, params) do
    logout_user_id = Map.get(params, "logout_user_id")

    # Get the referer (previous page) for better redirects
    referer_path = get_referer_path(conn)

    if logout_user_id && logout_user_id != "current" do
      # Handle logout for a linked account case
      # Handle logout for a linked account case
      try do
        linked_user = Accounts.get_user!(logout_user_id)

        # Verify this is actually a linked account of the current user
        current_user = conn.assigns.current_user

        case Accounts.unlink_account(current_user, linked_user.id) do
          {:ok, _} ->
            conn
            |> put_flash(:info, "Account #{linked_user.email} has been unlinked.")
            |> redirect(to: referer_path)

          {:error, :not_found} ->
            conn
            |> put_flash(:error, "This account is not linked to your account.")
            |> redirect(to: referer_path)
        end
      rescue
        Ecto.NoResultsError ->
          conn
          |> put_flash(:error, "Account not found")
          |> redirect(to: referer_path)
      end
    else
      # Default behavior - sign out current user
      conn
      |> put_flash(:info, "Logged out successfully.")
      |> UserAuth.log_out_user()
    end
  end

  # Helper function to safely extract just the path from the referer URL
  defp get_referer_path(conn) do
    case get_req_header(conn, "referer") |> List.first() do
      # Default path if no referer
      nil ->
        "/"

      referer ->
        # Parse the URL and extract just the path component
        uri = URI.parse(referer)

        case uri do
          %URI{path: nil} ->
            "/"

          %URI{path: path} ->
            # Add query string if present
            if uri.query do
              "#{path}?#{uri.query}"
            else
              path
            end

          # Default path if parsing fails
          _ ->
            "/"
        end
    end
  end

  def new(conn, params) do
    # Extract link parameter from query string
    link_param = Map.get(params, "link")
    render(conn, :new, error_message: nil, page_title: "Log in", link: link_param)
  end

  #
  def link_account(conn, %{"user" => user_params} = params) do
    IO.puts("UserSessionController link_account called with params: #{inspect(params)}")
    %{"email" => email, "password" => password} = user_params
    current_user = conn.assigns.current_user

    # Extract return_to from params if it exists, otherwise default to "/"
    return_to = Map.get(params, "return_to", "/")

    # Store return_to in session
    conn = put_session(conn, :user_return_to, return_to)

    if user = Accounts.get_user_by_email_and_password(email, password) do
      if user.id == current_user.id do
        conn
        |> put_flash(:error, "You cannot link your account to itself.")
        |> redirect(to: return_to)
      else
        linked_accounts = Accounts.list_linked_accounts(current_user)

        if length(linked_accounts) > 3 do
          conn
          |> put_flash(:error, "You can link a maximum of 3 accounts")
          |> redirect(to: return_to)
        else
          case Accounts.link_account(current_user, user) do
            {:ok, _linked_account} ->
              conn
              |> put_flash(:info, "Account linked successfully!")
              |> UserAuth.log_in_user(user, %{"remember_me" => "true"})

            {:error, %Ecto.Changeset{} = changeset} ->
              error_message =
                if Enum.any?(changeset.errors, fn {field, _} -> field == :linked_user_id end) do
                  "This account is already linked to your account."
                else
                  "Failed to link account. Please try again."
                end

              conn
              |> put_flash(:error, error_message)
              |> redirect(to: return_to)
          end
        end
      end
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: return_to)
    end
  end

  #
  def switch_account(conn, %{"linked_user_id" => linked_user_id}) do
    current_user = conn.assigns.current_user

    case Accounts.switch_to_linked_account(current_user, linked_user_id) do
      {:ok, token, linked_user} ->
        conn
        |> put_flash(:info, "Switched to #{linked_user.email} account")
        |> UserAuth.log_in_user(linked_user, %{"remember_me" => "true"}, token)

      {:error, :not_linked} ->
        conn
        |> put_flash(
          :error,
          "The account you're trying to switch to is not linked to your account"
        )
        |> redirect(to: ~p"/")

      {:error, :user_not_found} ->
        conn
        |> put_flash(:error, "The linked account was not found")
        |> redirect(to: ~p"/")
    end
  end
end
