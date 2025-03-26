defmodule MyappWeb.UserSessionController do
  use MyappWeb, :controller

  alias Myapp.Accounts
  alias Myapp.Accounts.LinkedAccount
  alias MyappWeb.UserAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:user_return_to, ~p"/users/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"user" => user_params}, info) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> UserAuth.log_in_user(user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/users/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end

  def link_account(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params
    current_user = conn.assigns.current_user

    if user = Accounts.get_user_by_email_and_password(email, password) do
      if user.id == current_user.id do
        conn
        |> put_flash(:error, "You cannot link your account to itself.")
        |> redirect(to: ~p"/")
      else
        linked_accounts = Accounts.list_linked_accounts(current_user)
        if length(linked_accounts) >= 3 do
          conn
          |> put_flash(:error, "You can link a maximum of 3 accounts")
          |> redirect(to: ~p"/")
        else
          case Accounts.link_account(current_user, user) do
          {:ok, _linked_account} ->
            conn
            |> put_flash(:info, "Account linked successfully!")
            |> UserAuth.log_in_user(user)

          {:error, %Ecto.Changeset{} = changeset} ->
            error_message = if Enum.any?(changeset.errors, fn {field, _} -> field == :linked_user_id end) do
              "This account is already linked to your account."
            else
              "Failed to link account. Please try again."
            end

            conn
            |> put_flash(:error, error_message)
            |> redirect(to: ~p"/")
          end
        end
      end
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/")
    end
  end

  def switch_account(conn, %{"linked_user_id" => linked_user_id}) do
    current_user = conn.assigns.current_user
    
    case Accounts.switch_to_linked_account(current_user, linked_user_id) do
      {:ok, token, linked_user} ->
        conn
        |> put_flash(:info, "Switched to #{linked_user.email} account")
        |> UserAuth.log_in_user(linked_user, %{"remember_me" => "true"}, token)
        
      {:error, :not_linked} ->
        conn
        |> put_flash(:error, "The account you're trying to switch to is not linked to your account")
        |> redirect(to: ~p"/")
        
      {:error, :user_not_found} ->
        conn
        |> put_flash(:error, "The linked account was not found")
        |> redirect(to: ~p"/")
    end
  end
end
