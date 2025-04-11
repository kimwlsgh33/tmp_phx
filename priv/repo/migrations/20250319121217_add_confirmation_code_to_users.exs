defmodule Myapp.Repo.Migrations.AddConfirmationCodeToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :confirmation_code, :string, size: 6
    end
  end
end
