ExUnit.start()
# Ecto.Adapters.SQL.Sandbox.mode(Auth.Repo, :manual)

defmodule AuthPropGenerators do
  use PropCheck

  @moduledoc """
    # To test these include the helpers:
    # iex(28)> c "test/test_helper.exs"

    # Garbage UTF-8
    # iex(88)> :proper_gen.pick(PropCheck.BasicTypes.utf8()) |> elem(1) |> IO.puts
    # Ƶ^Ȓꯈbx^Ką̀ﲩ𐀀ʦ𐀆𐀅!𐀅Б𐀄ﾨۉ厖

    # Random strings based on character I want
    # iex(6)> :proper_gen.sample(PropCheck.BasicTypes.vector(25, PropCheck.BasicTypes.elements('123456ABCDEFabcdefd8sf9vu98uf9vjsdf98jv9jdfv')))

    # "2f39F9cCfu9BjsFsfB9D8e899"

    # iex(23)> Enum.map(1..25, fn(_) -> :proper_gen.pick(AuthPropGenerators.email_text) |> elem(1) |> IO.puts end)

    # cj.?💥417💵g@v.io
    # m~1fu💥#@b.live
    # xn1q+💵wb🤷~i*ta@2d5aa2-org
    # mvbr8gry9🍕0u!‍3🐄@5w2oaly.com
    # zkf🔥u6|🙄p@5up.live
    # 2kqi🏻*💵rz^&@c.com
    # yg1mnshet+l@o-54vu5.com

    # # Make random UUID's
    # iex(27)> Enum.map(1..25, fn(_) -> :proper_gen.pick(AuthPropGenerators.uuid_gen) |> elem(1) |> IO.puts end)

    # 6c961a6b-9b0a-4713-a7ca-728fa7284571
    # 9824b918-247b-46a1-b306-a3111a1920e9
    # 947f5ad4-980b-4e4d-a8aa-8cf6d5febc89
    # 7a218096-0a8c-4806-972b-02bd03f08a12
    # d628b23f-cf0a-4e47-bd1a-909754324907
    # a2fc64d6-d487-421d-b452-d2672ad12c43

  """

  def password_gen() do
    let first_character <- vector(10, elements(first_letter())) do
      to_string(first_character)
    end
  end

  @doc """
    This is a solid implementation of normal non international emails
    https://www.mailboxvalidator.com/resources/articles/acceptable-email-address-syntax-rfc/
    TODO: How can we clean this code up?
  """
  def email_text() do
    let first_character <- non_empty(list(elements(first_letter()))) do
      local_string = to_string(first_character)

      let chars <- non_empty(list(elements(local_with_emoji()))) do
        local = to_string(chars) |> String.replace("..", ".")

        let emo <- list(emoji()) do
          local_emo = to_string(emo)

          # domains cannot be longer, how does this affect shrinking?
          let chars2 <- non_empty(list(elements(domain_base()))) do
            domain =
              to_string(chars2)
              |> String.slice(0, 63)

            let dot_chars <- dot_something() do
              dot = to_string(dot_chars)

              final =
                (local_string <> local_emo <> local <> "@" <> domain <> dot)
                |> String.replace(".@", "@")
                |> String.replace("@-", "@")
                |> String.replace("-.", "-")

              final
            end
          end
        end
      end
    end
  end

  @doc """
    Allows UTF8 characters into the email addresses.
    Not sure how perfect this is right now.
    We need to filter out `empty` types before this will work.
  """
  def utf8_email_text() do
    let first_character <- non_empty(list(elements(first_letter()))) do
      local_string = to_string(first_character)

      let chars <- non_empty(utf8()) do
        local =
          to_string(chars)
          # `..` not allowed by spec
          |> String.replace("..", ".")

        let chars2 <- non_empty(list(elements(domain_base()))) do
          domain =
            to_string(chars2)
            |> String.slice(0, 63)

          let dot_chars <- dot_something() do
            dot = to_string(dot_chars)

            final =
              (local_string <> local <> "@" <> domain <> dot)
              |> String.replace(".@", "@")
              |> String.replace("@-", "@")
              |> String.replace("-.", "-")

            # dots and dashes cannot be last in local or first in tld

            final
          end
        end
      end
    end
  end

  @doc """
    This is a quasi UTF8 test but specifically for emojis.
    https://tools.ietf.org/html/rfc6531
    Most email providers do not let you make an email with an emoji.
    It is how allowed and if you setup your own email server it will work.
  """
  def emoji_email_text() do
    let first_character <- non_empty(list(elements(first_letter()))) do
      local_string = to_string(first_character)

      let chars <- non_empty(emoji()) do
        local =
          to_string(chars)
          |> String.replace("..", ".")

        let chars2 <- non_empty(list(elements(domain_base()))) do
          domain =
            to_string(chars2)
            |> String.slice(0, 63)

          let dot_chars <- dot_something() do
            dot = to_string(dot_chars)

            final =
              (local_string <> local <> "@" <> domain <> dot)
              |> String.replace(".@", "@")
              |> String.replace("@-", "@")
              |> String.replace("-.", "-")

            final
          end
        end
      end
    end
  end

  def first_letter() do
    'abcdefghijklmnopqrstuvwxyz0123456789'
  end

  def local_with_emoji() do
    'abcdefghijklmnopqrstuvwxyz0123456789😸🤷🏻‍🙄🔥🥃🍪🐄💵💥🏀🍕🍟🎒🚙!#$%&‘*+–/=?^_`.{|}~'
  end

  def local_simple_emails() do
    'abcdefghijklmnopqrstuvwxyz0123456789' ++ '!#$%&‘*+–/=?^_`.{|}~'
  end

  def emoji() do
    oneof(["😸", "🤷🏻‍", "🙄", "🔥", "👍", "😍", "🤜🏼", "🥃", "🍪", "🐄", "💵", "💥", "🤞", "🍕", "🏀"])
  end

  @doc """
    Valid UUID4's have a 4 in the 3rd section
    They only container Hexidecimal characters
    The 4th section starts with 8,9,a, or b.
    "bb87f96a-f51f-4a8d-a8d1-a688e083aade"
  """
  def uuid_gen() do
    let chars <-
          vector(1, [
            uuid_chars(8),
            "-",
            uuid_chars(4),
            "-",
            "4",
            uuid_chars(3),
            "-",
            oneof(["8", "9", "a", "b"]),
            uuid_chars(3),
            "-",
            uuid_chars(12)
          ]) do
      to_string(chars)
    end
  end

  @doc """
    Returns `num` amounts of valid UUID characters.
  """
  def uuid_chars(num) do
    let chars <- vector(12, elements(uuid_hex_values())) do
      to_string(chars)
      # num-1 so we can pass in the total
      |> String.slice(0..(num - 1))
    end
  end

  def uuid_hex_values() do
    'abcdef0123456789'
  end

  # This should be limited to 64 characters
  # It could have subdomains too
  #  https://www.hscripts.com/tutorials/web/domain-characters.php
  def domain_base() do
    'abcdefghijklmnopqrstuvwxyz0123456789' ++ '-'
  end

  def dot_something() do
    oneof([".com", ".net", ".live", ".org", ".biz", ".io"])
  end
end
