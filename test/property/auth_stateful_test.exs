defmodule AuthStatefulTest do
  @doc """
    This is a model of how a user system should work.
    I extracted this from an internal project,
      so much of this is half-done.

    Demo:
    ▶ auth master ✗ iex -S mix
    iex(1)> c "test/test_helper.exs"
    [AuthPropGenerators]
    iex(2)> c "test/property/auth_stateful_test.exs"
    [AuthTest]
    iex(3)> :proper_gen.sample(:proper_statem.commands(AuthStatefulTest))
    iex(3)> :proper_gen.sample(:proper_statem.commands(AuthStatefulTest))
    [{set,{var,1},
      {call,'Elixir.AuthClientShim',create_user_new,
            [<<50,98,115,112,52,51,57,97,240,159,146,181,240,159,141,170,240,
               159,148,165,240,159,143,128,33,111,115,55,121,122,240,159,144,
               132,101,109,64,112,113,48,118,102,116,53,46,110,101,116>>,
             <<"dustin">>,<<"3426d712-2a1e-4529-b55b-07de5b05d8ae">>]}},
  """
  use ExUnit.Case
  use PropCheck
  use PropCheck.StateM
  require Logger

  doctest Auth

  @tag timeout: 100000000
  @tag stateful: true
  property "auth service stateful non-parallel operations", [:verbose, numtests: 100] do
    forall cmds <- commands(__MODULE__) do
      IO.puts("****************************************")
      IO.inspect(cmds, label: "COMMANDS")

      prep()
      {history, state, result} = run_commands(__MODULE__, cmds)
      teardown()

      (result == :ok)
      |> aggregate(command_names(cmds))
      |> when_fail(
        IO.puts("""
        History: #{inspect(history)}
        *****************
        State: #{inspect(state)}
        *****************
        Result: #{inspect(result)}
        """)
      )
    end
  end

  @tag timeout: 100000000
  @tag stateful_parallel: true
  property "auth service stateful parallel operations", [:verbose, numtests: 100] do
    forall cmds <- parallel_commands(__MODULE__) do
      IO.puts("****************************************")
      IO.inspect(cmds, label: "COMMANDS")

      prep()
      {history, state, result} = run_parallel_commands(__MODULE__, cmds)
      teardown()

      (result == :ok)
      |> aggregate(command_names(cmds))
      |> when_fail(
        IO.puts("""
        History: #{inspect(history)}
        *****************
        State: #{inspect(state)}
        *****************
        Result: #{inspect(result)}
        """)
      )
    end
  end


  def prep() do
    Auth.Repo.delete_all(Auth.Accounts.User)
  end

  def teardown() do
    prep()
  end

  # initial model value at system start. Should be deterministic.
  def initial_state(), do: %{users: []}

  # All of the commented out commands were working against my test NodeJs API.
  # They implementing in the Phoenix app.
  def command(state) do
    always_possible = [
      # anything that is 'unknown', makes something new, or requires no state
      {:call, AuthClientShim, :create_user_new, [email_address(), "dustin", uuid()]},
      # {:call, AuthClientShim, :create_user_new_with_password, [email_address(), uuid(), password()]},
      # {:call, AuthClientShim, :login_fail, [email_address(), password()]},
      # {:call, AuthClientShim, :find_user_by_email_address_unknown, [email_address()]},
      # {:call, AuthClientShim, :find_user_by_uuid_unknown, [uuid()]},
      # {:call, AuthClientShim, :set_password_fail_unknown, [uuid(), password()]},
      # {:call, AuthClientShim, :change_password_fail_unknown, [uuid(), password(), password()]},
    ]

    relies_on_state =
      case Map.equal?(state, %{users: []}) do
        # no values yet
        true ->
          []

        # values from which to work
        false ->
          s = state

          [
            {:call, AuthClientShim, :create_user_existing, [user(s)]},
            {:call, AuthClientShim, :update_user_existing, [user_to_update(s)]},
            # {:call, AuthClientShim, :login_success, [user(s)]},
            # {:call, AuthClientShim, :users, []}, # should find all from s
            # {:call, AuthClientShim, :users_by_email_address, email_address(s)},
            # {:call, AuthClientShim, :find_user_by_email_address_known, [email_address(s)]},
            # {:call, AuthClientShim, :find_user_by_uuid_known, [uuid(s)]},
            # use a random password for the old password
            # {:call, AuthClientShim, :change_password_fail_known, [uuid(s), password(), password()]},
            # {:call, AuthClientShim, :change_password_success, [user(s), password()]},
            # {:call, AuthClientShim, :set_password_success, [uuid(s), password()]},

          ]
      end

    oneof(always_possible ++ relies_on_state)
  end

  ## Generators
  def password(), do: AuthPropGenerators.password_gen()

  def user(state) do
    Enum.random(state.users)
  end

  def user_to_update(state) do
    u = Enum.random(state.users)
    Map.put(u, :name, "dusty updated name")
  end

  def uuid(), do: AuthPropGenerators.uuid_gen()

  def uuid(state) do
    # These are used in combination with preconditions
    # This just return the user or nil
    # If there is nothing in state tho then the precondition needs to filter that out
    elements([Enum.map(state.users, fn u -> u.uuid end)
    |> hd])
  end

  # We need to do some lookups with bad emails too
  def email_address(), do: AuthPropGenerators.email_text()
  # def email_address(), do: AuthPropGenerators.utf8_email_text()

  def email_address(state) do
    elements([Enum.map(state.users, fn u -> u.email_address end)
    |> hd])
  end

  @doc """
    Notes on preconditions
    If you return false then the test runner will try a different step.
    If you step relies on state being setup correctly the check that thing in the function
      and return true/false based on the precondition.
    These need to be correct for proper shrinking.
    Never use live response information for setting up state.
    Everything must be a generator and setup by the model or shrinking and parallel won't work right.
  """
  def precondition(_s, {:call, _, :create_user_new, [_email_address, _name, _uuid]}) do
    true
  end

  def precondition(state, {:call, _, :create_user_new_with_password, [e, _u, _p]}) do
    case user_exists(state, e) do
      true -> false
      _ -> true
    end
  end

  def precondition(%{users: []}, {:call, _, :create_user_new_with_password, [_e, _u, _p]}) do
    true
  end

  def precondition(state, {:call, _, :create_user_existing, [%{email_address: email_address, name: _name, uuid: _uuid}]}) do
    user_exists(state, email_address)
  end

  def precondition(state, {:call, _, :update_user_existing, [%{email_address: email_address, name: _name, uuid: _uuid}]}) do
    user_exists(state, email_address)
  end

  def precondition(_state, {:call, _, :find_user_by_email_address_unknown, [_e]}) do
    true
  end

  def precondition(_state, {:call, _, :find_user_by_uuid_unknown, [_u]}) do
    true
  end

  def precondition(_state, {:call, _, :set_password_fail_unknown, [_u, _p]}) do
    true
  end

  def precondition(_state, {:call, _, :change_password_fail_unknown, [_u, _p1, _p]}) do
    true
  end

  def precondition(%{users: []}, {:call, _, :change_password_success, _}) do
    false
  end

  def precondition(state, {:call, _, :change_password_success,
      [%{password: old_password, uuid: u} = _us, _password]}) do


    Enum.any?(state.users, fn(state_user) ->
      case state_user.uuid == u do
        true ->
          has_p = Map.has_key?(state_user, :password)
          p_matches = has_p && (state_user.password == old_password)
          p_matches
        _ ->
          false
      end
    end)
  end

  def precondition(
        _state,
        {:call, _, :change_password_success, _}
      ) do
    false
  end

  def precondition(state, {:call, _, :set_password_success, [u, _password]}) do
    user_exists_by_uuid(state, u)
  end

  def precondition(
        _state,
        {:call, _, :set_password_success, _}
      ) do
    false
  end

  # def precondition(
  #       _state,
  #       {:call, _, :login_success, [%{password: _p, email_address: _email_address, uuid: _uuid}]}
  #     ) do
  #   true
  # end

  def precondition(_state, {:call, _, :login_fail, [_e, _p]}) do
    true
  end

  def precondition(
        %{users: []},
        {:call, _, :login_success, [%{password: _p, email_address: _email_address}]}
      ) do
    false
  end

  def precondition(
        state,
        {:call, _, :login_success, [%{password: p, email_address: email_address, uuid: _uuid}]}
      ) do

    Enum.any?(state.users, fn(state_user) ->
      case state_user.email_address == email_address do
        true ->
          has_p = Map.has_key?(state_user, :password)
          p_matches = has_p && (state_user.password == p)
          p_matches
        _ ->
          false
      end
    end)
  end

  def precondition(_state, {_, _, :login_success, _}) do
    false
  end

  def precondition(_state, {:call, _, :users_by_email_address, [_e]}) do
    true
  end

  def precondition(%{users: []}, {:call, _, :find_user_by_email_address_known, [_e]}) do
    false
  end

  def precondition(state, {:call, _, :find_user_by_email_address_known, [e]}) do
    user_exists(state, e)
  end

  def precondition(state, {:call, _, :find_user_by_uuid_known, [u]}) do
    user_exists_by_uuid(state, u)
  end

  def precondition(%{users: []}, {:call, _, :find_user_by_uuid_known, [_u]}) do
    false
  end

  # def precondition(_state, {:call, _, :find_user_by_uuid_known, [_u]}) do
  #   true
  # end

  def precondition(state, {:call, _, :change_password_fail_known, [u, _p, _p2]}) do
    user_exists_by_uuid(state, u)
  end

  def precondition(%{users: []}, {:call, _, :change_password_fail_known, [_u, _p, _p2]}) do
    false
  end

  # Catch all in case we miss something
  def precondition(s, call) do
    IO.inspect(call, label: "PRECONDITION FELL THROUGH")
    IO.inspect(s, label: "PRECONDITION FALL THROUGH STATE")
    false
  end

  def user_exists(state, email_address) do
    case Enum.find(state.users, fn user ->
           user.email_address == email_address
         end) do
      nil ->
        false

      _ ->
        true
    end
  end

  def user_exists_by_uuid(state, find_uuid) do
    case Enum.find(state.users, fn(state_user) ->
           state_user.uuid == find_uuid
         end) do
      nil ->
        false

      _ ->
        true
    end
  end

  @doc """
    Runs BEFORE and AFTER a command.
    You have to build up state from commands not from responses
    This is because the calls and call order are built before running anything.
    You may be able to do some symbolic call wizardry but seems to not be good practice (or work at all i couldnt find examples)
  """
  def next_state(state, _res, {:call, _, :create_user_new, [e, n, u]}) do
    # IO.inspect(state, label: "OG STATE")
    new_state = Map.put(state, :users, [%{email_address: simulate_user_auth_cleanse(e), name: n, uuid: u} | state.users])
    # IO.inspect(new_state, label: "NEW STATE")
    new_state
  end

  # find the user and update the password
  # in case the login runs after this make sure we store the new password
  def next_state(state, _res, {:call, _, :change_password_success, [u, p]}) do
    users = Enum.map(state.users, fn(user) ->
      case user.uuid == u.uuid do
        true ->

          Map.put(user, :password, p)
        _ -> user
      end
    end)

    Map.put(state, :users, users)
  end

  def next_state(state, _res, {:call, _, :update_user_existing, [u]}) do
    users = Enum.map(state.users, fn(user) ->
      case user.uuid == u.uuid do
        true ->

          u # just return the new one which should replace it
        _ -> user
      end
    end)

    Map.put(state, :users, users)
  end

  def next_state(state, _res, {:call, _, :set_password_success, [u, p]}) do
    users = Enum.map(state.users, fn(user) ->
      case user.uuid == u do
        true ->

          Map.put(user, :password, p)
        _ -> user
      end
    end)

    Map.put(state, :users, users)
  end

  # def next_state(state, %Tesla.Env{status: 500}, {:call, _, :set_password_success, [u, p]}) do
  #   IO.puts("We probably hit a race condition, so dont update state")

  #   state
  # end


  def next_state(state, _res, {:call, _, :create_user_new_with_password, [e, u, p]}) do
    Map.put(state, :users, [%{email_address: simulate_user_auth_cleanse(e), uuid: u, password: p} | state.users])
  end

  def next_state(state, _res, {_doing, _mod, _fun, _args}) do
    state
  end

  def simulate_user_auth_cleanse(email_address) do
    String.downcase(email_address)
  end

  @doc """
    POSTCONDITIONS:

    Make one for all expected statuses.
    Sometimes youll find a bug and have to make a condition for that until its fixed.
    Keep a fallthrough condition for inspecting them.
  """
  def postcondition(_, {_, _, :create_user_new, _}, {:ok, %Tesla.Env{status: 500}}) do
    # If 500 then its a bug
    false
  end

  def postcondition(_, {_, _, :create_user_new, _}, {:ok, %Tesla.Env{status: 201}}) do
    true
  end

  def postcondition(_, {_, _, :create_user_new_with_password, _}, {:ok, %Tesla.Env{status: 201}}) do
    true
  end

  def postcondition(
        _,
        {_, _, :find_user_by_email_address_unknown, _},
        {:ok, %Tesla.Env{status: 404}}
      ) do
    true
  end

  def postcondition(
        _,
        {_, _, :find_user_by_email_address_unknown, _},
        {:ok, %Tesla.Env{status: 405}}
      ) do
    true
  end

  def postcondition(_, {_, _, :find_user_by_uuid_unknown, _}, {:ok, %Tesla.Env{status: 404}}) do
    true
  end

  def postcondition(_, {_, _, :change_password_fail_known, _}, {:ok, %Tesla.Env{status: 404}}) do
    true
  end

  def postcondition(_, {_, _, :change_password_fail_known, _}, {:ok, %Tesla.Env{status: 400}}) do
    true
  end

  def postcondition(_, {_, _, :change_password_fail_unknown, _}, {:ok, %Tesla.Env{status: 404}}) do
    true
  end

  def postcondition(_, {_, _, :change_password_success, _}, {:ok, %Tesla.Env{status: 200}}) do
    true
  end

  def postcondition(_, {_, _, :change_password_success, _}, {:ok, %Tesla.Env{status: 201}}) do
    true
  end

  def postcondition(_, {_, _, :set_password_success, _}, {:ok, %Tesla.Env{status: 201}}) do
    true
  end

  def postcondition(_, {_, _, :set_password_fail_unknown, _}, {:ok, %Tesla.Env{status: 404}}) do
    true
  end

  def postcondition(_, {_, _, :create_user_existing, _}, {:ok, %Tesla.Env{status: 422}}) do
    true
  end

  def postcondition(_, {_, _, :update_user_existing, _}, {:ok, %Tesla.Env{status: 200}}) do
    true
  end

  def postcondition(
        _,
        {_, _, :find_user_by_email_address_known, _},
        {:ok, %Tesla.Env{status: 200}}
      ) do
    true
  end

  def postcondition(_, {_, _, :find_user_by_uuid_known, _}, {:ok, %Tesla.Env{status: 200}}) do
    true
  end

  def postcondition(_, {_, _, :login_fail, _}, {:ok, %Tesla.Env{status: 401}}) do
    true
  end

  def postcondition(
        _state,
        {_one, _two, :login_success, _four},
        {:ok, %Tesla.Env{body: _body, status: 201}}
      ) do

    # TODO: Validate the JWT?
    true
  end

  def postcondition(one, two, three) do
    IO.inspect(one, label: "NOT CAUGHT POST CONDITION 1")
    IO.inspect(two, label: "NOT CAUGHT POST CONDITION 2")
    IO.inspect(three, label: "NOT CAUGHT POST CONDITION 3")

    false
  end
end
