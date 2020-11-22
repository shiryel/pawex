defmodule Pawex do
  @moduledoc """
  Pawex is a tree based code executioner, that can be used to test complex APIs as it as nothing!

  # Raw usage

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

  # Divide and conquer usage

  When we need to work with big applications, we want to have our code diveded on many collections to run, this can be easily made with `Pawex`, `:needs` option

  ```
  use Pawex, needs: [SomeOtherModule: :some_step]
  ```

  When calling the `paw` macro, the status will have the above collection :some_step state to work with!
  What? do you want to only have that on just one function? No problem, for that we have that:

  ```
  paw :very_specific_step, status, needs: [SomeOtherModule, :some_step] do
    ...
  end
  ```
  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      use Pawex.Tree, opts
    end
  end
end
