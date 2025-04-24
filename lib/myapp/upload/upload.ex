defmodule Myapp.Upload.Upload do
  use Ecto.Schema
  import Ecto.Changeset

  schema "uploads" do
    field :file_name, :string
    field :file_id, :string
    field :url, :string
    field :status, :string, default: "in_progress"
    field :bytes_uploaded, :integer, default: 0
    belongs_to :user, Myapp.Accounts.User
    timestamps()
  end

  @doc false
  def changeset(upload, attrs) do
    upload
    |> cast(attrs, [:file_name, :file_id, :user_id, :url, :status, :bytes_uploaded])
    |> validate_required([:file_name, :file_id, :status])
    |> unique_constraint(:file_id)
  end
end
