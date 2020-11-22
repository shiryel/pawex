defmodule Pawex.TreeTest do
  use ExUnit.Case

  defp get_attributes(module, attribute) do
    module.__info__(:attributes)
    |> Enum.reduce([], fn
      {^attribute, [value]}, acc ->
        [value | acc]

      _, acc ->
        acc
    end)
    |> Enum.reverse()
  end

  describe "Basic use case" do
    defmodule BasicTest do
      use Pawex.Tree

      paw :login, state, [] do
        new_state = Map.put(state, :login, true)
        {:ok, new_state}
      end
    end

    test "__pre_paw__/1" do
      assert {:ok, %{}} = BasicTest.__pre_paw__(:login, %{})
    end

    test "__paw__/2" do
      assert {:ok, %{login: true}} = BasicTest.__paw__(:login, %{})
    end

    test "attributes" do
      assert [:login] = get_attributes(BasicTest, :__paws__)
    end

    test "__paw_run__/0" do
      assert [ok: %{login: true}] = BasicTest.paw_run()
    end
  end

  describe "one need use case" do
    defmodule OneNeedTest do
      use Pawex.Tree

      paw :login, state, [] do
        new_state = Map.put(state, :login, true)
        {:ok, new_state}
      end

      paw :list_users, state, [:login] do
        new_state = Map.put(state, :users, [%{name: "shiryel"}])
        {:ok, new_state}
      end
    end

    test "__pre_paw__/1" do
      assert {:ok, %{}} = OneNeedTest.__pre_paw__(:login, %{})
      assert {:ok, %{login: true}} = OneNeedTest.__pre_paw__(:list_users, %{})
    end

    test "__paw__/2" do
      assert {:ok, state} = OneNeedTest.__pre_paw__(:list_users, %{})

      assert {:ok, %{login: true, users: [%{name: "shiryel"}]}} =
               OneNeedTest.__paw__(:list_users, state)
    end

    test "attributes" do
      assert [:login, :list_users] = get_attributes(OneNeedTest, :__paws__)
    end

    test "__paw_run__/0" do
      assert [{:ok, %{login: true, users: [%{name: "shiryel"}]}}, {:ok, %{login: true}}] =
               OneNeedTest.paw_run()
    end
  end

  describe "many need use case" do
    defmodule ManyNeedTest do
      use Pawex.Tree

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
    end

    test "__paw__/2" do
      assert {:ok, state} = ManyNeedTest.__pre_paw__(:list_users, %{})

      assert {:ok, %{login: true, login_2: true, users: [%{name: "shiryel"}]}} =
               ManyNeedTest.__paw__(:list_users, state)
    end

    test "attributes" do
      assert [:login, :login_2, :list_users] = get_attributes(ManyNeedTest, :__paws__)
    end

    test "__paw_run__/0" do
      assert [
               {:ok, %{login: true, users: [%{name: "shiryel"}], login_2: true}},
               {:ok, %{login_2: true}},
               {:ok, %{login: true}}
             ] = ManyNeedTest.paw_run()
    end
  end

  describe "Complex tree need use case" do
    defmodule ComplexTest do
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
      assert {:ok, state} = ComplexTest.__pre_paw__(:register_users, %{})

      assert {:ok, %{login: true, login_2: true, users: [%{name: "shiryel", registered: true}]}} =
               ComplexTest.__paw__(:register_users, state)
    end

    test "attributes" do
      assert [:login, :login_2, :list_users, :register_users] =
               get_attributes(ComplexTest, :__paws__)
    end

    test "__paw_run__/0" do
      assert [
               {:ok,
                %{login: true, login_2: true, users: [%{name: "shiryel", registered: true}]}},
               {:ok, %{login_2: true, login: true, users: [%{name: "shiryel"}]}},
               {:ok, %{login_2: true}},
               {:ok, %{login: true}}
             ] = ComplexTest.paw_run()
    end
  end

  describe "Complex tree need use case with another module" do
    defmodule PreTest do
      use Pawex

      paw :login, state, [] do
        new_state = Map.put(state, :login, true)
        {:ok, new_state}
      end
    end

    defmodule PosTest do
      use Pawex, needs: [{PreTest, :login}]

      paw :list_users, state, [] do
        new_state = Map.put(state, :users, [%{name: "shiryel"}])
        {:ok, new_state}
      end

      paw :register_users, %{users: users} = state, [:list_users] do
        new_users =
          Enum.map(users, fn x ->
            Map.put(x, :registered, true)
          end)

        {:ok, %{state | users: new_users}}
      end
    end

    test "__paw__/2" do
      assert {:ok, state} = PosTest.__pre_paw__(:register_users, %{})

      assert {:ok, %{login: true, users: [%{name: "shiryel", registered: true}]}} =
               PosTest.__paw__(:register_users, state)
    end

    test "attributes" do
      assert [:login] = get_attributes(PreTest, :__paws__)
      assert [:list_users, :register_users] = get_attributes(PosTest, :__paws__)
    end

    test "__paw_run__/0" do
      assert [ok: %{login: true}] = PreTest.paw_run()

      assert [
               {:ok, %{login: true, users: [%{name: "shiryel", registered: true}]}},
               {:ok, %{login: true, users: [%{name: "shiryel"}]}}
             ] = PosTest.paw_run()
    end
  end

  describe "Complex tree need use case with another module with wrong opts" do
    defmodule ErrorPreTest do
      use Pawex

      paw :login, state, [] do
        new_state = Map.put(state, :login, true)
        {:ok, new_state}
      end
    end

    defmodule ErrorPosTest do
      use Pawex, needs: {PreTest, :login}

      paw :list_users, state, [] do
        new_state = Map.put(state, :users, [%{name: "shiryel"}])
        {:ok, new_state}
      end

      paw :register_users, %{users: users} = state, [:list_users] do
        new_users =
          Enum.map(users, fn x ->
            Map.put(x, :registered, true)
          end)

        {:ok, %{state | users: new_users}}
      end
    end

    test "__paw__/2" do
      assert_raise RuntimeError,
                   ~s|In "use Pawex.Tree, needs: VALUE" VALUE needs to be a list!!!|,
                   fn -> ErrorPosTest.__pre_paw__(:register_users, %{}) end
    end
  end
end
