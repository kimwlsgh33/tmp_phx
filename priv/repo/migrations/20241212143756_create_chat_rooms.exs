defmodule Myapp.Repo.Migrations.CreateChatRooms do
  use Ecto.Migration

  def change do
    create table(:rooms) do
      add :name, :string, null: false
      add :description, :text
      add :slug, :string

      timestamps()
    end

    create index(:rooms, [:slug])
  end
end
