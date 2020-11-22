defmodule PawexTest do
  use ExUnit.Case
  doctest Pawex

  describe "Complete use-case" do
    defmodule Test do
      use Pawex

      paw :login, state, [] do
        new_state = Map.put(state, :login, true)
        {:ok, new_state}
      end

      paw :login_2, state, [] do
        new_state = Map.put(state, :login_2, true)
        {:ok, new_state}
      end

      paw :list_users, state, [:login, :login_2] do
        new_state = Map.put(state, :users, [%{name: "shiryel"}])
        {:ok, new_state}
      end

      paw :register_users, %{users: users} = state, [:login, :list_users] do
        new_users =
          Enum.map(users, fn x ->
            Map.put(x, :registered, true)
          end)

        {:ok, %{state | users: new_users}}
      end
    end

    test "__paw__/2" do
      assert {:ok, state} = Test.__pre_paw__(:register_users, %{})

      assert {:ok, %{login: true, login_2: true, users: [%{name: "shiryel", registered: true}]}} =
               Test.__paw__(:register_users, state)
    end
  end
end
