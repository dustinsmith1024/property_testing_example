defmodule Auth.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :email_address, :string

      timestamps()
    end

    create index(:users, [:email_address], unique: true)
  end
end
