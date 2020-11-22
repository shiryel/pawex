defmodule Pawex.Tree do
  @moduledoc """
  Defines the tree implementation used by `Pawex`

  You can use `use Pawex.Tree` to use and define these callbacks/macros

  ## How it works

  When you call `paw/5` it will generate functions for the `c:__pre_paw__/2` and `c:__paw__/2`, these functions works together, first the `state` is mounted using the `c:__pre_paw__/2`, it will get the state calling the `needs`'s `c:__pre_paw__/2` and `c:__paw__/2`, and when all the `needs` are complete it will then return the final `state`, that can then be used on `c:__paw__/2`

  For easy calls, its registered the attribute `@__paws__` containing all the steps defined with `paw/5`

  Yes, the tree is defined on compilation time and its all pattern match, amazing, no?
  """

  @doc """
  Gets the state needed to run the `c:__paw__/2`
  """
  @callback __pre_paw__(
              name :: atom(),
              state
            ) :: {:ok, state} | {:error, state}
            when state: term()

  @doc """
  Get the state for the current `step`
  """
  @callback __paw__(
              name :: atom(),
              state
            ) :: {:ok, state} | {:error, state}
            when state: term()

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      Module.register_attribute(__MODULE__, :__paws__, accumulate: true, persist: true)

      require Pawex.Tree
      import Pawex.Tree
      @behaviour Pawex.Tree
      @on_definition Pawex.Tree

      @doc """
      Main function of the `Pawex.Tree`, it will execute all the `c:Pawex.Tree.__pre_paw__/2` and `c:Pawex.Tree.__paws__/2` in order of declaration of the `paw/5`

      ## Example:

      If you declare a paw with

      ```
      defmodule BasicTest do
        use Pawex.Tree

        paw :login, state, [] do
          new_state = Map.put(state, :login, true)
          {:ok, new_state}
        end
      end
      ```

      And then run `paw_run/0`

      iex> BasicTest.paw_run()
      [ok: %{login: true}] 
      """
      def paw_run do
        get_attributes(__MODULE__, :__paws__)
        |> Enum.reduce_while([], fn
          x, acc ->
            with {:ok, state} <- apply(__MODULE__, :__pre_paw__, [x, %{}]),
                 {:ok, state} <- apply(__MODULE__, :__paw__, [x, state]) do
              {:cont, [{:ok, state} | acc]}
            else
              {:error, state} ->
                {:halt, [{:error, state} | acc]}
            end
        end)
      end

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

      #########
      # UTILS #
      #########

      defp __get_needs__(needs) when is_list(needs) do
        extra_needs = unquote(Macro.escape(opts))[:needs] || []

        if is_list(extra_needs) do
          extra_needs ++ needs
        else
          raise(~s|In "use Pawex.Tree, needs: VALUE" VALUE needs to be a list!!!|)
        end
      end

      defp __pre_paw_maybe_continue__(module, name, state) do
        with {:ok, new_state} <- apply(module, :__pre_paw__, [name, state]),
             {:ok, result} <- apply(module, :__paw__, [name, new_state]) do
          {:cont, {:ok, result}}
        else
          {:error, state} ->
            {:halt, {:error, state}}
        end
      end
    end
  end

  @doc """
  Defines the `c:__pre_paw__/2` and `c:__paw__/2` functions for the tree that will be executed later!
  """
  @spec paw(atom(), term(), [atom() | {module(), atom()}], [when: term()], do: any | [do: any]) ::
          Macro.t()
  defmacro paw(name, state, needs, opts \\ [when: true], do: code) do
    quote do
      @impl Pawex.Tree
      @doc false
      def __pre_paw__(unquote(name), state) do
        needs = __get_needs__(unquote(needs))

        Enum.reduce_while(needs, {:ok, state}, fn
          {module, name}, {:ok, new_state} ->
            __pre_paw_maybe_continue__(module, name, new_state)

          name, {:ok, new_state} ->
            __pre_paw_maybe_continue__(__MODULE__, name, new_state)

          _, {:error, new_state} ->
            {:halt, {:error, new_state}}
        end)
      end

      @impl Pawex.Tree
      @doc false
      def __paw__(unquote(name), unquote(state)) when unquote(opts[:when]) do
        unquote(code)
      end
    end
  end

  def __on_definition__(env, :def, :__paw__, [name | _], _guards, _body) do
    Module.put_attribute(env.module, :__paws__, name)
  end

  def __on_definition__(_env, _kind, _name, _args, _guards, _body),
    do: :ignore
end
