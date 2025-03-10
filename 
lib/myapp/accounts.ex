379|  end

  ## OAuth Authentication

  @doc """
  Gets a user by provider and provider ID.

  ## Examples

      iex> get_user_by_oauth("google", "123456789")
      %User{}

      iex> get_user_by_oauth("google", "invalid")
      nil

  """
  def get_user_by_oauth(provider, provider_id) when is_binary(provider) and is_binary(provider_id) do
    Repo.get_by(User, provider: provider, provider_id: provider_id)
  end

  @doc """
  Registers a user using OAuth provider data.

  ## Examples

      iex> register_oauth_user(%{field: value})
      {:ok, %User{}}

      iex> register_oauth_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_oauth_user(attrs) do
    %User{}
    |> User.oauth_registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Finds or creates a user based on OAuth profile information.
  If the user exists, it returns the existing user.
  If the user doesn't exist, it creates a new one.

  ## Examples

      iex> find_or_create_oauth_user(%{provider: "google", provider_id: "123", email: "user@example.com"})
      {:ok, %User{}}

  """
  def find_or_create_oauth_user(attrs) do
    provider = attrs.provider
    provider_id = attrs.provider_id

    case get_user_by_oauth(provider, provider_id) do
      nil ->
        # Check if user exists with this email but without OAuth info
        case get_user_by_email(attrs.email) do
          nil -> 
            # User doesn't exist, create a new one
            register_oauth_user(attrs)
          existing_user -> 
            # User exists with this email but doesn't have OAuth info
            # Update the user with OAuth provider information
            existing_user
            |> User.oauth_registration_changeset(attrs)
            |> Repo.update()
        end
      user -> 
        # User already exists with this provider_id
        {:ok, user}
    end
  end

  @doc """
  Authenticates a user using OAuth provider information.
  If authentication is successful, it returns the user.

  ## Examples

      iex> authenticate_oauth_user(%{provider: "google", provider_id: "123", email: "user@example.com"})
      {:ok, %User{}}

  """
  def authenticate_oauth_user(oauth_info) do
    attrs = %{
      email: oauth_info.email,
      provider: oauth_info.provider,
      provider_id: oauth_info.provider_id,
      avatar_url: Map.get(oauth_info, :avatar_url)
    }
    
    case find_or_create_oauth_user(attrs) do
      {:ok, user} ->
        if user.confirmed_at do
          # User is already confirmed
          {:ok, user}
        else
          # Auto-confirm users authenticated via OAuth
          user
          |> User.confirm_changeset()
          |> Repo.update()
        end
      error -> error
    end
  end
end
