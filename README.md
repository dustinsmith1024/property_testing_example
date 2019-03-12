# User service property testing example

Sample property testing for an HTTP API.

Worked my way through the Property Testing with PropEr, Erlang, and Elixir.

This was abstracted and simplified from testing a real API. I did not replicate the API so this is just for reference and the basics.

## Setup

```sh
▶ mix deps.get
```

Remember to update your repository by running migrations. Double check dev and test DB configs because mine are probably different.

```sh
▶ mix ecto.migrate
[info] == Running 20190309190403 Auth.Repo.Migrations.CreateUsers.change/0 forward
[info] create table users
[info] == Migrated 20190309190403 in 0.0s
```

Start the API and test it a bit.

```sh
▶ mix phx.server
[info] Running AuthWeb.Endpoint with cowboy 2.6.1 at http://localhost:4000

▶ curl http://localhost:4000/api/users
{"data":[]}%

▶ curl --request POST \
  --url http://localhost:4000/api/users \
  --header 'Content-Type: application/json' \
  --header 'Postman-Token: 7f23bc67-da44-4d93-af10-eeeb6d05f518' \
  --header 'cache-control: no-cache' \
  --data '{\n	"user": {\n		"email_address": "dustin@smith.com",\n		"name": "Dustin"\n	}\n}'

{
    "data": {
        "email_address": "dustin@smith.com",
        "id": "d6a6f371-88b0-4d9f-ab57-1992d59dfa50",
        "name": "Dustin"
    }
}
```

## Running stateless tests

Make sure the server is running. Dev mode should be fine.

Basic email testing. Notice how the tests grow in complexity but all pass.

```sh
▶ auth mix test --only emails
Including tags: [:emails]
Excluding tags: [:test]

"1🙄‘@m.com"
."k🔥p@4.biz"
."o–@9.net"
."80🤷🐄@9.biz"
."y🐄🔥|@u4.biz"
."a🏀k!@q9.io"
```

No bourbon allowed. It fails and then shrinks down to a basic email with bourbon in it. There is extra characters because the generators are forcing it.

```sh
▶ auth mix test --only emails_no_bourbon
Including tags: [:emails_no_bourbon]
Excluding tags: [:test]

"t🔥s@3.net"
."d🤷🏻‍🔥@g.live"
."c!@y.live"
."wy💵1💵@8x.com"
."ty1@.biz"
."cc@q4.com"
."41🔥y@j2c.biz"
."96o🤞y8@d.org"
."o0🤜🏼🤷🏻‍?|@r4z.net"
."kr🥃🤷🏻‍😸🏀@86-net"
!
Failed: After 10 test(s).
<<107,114,240,159,165,131,240,159,164,183,240,159,143,187,226,128,141,240,159,152,184,240,159,143,128,64,56,54,45,110,101,116>>

Shrinking "r😍🍕nq*@ls1.org"
"k`@gh.live"
"ar🏀🤜🏼🤷pk@gs2w.com"
"brjf#@0ymi.biz"
"cry–@iu.live"
"dr🍕j@7857.org"

...

(39 time(s))
<<97,240,159,165,131,101,97,64,97,46,99,111,109>>


  1) property good normal emails with no bourbon emojis!! (AuthStateless)
     test/property/auth_stateless_test.exs:23
     Property Elixir.AuthStateless.property good normal emails with no bourbon emojis!!() failed. Counter-Example is:
     ["a🥃ea@a.com"]

     code: nil
     stacktrace:
       (propcheck) lib/properties.ex:126: PropCheck.Properties.handle_check_results/3
       test/property/auth_stateless_test.exs:23: (test)



Finished in 2.1 seconds
4 properties, 16 tests, 1 failure, 19 excluded
```

No make it a bit more complex. This will be random best on the test run. So it might not fail the same for you.

```sh
▶ auth mix test --only emails_no_bourbon_or_pizza
Including tags: [:emails_no_bourbon_or_pizza]
Excluding tags: [:test]

"c💥🚙@1.org"
."s🍪@e.com"
."j2@b.com"
."a🍪w@mz.org"
."k😍u@p.live"
."4🔥||@8d.biz"
."v💥lo@xy.net"
."d9🐄🔥j+@gr.org"
."9🔥😸0@5yt.org"
."tti5😸🤞🤷🏻‍👍29na@wgk.biz"
."gv🤞🥃🥃🐄o🤷~9@5.biz"
."np🥃🔥vz@os.net"
."r*69v!@wj3.io"
."4v🍕🤞1c😸0@j-8d.com"
."ih🤷🏻‍🍪🙄🤜🏼i*ej@5g8o.com"
."fb😍😸e7k@hnc5pz.net"
."x9j🍟8@fa3.io"
."f8x🤜🏼🍕😍😍💥i@6n4.net"
."w1vw💵💥🏀🤞6^@bagm.com"
."4u🐄🍪🍪💵😸💵🍪#2@wse.io"
."d54k🥃😸🍪💵💵mkq`7@shyzwrc.io"
."4sgffi9🔥🏀😍🏀😸🍪💥.d🎒@8.biz"
."ck🤜🏼😸😸😸💥🤞🍕🤜🏼v0@dr-m4lu.io"
."mc4j2x💵🥃🐄🤜🏼🥃h@ls9o4y42.biz"
."vbf💥💥ec@h9eiy.live"
."g4148cakg🙄9n}4b@aqr9uc05.com"
."7z1ihe9🤜🏼🤞_^😸y@ejwsb3.org"
."ky76🥃💥🔥🍪🍪😸🤷🏻‍.{l@qnwy4qf.org"
."4oc79🔥👍🏀🍕😸🔥🤜🏼🔥🥃🍕🔥🙄🐄@k1.biz"
!
Failed: After 29 test(s).
<<52,111,99,55,57,240,159,148,165,240,159,145,141,240,159,143,128,240,159,141,149,240,159,152,184,240,159,148,165,240,159,164,156,240,159,143,188,240,159,148,165,240,159,165,131,240,159,141,149,240,159,148,165,240,159,153,132,240,159,144,132,64,107,49,46,98,105,122>>

Shrinking "4oc💥🍪🤷🏻‍🐄🙄😍🤜🏼😸🍕u🙄~_mck💥@2jf9.biz"
...
(117 time(s))
<<98,240,159,165,131,240,159,141,149,97,64,97,46,99,111,109>>


  1) property good normal emails with no bourbon or pizza emojis!! (AuthStateless)
     test/property/auth_stateless_test.exs:32
     Property Elixir.AuthStateless.property good normal emails with no bourbon or pizza emojis!!() failed. Counter-Example is:
     ["b🥃🍕a@a.com"]

     code: nil
     stacktrace:
       (propcheck) lib/properties.ex:126: PropCheck.Properties.handle_check_results/3
       test/property/auth_stateless_test.exs:32: (test)



Finished in 8.6 seconds
4 properties, 16 tests, 1 failure, 19 excluded

Randomized with seed 443548
```

## Running Stateful Tests

The commands are printed out just for testing purposes. Notice how they start simple then slowly get more complex.

Same idea as the basic test, just now its running sets of functions instead of just more complex arguments.

```sh
▶ auth mix test --only stateful
Including tags: [:stateful]
Excluding tags: [:test]

****************************************
COMMANDS: [
  {:set, {:var, 1},
   {:call, AuthClientShim, :create_user_new,
    ["1+@0.org", "dustin", "713f5bac-61d4-481d-b3f0-67b99e1c0eb0"]}}
]
.****************************************
COMMANDS: [
  {:set, {:var, 1},
   {:call, AuthClientShim, :create_user_new,
    ["5🍕0@u.io", "dustin", "54f03fb9-0204-48e6-b905-d88d6ad43a4d"]}}

...

COMMANDS: [
  {:set, {:var, 1},
   {:call, AuthClientShim, :create_user_new,
    ["agg👍👍🔥🏀💵😍🔥🍕?}💵{🎒5pp@7xljyx-wr3eowfezu0req1vot9w6.biz",
     "dustin", "e46fd872-d8fe-49f4-903d-e59dd6e7669a"]}},
  {:set, {:var, 2},
   {:call, AuthClientShim, :create_user_existing,
    [
      %{
        email_address: "agg👍👍🔥🏀💵😍🔥🍕?}💵{🎒5pp@7xljyx-wr3eowfezu0req1vot9w6.biz",
        name: "dustin",
        uuid: "e46fd872-d8fe-49f4-903d-e59dd6e7669a"
      }
    ]}},
  {:set, {:var, 3},
   {:call, AuthClientShim, :create_user_existing,
    [
      %{
        email_address: "agg👍👍🔥🏀💵😍🔥🍕?}💵{🎒5pp@7xljyx-wr3eowfezu0req1vot9w6.biz",
        name: "dustin",
        uuid: "e46fd872-d8fe-49f4-903d-e59dd6e7669a"
      }
    ]}},
  {:set, {:var, 4},
   {:call, AuthClientShim, :create_user_existing,
    [
      %{
        email_address: "agg👍👍🔥🏀💵😍🔥🍕?}💵{🎒5pp@7xljyx-wr3eowfezu0req1vot9w6.biz",
        name: "dustin",
        uuid: "e46fd872-d8fe-49f4-903d-e59dd6e7669a"
      }
    ]}},
  {:set, {:var, 5},
   {:call, AuthClientShim, :update_user_existing,
    [
      %{
        email_address: "agg👍👍🔥🏀💵😍🔥🍕?}💵{🎒5pp@7xljyx-wr3eowfezu0req1vot9w6.biz",
        name: "dusty updated name",
        uuid: "e46fd872-d8fe-49f4-903d-e59dd6e7669a"
      }
    ]}},
  {:set, {:var, 6},
   {:call, AuthClientShim, :create_user_existing,
    [
      %{
        email_address: "agg👍👍🔥🏀💵😍🔥🍕?}💵{🎒5pp@7xljyx-wr3eowfezu0req1vot9w6.biz",
        name: "dusty updated name",
        uuid: "e46fd872-d8fe-49f4-903d-e59dd6e7669a"
      }
    ]}},
  {:set, {:var, 7},
   {:call, AuthClientShim, :update_user_existing,
    [
      %{
        email_address: "agg👍👍🔥🏀💵😍🔥🍕?}💵{🎒5pp@7xljyx-wr3eowfezu0req1vot9w6.biz",
        name: "dusty updated name",
        uuid: "e46fd872-d8fe-49f4-903d-e59dd6e7669a"
      }
    ]}}
]
```

## Running Parallel Test

Same thing here except it spawns a process and runs sets of commands at the same time.

Works for testing race conditions and workflows you could not replica manually or even think of testing.

```sh
▶ auth mix test --only stateful_parallel
Including tags: [:stateful_parallel]
Excluding tags: [:test]

****************************************
COMMANDS: {[
   {:set, {:var, 1},
    {:call, AuthClientShim, :create_user_new,
     ["h💥*@u.io", "dustin", "b13bcae1-86c2-4a9f-a0d8-0036ed8cec62"]}}
 ],
 [
   [
     {:set, {:var, 2},
      {:call, AuthClientShim, :update_user_existing,
       [
         %{
           email_address: "h💥*@u.io",
           name: "dusty updated name",
           uuid: "b13bcae1-86c2-4a9f-a0d8-0036ed8cec62"
         }
       ]}},
     {:set, {:var, 4},
      {:call, AuthClientShim, :create_user_existing,
       [
         %{
           email_address: "h💥*@u.io",
           name: "dusty updated name",
           uuid: "b13bcae1-86c2-4a9f-a0d8-0036ed8cec62"
         }
       ]}}
   ],
   [
     {:set, {:var, 3},
      {:call, AuthClientShim, :create_user_new,
       ["x1@b.com", "dustin", "ebce5d61-c2c9-46d9-99dd-09e61aa6c469"]}},
     {:set, {:var, 5},
      {:call, AuthClientShim, :create_user_new,
       ["a🍪^@k.com", "dustin", "b8658a85-b286-471d-bcc1-96bc53aa4aaf"]}},
     {:set, {:var, 6},
      {:call, AuthClientShim, :update_user_existing,
       [
         %{
           email_address: "x1@b.com",
           name: "dusty updated name",
           uuid: "ebce5d61-c2c9-46d9-99dd-09e61aa6c469"
         }
       ]}}
   ]
 ]}
.****************************************
COMMANDS: {[],
 [
   [
     {:set, {:var, 6},
      {:call, AuthClientShim, :create_user_new,
       ["a4@n.io", "dustin", "95db8715-5b75-48c6-8e9a-1aef2331891c"]}},
     {:set, {:var, 7},
      {:call, AuthClientShim, :create_user_new,
       ["w🤜🏼5@x.net", "dustin", "44993449-bbc1-42ac-9f86-277630d287df"]}},
     {:set, {:var, 8},
      {:call, AuthClientShim, :create_user_existing,
       [
         %{
           email_address: "w🤜🏼5@x.net",
           name: "dustin",
           uuid: "44993449-bbc1-42ac-9f86-277630d287df"
         }
       ]}},
     {:set, {:var, 9},
      {:call, AuthClientShim, :update_user_existing,
       [
         %{
           email_address: "w🤜🏼5@x.net",
           name: "dusty updated name",
           uuid: "44993449-bbc1-42ac-9f86-277630d287df"
         }
       ]}}
   ],
   [
     {:set, {:var, 1},
      {:call, AuthClientShim, :create_user_new,
       ["7💥🎒@6.biz", "dustin", "482ef864-5ffa-4f7e-a514-936b8c863d04"]}},
     {:set, {:var, 2},
      {:call, AuthClientShim, :create_user_existing,
       [
         %{
           email_address: "7💥🎒@6.biz",
           name: "dustin",
           uuid: "482ef864-5ffa-4f7e-a514-936b8c863d04"
         }
       ]}},
     {:set, {:var, 3},
      {:call, AuthClientShim, :update_user_existing,
       [
         %{
           email_address: "7💥🎒@6.biz",
           name: "dusty updated name",
           uuid: "482ef864-5ffa-4f7e-a514-936b8c863d04"
         }
       ]}},
     {:set, {:var, 4},
      {:call, AuthClientShim, :create_user_existing,
       [
         %{
           email_address: "7💥🎒@6.biz",
           name: "dusty updated name",
           uuid: "482ef864-5ffa-4f7e-a514-936b8c863d04"
         }
       ]}},
     {:set, {:var, 5},
      {:call, AuthClientShim, :update_user_existing,
       [
         %{
           email_address: "7💥🎒@6.biz",
           name: "dusty updated name",
           uuid: "482ef864-5ffa-4f7e-a514-936b8c863d04"
         }
       ]}}
   ]
 ]}
```