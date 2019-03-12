defmodule AuthClientShim do
  # find user unknown
  def find_user_by_email_address_unknown(email_address),
    do: AuthClient.users_by_email(email_address)

  def find_user_by_uuid_unknown(uuid), do: AuthClient.users(uuid)
  # find user known
  def find_user_by_email_address_known(email_address),
    do: AuthClient.users_by_email(email_address)

  def find_user_by_uuid_known(uuid), do: AuthClient.users(uuid)
  # make user
  def create_user_new(email_address, name, uuid),
    do: AuthClient.create_user(email_address, name, uuid)

  def create_user_existing(%{email_address: email_address, name: name, uuid: uuid}),
    do: AuthClient.create_user(email_address, name, uuid)

  def update_user_existing(%{email_address: email_address, name: name, uuid: uuid}),
    do: AuthClient.update_user(email_address, name, uuid)

  def create_user_new_with_password(email_address, uuid, password),
    do: AuthClient.create_user(email_address, uuid, password)

  def set_password_success(uuid, password), do: AuthClient.set_password(uuid, password)
  def set_password_fail_known(uuid, password), do: AuthClient.set_password(uuid, password)
  def set_password_fail_unknown(uuid, password), do: AuthClient.set_password(uuid, password)

  def change_password_success(%{uuid: uuid, password: old_password}, password) do
    AuthClient.change_password(uuid, old_password, password)
  end

  def change_password_fail_unknown(uuid, old_password, password),
    do: AuthClient.change_password(uuid, old_password, password)

  def change_password_fail_known(uuid, old_password, password),
    do: AuthClient.change_password(uuid, old_password, password)

  def login_success(%{email_address: email_address, password: password}),
    do: AuthClient.login(email_address, password)

  def login_fail(email_address, password), do: AuthClient.login(email_address, password)
end
