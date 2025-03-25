defmodule Myapp.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Myapp.Repo

  alias Myapp.Accounts.{User, UserToken, UserNotifier, LinkedAccount}

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset =
      user
      |> User.email_changeset(%{email: email})
      |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm_email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &url(~p"/users/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_confirmation_instructions(confirmed_user, &url(~p"/users/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_user_confirmation_instructions(%User{} = user, _confirmation_url_fun \\ nil) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      # Generate a 6-letter confirmation code
      confirmation_code = generate_confirmation_code()
      
      # Update the user with the confirmation code
      {:ok, updated_user} =
        user
        |> User.confirmation_code_changeset(%{confirmation_code: confirmation_code})
        |> Repo.update()
      
      # Send the confirmation code via email
      UserNotifier.deliver_confirmation_instructions(updated_user, confirmation_code)
    end
  end
  
  # Generates a random 6-letter confirmation code
  defp generate_confirmation_code do
    # Generate 6 random uppercase letters
    for _ <- 1..6, into: "", do: <<Enum.random(?A..?Z)>>
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(email, confirmation_code) when is_binary(email) and is_binary(confirmation_code) do
    # First check if a user with this email exists
    case Repo.get_by(User, email: email) do
      nil -> 
        {:error, :user_not_found}
        
      %User{confirmed_at: confirmed_at} when not is_nil(confirmed_at) ->
        {:error, :already_confirmed}
        
      user ->
        # Now verify the confirmation code
        if user.confirmation_code == confirmation_code do
          {:ok, %{user: confirmed_user}} = Repo.transaction(confirm_user_multi(user))
          {:ok, confirmed_user}
        else
          {:error, :invalid_code}
        end
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user, %{confirmation_code: nil}))
    # We still delete any existing confirmation tokens for backward compatibility
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &url(~p"/users/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## OAuth Authentication

  @doc """
  Registers a user via OAuth authentication.

  This function processes a Ueberauth.Auth struct to extract relevant
  user information and create a new user account using the OAuth
  registration changeset.

  ## Examples

      iex> register_oauth_user(%Ueberauth.Auth{})
      {:ok, %User{}}

      iex> register_oauth_user(%Ueberauth.Auth{})
      {:error, %Ecto.Changeset{}}

  """
  def register_oauth_user(%Ueberauth.Auth{} = auth) do
    %{
      uid: uid,
      provider: provider,
      info: %{email: email, image: avatar_url}
    } = auth

    # Add debug logging
    require Logger
    Logger.debug("OAuth User Data - Email: #{email}, Provider: #{provider}, Avatar URL: #{avatar_url}")

    # Generate a secure random password for OAuth users
    random_password = generate_secure_password(32)

    # Prepare user attributes from OAuth data
    user_params = %{
      email: email,
      provider: to_string(provider),
      provider_id: uid,
      avatar_url: avatar_url,
      password: random_password
    }
    
    Logger.debug("User params being saved: #{inspect(user_params)}")

    # Try to find an existing user with this email
    case get_user_by_email(email) do
      # User exists - update their OAuth info if needed
      %User{} = user ->
        Logger.debug("Updating existing user with OAuth info")
        user
        |> User.oauth_changeset(user_params)
        |> Repo.update()

      # User doesn't exist - create a new one
      nil ->
        Logger.debug("Creating new user with OAuth info")
        %User{}
        |> User.oauth_registration_changeset(user_params)
        |> Repo.insert()
    end
  end

  # Generates a cryptographically secure random password
  defp generate_secure_password(length) do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64(padding: false)
    |> binary_part(0, length)
  end

  ## API

  @doc """
  Creates a new api token for a user.

  The token returned must be saved somewhere safe.
  This token cannot be recovered from the database.
  """
  def create_user_api_token(user) do
    # email_token : it will be expired if the user changes their email
    {encoded_token, user_token} = UserToken.build_email_token(user, "api-token")
    Repo.insert!(user_token)
    encoded_token
  end

  @doc """
  Fetches the user by API token.
  """
  def fetch_user_by_api_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "api-token"),
         %User{} = user <- Repo.one(query) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  ## Linked Accounts

  @doc """
  Links a secondary account to a primary user account.

  ## Examples

      iex> link_account(primary_user, linked_user)
      {:ok, %LinkedAccount{}}

      iex> link_account(primary_user, same_user)
      {:error, %Ecto.Changeset{}}
  """
  def link_account(%User{} = primary_user, %User{} = linked_user, attrs \\ %{}) do
    # Prevent linking to self
    if primary_user.id == linked_user.id do
      changeset = LinkedAccount.changeset(%LinkedAccount{}, %{})
      {:error, Ecto.Changeset.add_error(changeset, :linked_user_id, "cannot link to the same account")}
    else
      # Check if the link already exists
      case Repo.get_by(LinkedAccount, primary_user_id: primary_user.id, linked_user_id: linked_user.id) do
        %LinkedAccount{} = existing_link ->
          {:ok, existing_link}
        nil ->
          %LinkedAccount{}
          |> LinkedAccount.changeset(Map.merge(attrs, %{
              primary_user_id: primary_user.id,
              linked_user_id: linked_user.id
            }))
          |> Repo.insert()
      end
    end
  end

  @doc """
  Lists all linked accounts for a given user.

  ## Examples

      iex> list_linked_accounts(user)
      [%{user: %User{}, name: "Work Account"}, ...]
  """
  def list_linked_accounts(%User{} = user) do
    query = from la in LinkedAccount,
            where: la.primary_user_id == ^user.id and la.linked_user_id != ^user.id,
            join: u in User, on: la.linked_user_id == u.id,
            select: %{
              id: la.id,
              user: u,
              name: la.name
            }
            
    Repo.all(query)
  end

  @doc """
  Removes a link between accounts.

  ## Examples

      iex> unlink_account(primary_user, linked_user_id)
      {:ok, %LinkedAccount{}}

      iex> unlink_account(primary_user, non_existent_id)
      {:error, :not_found}
  """
  def unlink_account(%User{} = primary_user, linked_user_id) do
    case Repo.get_by(LinkedAccount, primary_user_id: primary_user.id, linked_user_id: linked_user_id) do
      nil ->
        {:error, :not_found}
      link ->
        Repo.delete(link)
    end
  end

  @doc """
  Switches the current session to use a linked account.
  Returns the session token for the linked account if successful.

  ## Examples

      iex> switch_to_linked_account(current_user, linked_user_id)
      {:ok, "new_session_token", %User{}}

      iex> switch_to_linked_account(current_user, non_linked_id)
      {:error, :not_linked}
  """
  def switch_to_linked_account(%User{} = current_user, linked_user_id) do
    # First verify that this is a valid link
    case Repo.get_by(LinkedAccount, primary_user_id: current_user.id, linked_user_id: linked_user_id) do
      nil ->
        {:error, :not_linked}
      _link ->
        # Get the linked user
        linked_user = Repo.get(User, linked_user_id)
        
        case linked_user do
          nil ->
            {:error, :user_not_found}
          linked_user ->
            # Create a complete graph of linked accounts
            
            # 1. Get all accounts linked to the current user
            current_user_links_query = from la in LinkedAccount,
                                      where: la.primary_user_id == ^current_user.id,
                                      select: la.linked_user_id
            current_user_linked_ids = Repo.all(current_user_links_query)
            
            # 2. Get all accounts linked to the target user
            linked_user_links_query = from la in LinkedAccount,
                                     where: la.primary_user_id == ^linked_user_id,
                                     select: la.linked_user_id
            linked_user_linked_ids = Repo.all(linked_user_links_query)
            
            # 3. Add the current user and target user to their respective groups
            group1 = [current_user.id | current_user_linked_ids]
            group2 = [linked_user_id | linked_user_linked_ids]
            
            # 4. Create links between all accounts in both groups
            for id1 <- group1, id2 <- group2 do
              # Skip self-links
              if id1 != id2 do
                # Check if link already exists
                case Repo.get_by(LinkedAccount, primary_user_id: id1, linked_user_id: id2) do
                  nil ->
                    # Create new link
                    %LinkedAccount{}
                    |> LinkedAccount.changeset(%{
                      primary_user_id: id1,
                      linked_user_id: id2
                    })
                    |> Repo.insert()
                  _existing -> :ok
                end
                
                # Create reciprocal link if needed
                case Repo.get_by(LinkedAccount, primary_user_id: id2, linked_user_id: id1) do
                  nil ->
                    # Create new reciprocal link
                    %LinkedAccount{}
                    |> LinkedAccount.changeset(%{
                      primary_user_id: id2,
                      linked_user_id: id1
                    })
                    |> Repo.insert()
                  _existing -> :ok
                end
              end
            end
            
            # Generate a new session token for the linked user
            token = generate_user_session_token(linked_user)
            {:ok, token, linked_user}
        end
    end
  end
end
