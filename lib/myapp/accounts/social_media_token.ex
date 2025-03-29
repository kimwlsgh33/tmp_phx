defmodule Myapp.Accounts.SocialMediaToken do
  @moduledoc """
  Manages encrypted social media access tokens for user authentication with third-party platforms.
  
  ## Purpose and Overview
  
  This module provides secure storage and management of OAuth tokens for various social media
  platforms. Unlike the `PlatformToken` module, `SocialMediaToken` implements encryption for
  all stored tokens, making it more suitable for production environments where security is
  a critical concern.
  
  ## Token Structure
  
  Social media tokens are stored with the following key fields:
  
  * `user_id` - The ID of the user who owns the token
  * `provider` - The social media platform (e.g., :twitter, :instagram)
  * `access_token` - The encrypted OAuth access token used for API calls
  * `refresh_token` - The encrypted OAuth refresh token (when available)
  * `expires_at` - When the access token expires
  * `refresh_token_expires_at` - When the refresh token expires
  * `provider_user_id` - The user's ID on the social platform
  * `revoked_at` - Timestamp when the token was invalidated (if applicable)
  * `metadata` - Additional platform-specific data
  
  ## Encryption Approach
  
  Tokens are encrypted using Phoenix.Token with a salt-based approach:
  
  1. When tokens are stored, the plaintext values are passed via virtual fields
     (`access_token_text` and `refresh_token_text`)
  2. The encryption process uses Phoenix.Token to sign the data with a salt
  3. Encrypted tokens are stored as binary data in the database
  4. When retrieving tokens, they are automatically decrypted back to plaintext
  
  This approach prevents plaintext tokens from ever being stored in the database,
  providing protection against database breaches or unauthorized access.
  
  ## Token Lifecycle
  
  Social media tokens follow this lifecycle:
  
  1. **Creation** - Tokens are stored via `store_tokens/4` after OAuth authentication
  2. **Retrieval** - Active tokens are fetched via `get_active_tokens/2` with automatic decryption
  3. **Refresh** - When tokens expire, they can be refreshed using `update_token/3`
  4. **Expiration** - Tokens automatically expire based on provider-specified or default timeframes
  5. **Revocation** - Tokens can be explicitly revoked via `revoke_active_tokens/2`
  
  The module provides helper functions like `needs_refresh?/1` and `refresh_token_valid?/1`
  to manage this lifecycle.
  
  ## Comparison with PlatformToken
  
  While PlatformToken also manages social platform tokens, SocialMediaToken differs in key ways:
  
  * **Security** - SocialMediaToken encrypts tokens, PlatformToken stores them as plaintext
  * **Structure** - SocialMediaToken has more fields for better token lifecycle tracking
  * **Functionality** - SocialMediaToken includes built-in refresh and expiration handling
  * **Implementation** - SocialMediaToken uses a more robust, database-only approach
  
  Both modules may exist during a transition period, with SocialMediaToken intended as
  a more secure replacement for PlatformToken in production environments.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Myapp.Repo
  alias Myapp.Accounts.{User, SocialMediaToken}

  @providers [:twitter, :tiktok, :instagram, :youtube, :thread]
  @token_lifetime 24 * 60 * 60 # 24 hours in seconds
  @refresh_token_lifetime 30 * 24 * 60 * 60 # 30 days in seconds
  @encryption_key_salt "social_media_token_encryption"

  schema "social_media_tokens" do
    belongs_to :user, User
    field :provider, Ecto.Enum, values: @providers
    field :access_token, :binary
    field :refresh_token, :binary
    field :token_type, :string
    field :scope, :string
    field :expires_at, :utc_datetime
    field :refresh_token_expires_at, :utc_datetime
    field :provider_user_id, :string
    field :metadata, :map, default: %{}
    field :revoked_at, :utc_datetime
    field :last_used_at, :utc_datetime

    # Virtual fields for token encryption
    field :access_token_text, :string, virtual: true
    field :refresh_token_text, :string, virtual: true

    timestamps()
  end

  @required_fields [:user_id, :provider]
  @optional_fields [
    :token_type, :scope, :expires_at, :refresh_token_expires_at,
    :provider_user_id, :metadata, :revoked_at, :last_used_at
  ]
  @virtual_fields [:access_token_text, :refresh_token_text]

  def changeset(token, attrs) do
    token
    |> cast(attrs, @required_fields ++ @optional_fields ++ @virtual_fields)
    |> validate_required(@required_fields ++ [:access_token_text])
    |> validate_inclusion(:provider, @providers)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:user_id, :provider, :provider_user_id],
      name: :active_social_tokens_index,
      message: "active token already exists for this provider"
    )
    |> encrypt_tokens()
  end

  def update_changeset(token, attrs) do
    token
    |> cast(attrs, @optional_fields ++ @virtual_fields)
    |> encrypt_tokens()
  end

  @doc """
  Stores social media tokens for a user.
  Automatically calculates expiration times if not provided.
  """
  def store_tokens(user_id, provider, token_data, opts \\ []) do
    now = DateTime.utc_now()
    expires_in = token_data["expires_in"] || opts[:expires_in] || @token_lifetime
    refresh_expires_in = token_data["refresh_expires_in"] ||
      opts[:refresh_expires_in] || @refresh_token_lifetime

    attrs = %{
      user_id: user_id,
      provider: provider,
      access_token_text: token_data["access_token"],
      refresh_token_text: token_data["refresh_token"],
      token_type: token_data["token_type"] || "Bearer",
      scope: token_data["scope"],
      expires_at: DateTime.add(now, expires_in, :second),
      refresh_token_expires_at:
        if token_data["refresh_token"] do
          DateTime.add(now, refresh_expires_in, :second)
        else
          nil
        end,
      provider_user_id: token_data["open_id"] || token_data["provider_user_id"],
      metadata: Map.drop(token_data, [
        "access_token", "refresh_token", "token_type",
        "scope", "expires_in", "refresh_expires_in",
        "open_id", "provider_user_id"
      ]),
      last_used_at: now
    }

    # Revoke any existing active tokens for this user/provider combination
    revoke_active_tokens(user_id, provider)

    %SocialMediaToken{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Retrieves active tokens for a user and provider.
  Automatically decrypts tokens when found.
  """
  def get_active_tokens(user_id, provider) do
    now = DateTime.utc_now()

    query =
      from t in SocialMediaToken,
        where: t.user_id == ^user_id and
              t.provider == ^provider and
              is_nil(t.revoked_at) and
              (is_nil(t.expires_at) or t.expires_at > ^now),
        order_by: [desc: :inserted_at],
        limit: 1

    case Repo.one(query) do
      nil -> 
        {:error, {:not_found, "No active tokens found"}}
      token -> 
        with {:ok, access_token} <- decrypt_access_token(token),
             {:ok, refresh_token} <- decrypt_refresh_token(token) do
          {:ok, %{token |
            access_token_text: access_token,
            refresh_token_text: refresh_token
          }}
        else
          {:error, reason} -> {:error, {:decrypt, reason}}
        end
    end
  end

  @doc """
  Revokes all active tokens for a user and provider.
  """
  def revoke_active_tokens(user_id, provider) do
    now = DateTime.utc_now()

    query =
      from t in SocialMediaToken,
        where: t.user_id == ^user_id and
              t.provider == ^provider and
              is_nil(t.revoked_at)

    Repo.update_all(query,
      set: [revoked_at: now, updated_at: now]
    )

    :ok
  end

  @doc """
  Updates a token with new token data (e.g., after refresh).
  """
  def update_token(token, token_data, opts \\ []) do
    now = DateTime.utc_now()
    expires_in = token_data["expires_in"] || opts[:expires_in] || @token_lifetime

    attrs = %{
      access_token_text: token_data["access_token"],
      refresh_token_text: token_data["refresh_token"] || token.refresh_token_text,
      expires_at: DateTime.add(now, expires_in, :second),
      last_used_at: now,
      metadata: Map.merge(token.metadata || %{}, Map.drop(token_data, [
        "access_token", "refresh_token", "expires_in"
      ]))
    }

    token
    |> update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Checks if a token needs to be refreshed based on its expiration time.
  Returns true if the token will expire within the next hour.
  """
  def needs_refresh?(token) do
    now = DateTime.utc_now()
    refresh_threshold = DateTime.add(now, 3600, :second)

    not is_nil(token.expires_at) and
      DateTime.compare(token.expires_at, refresh_threshold) in [:lt, :eq]
  end

  @doc """
  Checks if a refresh token is still valid.
  """
  def refresh_token_valid?(token) do
    now = DateTime.utc_now()

    not is_nil(token.refresh_token) and
      (is_nil(token.refresh_token_expires_at) or
       DateTime.compare(token.refresh_token_expires_at, now) == :gt)
  end

  @doc """
  Finds tokens that are about to expire.
  """
  def find_expiring_tokens(buffer_in_seconds \\ 3600) do
    buffer = DateTime.add(DateTime.utc_now(), buffer_in_seconds, :second)
    
    from(t in SocialMediaToken,
      where: not is_nil(t.expires_at) and t.expires_at <= ^buffer and
            is_nil(t.revoked_at)
    )
  end

  # Token encryption/decryption functions
  defp encrypt_tokens(changeset) do
    if access_token = get_change(changeset, :access_token_text) do
      encrypted = encrypt_token(access_token)
      put_change(changeset, :access_token, encrypted)
    else
      changeset
    end
    |> maybe_encrypt_refresh_token()
  end

  defp maybe_encrypt_refresh_token(changeset) do
    if refresh_token = get_change(changeset, :refresh_token_text) do
      encrypted = encrypt_token(refresh_token)
      put_change(changeset, :refresh_token, encrypted)
    else
      changeset
    end
  end

  defp encrypt_token(token) do
    Phoenix.Token.sign(Myapp.Endpoint, @encryption_key_salt, token)
    |> :erlang.term_to_binary()
  end

  def decrypt_access_token(%__MODULE__{access_token: encrypted}) when not is_nil(encrypted) do
    decrypt_token(encrypted)
  end
  def decrypt_access_token(_), do: {:error, :no_token}

  def decrypt_refresh_token(%__MODULE__{refresh_token: encrypted}) when not is_nil(encrypted) do
    decrypt_token(encrypted)
  end
  def decrypt_refresh_token(_), do: {:error, :no_token}

  defp decrypt_token(encrypted) do
    try do
      binary = :erlang.binary_to_term(encrypted)
      Phoenix.Token.verify(Myapp.Endpoint, @encryption_key_salt, binary, max_age: @refresh_token_lifetime)
    rescue
      _ -> {:error, :invalid_token}
    end
  end
end

