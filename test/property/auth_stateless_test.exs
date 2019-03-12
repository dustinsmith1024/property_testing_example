defmodule AuthStateless do
  use ExUnit.Case
  use PropCheck

  # property "uuids", [:verbose] do
  #   prep()

  #   forall e <- non_empty(AuthPropGenerators.uuid_gen()) do
  #     validate_uuid(e)
  #   end
  # end

  @tag emails: true
  property "good normal emails with some emojis", [:verbose] do
    prep()

    forall e <- non_empty(AuthPropGenerators.email_text()) do
      validate(e, AuthClient.create_user(e, "dustin", UUID.uuid4()))
    end
  end

  @tag emails_no_bourbon: true
  property "good normal emails with no bourbon emojis!!", [:verbose] do
    prep()

    forall e <- non_empty(AuthPropGenerators.email_text()) do
      validate_demo_no_bourbon(e, AuthClient.create_user(e, "dustin", UUID.uuid4()))
    end
  end

  @tag emails_no_bourbon_or_pizza: true
  property "good normal emails with no bourbon or pizza emojis!!", [:verbose] do
    prep()

    forall e <- non_empty(AuthPropGenerators.email_text()) do
      validate_demo_no_bourbon_or_pizza(e, AuthClient.create_user(e, "dustin", UUID.uuid4()))
    end
  end

  # This is buggy and not perfect
  # property "utf8 emails" do
  #   prep()
  #   forall e <- non_empty(AuthPropGenerators.utf8_email_text()) do
  #     validate(e, AuthClient.create_user(e))
  #   end
  # end

  # property "emoji emails" do
  #   prep()
  #   forall e <- non_empty(AuthPropGenerators.emoji_email_text()) do
  #     validate(e, AuthClient.create_user(e))
  #   end
  # end

  def prep() do
    Auth.Repo.delete_all(Auth.Accounts.User)
  end

  def validate_uuid(u) do
    case UUID.info(u) do
      {:error, m} ->
        IO.puts(m)
        false

      _ ->
        true
    end
  end

  @doc """
    This is valid if the email address doesnt contain a bourbon emoji.
  """
  def validate_demo_no_bourbon(
        _e,
        {:ok, %Tesla.Env{status: 201, body: %{"data" => %{"email_address" => email_address}}}}
      ) do
    IO.inspect(email_address)
    not String.contains?(email_address, "🥃")
  end

  @doc """
    This is valid if the email address doesn't contain a pizza emoji.
  """
  def validate_demo_no_bourbon_or_pizza(
        _e,
        {:ok, %Tesla.Env{status: 201, body: %{"data" => %{"email_address" => email_address}}}}
      ) do
    IO.inspect(email_address)
    not String.contains?(email_address, "🥃") || not String.contains?(email_address, "🍕")
  end

  @doc """
    This is valid if the auth service returned correctly.
  """
  def validate(
        _e,
        {:ok, %Tesla.Env{status: 201, body: %{"data" => %{"email_address" => email_address}}}}
      ) do
    IO.inspect(email_address)
    true
  end

  def validate(_email, {:error, _wat}) do
    # IO.inspect(wat)
    false
  end

  def validate(_, {:ok, %Tesla.Env{status: _status} = res}) do
    IO.inspect(res, label: "Bad response?")
    false
  end
end
