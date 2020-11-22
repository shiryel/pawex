# Pawex

  Pawex is a tree based code executioner, that can be used to test complex APIs!

## Raw usage

```
use Pawex

paw :login, _status, [] do
  token = get_token()
  {:ok, %{token: token}}
end

paw :list_users, %{token: token}, [:login] do
  users = list_users(token)
  {:ok, %{users: users}}
end
```

When executing this with the escript, it will result in something like this:
```
[OK] login
[OK] list_users
```

If something explode it will result in something like this
```
(raised ...)
[ERROR] login
[-] list_users
```

## Usage with `Pawex.Tester`

But most of the time you will want to use this lib with our abstractions, like the API Tester.
What it does? well... it will abstract many things, the configuration, what is expected and how it will explode and be showed!
Take a look on a example:

```
use Pawex
import Pawex.Tester


paw :login, _status, [] do
  new(base_url: "http://localhost:4000")
  |> get("/login")
  |> expect(200)
  |> keep(["token"])
end
```

Pawex.Tester is very especial, it will use your status to do things! (and will not raise a error)
Take a look at `Pawex.Tester`!

## Installation

```elixir
def deps do
  [
    {:pawex, "~> 0.1.0"}
  ]
end
```

## Why so many paws?

Because when we are making tests we need to test step by step (and is the sound of the AWP killing the bugs :P)
