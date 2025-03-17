defmodule Myapp.Accounts.SocialMediaToken do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Myapp.Accounts.User

  @encryption_key_salt "social_media_token_encryption"
  @token_max_age 86400 * 30 # 30 days in seconds

  schema "social_media_tokens" do
    field :access_token, :binary
    field :refresh_token, :binary
    field :expires_at, :utc_datetime
    field :platform, :string
    field :metadata, :map, default: %{}
    field :last_used_at, :utc_datetime

    # Virtual fields for changeset
    field :access_token_text, :string, virtual: true
    field :refresh_token_text, :string, virtual: true

    belongs_to :user, User

    timestamps()
  end

  @doc """
  Creates a changeset for the social media token.
  """
  def changeset(token, attrs) do
    token
    |> cast(attrs, [:access_token_text, :refresh_token_text, :expires_at, :platform, :metadata, :last_used_at, :user_id])
    |> validate_required([:access_token_text, :platform, :user_id])
    |> validate_inclusion(:platform, ["twitter", "instagram", "youtube", "tiktok"])
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:user_id, :platform], message: "Token for this platform already exists")
    |> encrypt_tokens()
  end

  @doc """
  Updates a changeset for an existing token.
  """
  def update_changeset(token, attrs) do
    token
    |> cast(attrs, [:access_token_text, :refresh_token_text, :expires_at, :metadata, :last_used_at])
    |> encrypt_tokens()
  end

  @doc """
  Gets token by user_id and platform.
  """
  def get_by_user_and_platform(user_id, platform) do
    from(t in __MODULE__,
      where: t.user_id == ^user_id and t.platform == ^platform
    )
  end

  @doc """
  Finds tokens that are about to expire.
  """
  def find_expiring_tokens(buffer_in_seconds \\ 3600) do
    buffer = DateTime.add(DateTime.utc_now(), buffer_in_seconds, :second)
    
    from(t in __MODULE__,
      where: not is_nil(t.expires_at) and t.expires_at <= ^buffer
    )
  end

  @doc """
  Encrypts access and refresh tokens.
  """
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

  @doc """
  Decrypts the access token from the database.
  """
  def decrypt_access_token(%__MODULE__{access_token: encrypted}) when not is_nil(encrypted) do
    decrypt_token(encrypted)
  end
  def decrypt_access_token(_), do: {:error, :no_token}

  @doc """
  Decrypts the refresh token from the database.
  """
  def decrypt_refresh_token(%__MODULE__{refresh_token: encrypted}) when not is_nil(encrypted) do
    decrypt_token(encrypted)
  end
  def decrypt_refresh_token(_), do: {:error, :no_token}

  # Private utility functions for token encryption/decryption
  defp encrypt_token(token) do
    Phoenix.Token.sign(Myapp.Endpoint, @encryption_key_salt, token)
    |> :erlang.term_to_binary()
  end

  defp decrypt_token(encrypted) do
    try do
      binary = :erlang.binary_to_term(encrypted)
      case Phoenix.Token.verify(Myapp.Endpoint, @encryption_key_salt, binary, max_age: @token_max_age) do
        {:ok, token} -> {:ok, token}
        {:error, reason} -> {:error, reason}
      end
    rescue
      _ -> {:error, :invalid_token}
    end
  end

  @doc """
  Validates if a token is still valid (not expired).
  """
  def valid?(%__MODULE__{expires_at: nil}), do: true
  def valid?(%__MODULE__{expires_at: expires_at}) do
    DateTime.compare(expires_at, DateTime.utc_now()) == :gt
  end

  @doc """
  Updates the last_used_at timestamp for tracking purposes.
  """
  def mark_as_used(token) do
    change(token, %{last_used_at: DateTime.utc_now()})
  end
end

