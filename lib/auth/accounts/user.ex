defmodule Auth.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :email_address, :string
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    # allow to send in id
    |> cast(attrs, [:name, :email_address, :id])
    |> validate_required([:name, :email_address])
    |> unique_constraint(:email_address)
    |> unique_constraint(:id, name: :users_pkey)
  end
end
