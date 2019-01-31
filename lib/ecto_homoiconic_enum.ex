defmodule EctoHomoiconicEnum do
  @moduledoc """
  Support for defining enumerated types.

  See `EctoHomoiconicEnum.defenum/2` for usage.
  """

  defmodule ConflictingTypesError do
    defexception [:message]

    def exception({module, mappings}) do
      if expected = prominent(histogram(mappings)) do
        conflicts =
          case expected do
            :integers ->
              Enum.reduce(mappings, [], fn ({member, internal}, conflicts) ->
                if is_binary(internal) do [member | conflicts] else conflicts end
              end)
            :binaries ->
              Enum.reduce(mappings, [], fn ({member, internal}, conflicts) ->
                if is_integer(internal) do [member | conflicts] else conflicts end
              end)
          end

        culprits =
          conflicts
          |> Enum.map(&("`#{&1}`"))
          |> Enum.join(", ")

        plural =
          length(conflicts) >= 2

        indicative =
          if plural do "are" else "is" end

        message =
          "You have specified conflicting data types for `#{module}`! " <>
          "You can only map to one data type, i.e. integers or strings, but not both. " <>
          "Specifically, #{culprits} #{indicative} not mapped to #{expected} while other members are."

        %__MODULE__{message: message}
      else
        message =
          "You have specified conflicting data types for `#{module}`! " <>
          "You can only map to one data type, i.e. integers or strings, but not both."

        %__MODULE__{message: message}
      end
    end

    defp histogram(mappings) when is_list(mappings) do
      Enum.reduce(mappings, %{integers: 0, binaries: 0}, fn (mapping, histogram) ->
        case mapping do
          {_, internal} when is_integer(internal) -> %{histogram | integers: histogram[:integers] + 1}
          {_, internal} when is_binary(internal) -> %{histogram | binaries: histogram[:binaries] + 1}
        end
      end)
    end

    defp prominent(%{integers: integers, binaries: binaries}) when integers > binaries, do: :integers
    defp prominent(%{integers: integers, binaries: binaries}) when binaries > integers, do: :binaries
    defp prominent(_), do: nil
  end

  @doc """
  Defines a custom enumerated `Ecto.Type`.

  It can be used like any other `Ecto.Type`:

      import EctoHomoiconicEnum, only: [defenum: 2]
      defenum User.Status, active: 1, inactive: 2, archived: 3

      defmodule User do
        use Ecto.Model

        schema "users" do
          field :status, User.Status
        end
      end

  In this example, the `status` column can only assume the three stated values
  (or `nil`), and will automatically convert atoms and strings passed to it
  into the specified stored value. Integers in this case. This applies to
  saving the model, invoking `Ecto.Changeset.cast/4`, or performing a query on
  the `status` field.

  Continuing from the previous example:

      iex> user = Repo.insert!(%User{status: :active})
      iex> Repo.get(User, user.id).status
      :registered

      iex> %{changes: changes} = cast(%User{}, %{"status" => "inactive"}, [:status], [])
      iex> changes.status
      :inactive

      iex> from(u in User, where: u.status == :inactive) |> Repo.all |> length
      1

  Passing an invalid value to a `Ecto.Changeset.cast` will add an error to
  `changeset.errors` field.

      iex> changeset = cast(%User{}, %{"status" => "minister_of_silly_walks"}, [:status], [])
      iex> changeset.errors
      [status: "is invalid"]

  Likewise, putting an invalid value directly into a model struct will casue an
  error when calling `Repo` functions.

  The generated module `User.Status` also exposes a reflection functions for
  inspecting the type at runtime.

      iex> User.Status.__members__()
      [:active, :inactive, :archived]
      iex> User.Status.__mappings__()
      [active: 1, inactive: 2, archived: 3]

  For static type checking with tools such as dialyzer, you can access a type
  containing the list of all valid enum values with the `t()` type. For example:

      import EctoHomoiconicEnum, only: [defenum: 2]
      defenum MyEnum, [:a, :b, :c]

      # There is now an automatically generated type in the MyEnum module
      # of the form:
      # @type t() :: :a | :b | :c

      @spec my_fun(MyEnum.t()) :: boolean()
      def my_fun(_v), do: true
  """
  defmacro defenum(module, list_or_mapping) when is_list(list_or_mapping) do
    typespec = Enum.reduce(list_or_mapping, [],
      fn a, acc when is_atom(a) or is_binary(a) -> add_type(a, acc)
         {a, _}, acc when is_atom(a) -> add_type(a, acc)
         _, acc -> acc
      end
    )

    quote do
      list_or_mapping = Macro.escape(unquote(list_or_mapping))

      storage = EctoHomoiconicEnum.storage(list_or_mapping)

      if storage in [:indeterminate],
        do: raise EctoHomoiconicEnum.ConflictingTypesError, {unquote(module), list_or_mapping}

      {member_to_internal, internal_to_member} = EctoHomoiconicEnum.mapping(list_or_mapping)

      members = Map.keys(member_to_internal)
      internals = Map.values(member_to_internal)

      defmodule unquote(module) do
        @behaviour Ecto.Type

        @storage storage

        @members members
        @internals internals

        @member_to_internal member_to_internal
        @internal_to_member internal_to_member

        @type t :: unquote(typespec)

        def type, do: @storage

        def cast(stored) when is_integer(stored),
          do: Map.fetch(@internal_to_member, stored)
        def cast(member) when is_binary(member),
          do: cast(String.to_existing_atom(member))
        def cast(member) when member in @members,
          do: {:ok, member}
        def cast(_), do: :error

        def dump(stored) when is_binary(stored),
          do: Map.fetch(@member_to_internal, String.to_existing_atom(stored))
        def dump(stored) when is_atom(stored),
          do: Map.fetch(@member_to_internal, stored)
        def dump(stored) when stored in @internals,
          do: {:ok, stored}
        def dump(_), do: :error

        def load(internal), do: Map.fetch(@internal_to_member, internal)

        def __members__(), do: @members
        def __mappings__(), do: @member_to_internal
      end
    end
  end

  # Tries to determine the appropriate backing type ("storage") based on the
  # provided mappings. Defaults to `string` when not provided any explicit
  # mapping.
  def storage(list_or_mapping) when is_list(list_or_mapping) do
    cond do
      Enum.all?(list_or_mapping, &(is_atom(&1) or is_binary(&1))) -> :string
      Enum.all?(list_or_mapping, &(is_integer(elem(&1, 1)))) -> :integer
      Enum.all?(list_or_mapping, &(is_binary(elem(&1, 1)))) -> :string
      true -> :indeterminate
    end
  end

  # Builds look up tables that map members to their stored value counterparts
  # and vice versa.
  def mapping(list_or_mapping) when is_list(list_or_mapping) do
    {members, internal} = cond do
      Enum.all?(list_or_mapping, &is_atom/1) ->
        {list_or_mapping, Enum.map(list_or_mapping, &Atom.to_string/1)}
      Enum.all?(list_or_mapping, &is_binary/1) ->
        {Enum.map(list_or_mapping, &Atom.to_string/1), list_or_mapping}
      true ->
        {Keyword.keys(list_or_mapping), Keyword.values(list_or_mapping)}
    end

    {Enum.zip(members, internal) |> Map.new,
     Enum.zip(internal, members) |> Map.new}
  end

  defp add_type(type, acc), do: {:|, [], [acc, type]}
end
