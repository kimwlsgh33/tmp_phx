defmodule Myapp.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :current_password, :string, virtual: true, redact: true
    field :confirmed_at, :utc_datetime
    field :provider, :string
    field :provider_id, :string
    field :avatar_url, :string
    field :confirmation_code, :string

    timestamps(type: :utc_datetime)
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.

    * `:validate_email` - Validates the uniqueness of the email, in case
      you don't want to validate the uniqueness of the email (like when
      using this changeset for validations on a LiveView form before
      submitting the form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password, :provider, :provider_id, :avatar_url, :confirmation_code])
    |> validate_email(opts)
    |> validate_password(opts)
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    |> validate_format(:password, ~r/[0-9]/, message: "at least one number")
    |> validate_format(:password, ~r/[!@#$%^&*_]/, message: "at least one special character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Argon2.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, Myapp.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user, attrs \\ %{}) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    user
    |> cast(attrs, [:confirmation_code])
    |> change(confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Argon2.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%Myapp.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Argon2.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Argon2.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    changeset = cast(changeset, %{current_password: password}, [:current_password])

    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  @doc """
  A user changeset for registration via OAuth providers.

  This changeset handles registration with OAuth providers like Google,
  where the provider handles authentication and we just need to store 
  provider-specific information.
  """
  def oauth_registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :provider, :provider_id, :avatar_url, :password])
    |> validate_required([:email, :provider, :provider_id])
    |> validate_email([])
    |> validate_password([])
    |> unique_constraint(:provider_id, name: "users_provider_provider_id_index")
  end

  @doc """
  A user changeset for updating OAuth information.

  This changeset is used when a user logs in via an OAuth provider and
  we need to update their provider information (like a new avatar URL
  or a token refresh).
  """
  def oauth_changeset(user, attrs) do
    user
    |> cast(attrs, [:provider, :provider_id, :avatar_url])
    |> validate_required([:provider, :provider_id])
    |> unique_constraint(:provider_id, name: "users_provider_provider_id_index")
  end

  @doc """
  A changeset for generating a confirmation code for a user.

  This generates a random 6-letter uppercase confirmation code that will be sent 
  to the user's email address for verification.

  ## Options

    * `:generate_code` - When true, generates a new random 6-letter code.
      Defaults to `true`.
  """
  def confirmation_code_changeset(user, attrs \\ %{}, opts \\ []) do
    generate_code = Keyword.get(opts, :generate_code, true)

    changeset = cast(user, attrs, [:confirmation_code])

    if generate_code do
      # Generate a random 6-letter uppercase confirmation code
      code =
        :crypto.strong_rand_bytes(6)
        |> Base.encode32(padding: false)
        |> binary_part(0, 6)
        |> String.upcase()

      put_change(changeset, :confirmation_code, code)
    else
      changeset
      |> validate_required([:confirmation_code])
      |> validate_length(:confirmation_code, is: 6)
      |> validate_format(:confirmation_code, ~r/^[A-Z0-9]{6}$/,
        message: "must be 6 uppercase letters or numbers"
      )
    end
  end

  @doc """
  Validates if the provided confirmation code matches the stored one.

  Returns `{:ok, changeset}` if the code matches, or `{:error, changeset}` otherwise.
  """
  def validate_confirmation_code(user, code) do
    if user.confirmation_code == String.upcase(code) do
      {:ok, confirm_changeset(user)}
    else
      {:error, add_error(change(user), :confirmation_code, "is invalid")}
    end
  end
end
