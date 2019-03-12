defmodule AuthClient do
  @moduledoc """
    Auth client setup to hit this Phoenix API

    Reminder run the server before testing:
    mix phx.server
  """

  use Tesla

  plug(Tesla.Middleware.BaseUrl, "http://localhost:4000")
  plug(Tesla.Middleware.JSON)

  @doc """
    returns a list of users, data: [] wrapper
  """
  def users() do
    get("/api/users")
  end

  @doc """
    Auth.users("0e1ed109-44d7-49d7-89da-03c15c0cef39")
  """
  def users(id) do
    get("/api/users/#{id}")
  end

  @doc """
    Auth.users_by_email("dustin@test.com")
    {:ok, %Tesla.Env{body: %Map, status: 200}
    Done exist?
    {:ok, %Tesla.Env{body: %Map, status: 404}
  """
  def users_by_email(email_address) do
    e = URI.encode_www_form(email_address)
    get("/api/users-by-email/#{e}")
  end

  @doc """
    iex(1)> AuthClient.create_user("dustin@gmail.com", "Dustin")
    {:ok,
    %Tesla.Env{
      __client__: %Tesla.Client{adapter: nil, fun: nil, post: [], pre: []},
      __module__: AuthClient,
      body: %{
        "data" => %{
          "email_address" => "dustin@gmail.com",
          "id" => "14214408-4a57-42c2-b2f5-4f2cc98f77d1",
          "name" => "Dustin"
        }
      },
    status: 201,
  """
  def create_user(email_address, name, id) do
    post("/api/users", %{user: %{email_address: email_address, name: name, id: id}})
  end

  def update_user(email_address, name, id) do
    patch("/api/users/#{id}", %{user: %{email_address: email_address, name: name}})
  end

  def change_password(id, old_password, new_password) do
    post("/api/users/#{id}/password", %{
      old_password: old_password,
      password: new_password
    })
  end

  def set_password(id, password) do
    patch("/api/users/#{id}/password", %{password: password})
  end

  def create_user(email_address) do
    post("/api/users", %{email_address: email_address})
  end

  def login(email_address, password) do
    post("/api/users", %{email_address: email_address, password: password})
  end

  def user(id), do: users(id)
end
