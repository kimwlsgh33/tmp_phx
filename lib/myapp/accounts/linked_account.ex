defmodule Myapp.Accounts.LinkedAccount do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "linked_accounts" do
    belongs_to :primary_user, Myapp.Accounts.User
    belongs_to :linked_user, Myapp.Accounts.User
    field :name, :string

    timestamps(type: :utc_datetime)
  end

  @doc """
  A linked account changeset for creation and update.

  ## Examples

      iex> change_linked_account(linked_account, attrs)
      %Ecto.Changeset{data: %LinkedAccount{}}

  """
  def changeset(linked_account, attrs) do
    linked_account
    |> cast(attrs, [:primary_user_id, :linked_user_id, :name])
    |> validate_required([:primary_user_id, :linked_user_id])
    |> foreign_key_constraint(:primary_user_id)
    |> foreign_key_constraint(:linked_user_id)
    |> unique_constraint([:primary_user_id, :linked_user_id], name: :primary_linked_user_index)
    |> check_constraint(:primary_user_id, name: :prevent_self_linking, message: "cannot link an account to itself")
  end

  @doc """
  Returns a list of linked accounts for a user.
  
  ## Examples

      iex> list_linked_accounts(user)
      [%LinkedAccount{}, ...]

  """
  def list_linked_accounts(user) do
    query = from l in __MODULE__,
            where: l.primary_user_id == ^user.id,
            preload: [:linked_user]
            
    Myapp.Repo.all(query)
  end
end

