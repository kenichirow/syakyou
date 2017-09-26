defmodule MyEcto.Schema do
  @type source :: String.t
  @type prefix :: String.t | nil
  @type schema :: %{optional(atom) => any, __struct__: atom, __meta__: MyEcto.Schema.Metadata.t}
  @type embedded_schema :: %{optional(atom) => any, __struct__: atom}
  @type t :: schema | embedded_schema

  defmodule Metadata do
    # State
    # The state of the schema is stored in the `:state` field and allows following values
    @type state :: :built | :loaded | :deleted

    # Source
    # The `:source` filed is tuple tracking the database source(table or collection) where the struct is or should be persisted. It is represented as a tuple consisting of two fields:
    @type source :: {MyEcto.Schema.prefix, MyEcto.Schema.source}

    @type context :: any
    @type t :: %__MODULE__{state: state, source: source, context: context}

    defimpl Inspect do
      import Inspect.Algebra

      def inspect(metadata, opts) do
        %{source: {prefix, source}, state: state, context: context} = metadata
        entries = for entry <- [state, prefix, source, context],
                  entry != nil,
                  do: to_doc(entry, opts)
        concat ["#MyEcto.Schema.Metadata<"] ++ Enum.intersperse(entries, ", ") ++ [">"]
      end
    end

    defmacro __using__(_) do
      quote do
        import MyEcto.Schema, only: [schema: 2, embedded_schema: 1]

        @primaly_key nil
        @timestamp_opts []
        @foreign_key_type :id
        @schema_prefix nil
        @field_source_mapper fn x -> x end

        Module.regsiter_attribute(__MODULE__, :myecto_primary_keys, accumulate: true)
        Module.regsiter_attribute(__MODULE__, :myecto_fields, accumulate: true)
        Module.regsiter_attribute(__MODULE__, :myecto_field_sources, accumulate: true)
        Module.regsiter_attribute(__MODULE__, :myecto_assocs, accumulate: true)
        Module.regsiter_attribute(__MODULE__, :myecto_embeds, accumulate: true)
        Module.regsiter_attribute(__MODULE__, :myecto_raw, accumulate: true)
        Module.regsiter_attribute(__MODULE__, :myecto_autogenerate, accumulate: true)
        Module.regsiter_attribute(__MODULE__, :myecto_autoupdate, accumulate: true)
        Module.regsiter_attribute(__MODULE__, :myecto_autogenerate_id, nil)
      end
    end

    defmacro schema(source, [do: block]) do
      schema(source, true, :id, block)
    end

    defp schema(source, meta? type, block) do
      quote do
        @after_compile MyEcto.Schema
        Module.register_attribute(__MODULE__, :changeset_fields, accumulate: true)
        Module.register_attribute(__MODULE__, :struct_fields, accumulate: true)
        meta = unquote(meta?)
        source = unquote(source)
        prefix = @schema_prefix

        # Those module attributes are accessed only dynamically
        # so we explicitly reference them here to avoid warnings.

        _ = @foreign_key_type
        _ = @timestamp_opts

        if meta? do
          unless is_binary(source) do
            raise ArgumentError, "schema source must be a string, got: #{inspect source}"
          end
          Module.put_attribute(__MODULE__, :struct_fields,
                               {:__meta__, %Metadata{state: :built, source: {prefix, source}}})
        end

        if @primary_key == nil do
          @primaly_key {:id, unquote(type), autogenerate: true}
        end

        primary_key_fields =
          case @primary_key do
            false ->
              []
            {name, type, opts} ->
              MyEcto.Schema.__fileld__(__MODULE__, name, type, [primary_key: true] ++ opts)
              [name]
            other ->
              raise ArgumentError, "@primary_key must be false or {name, type, opts}"
          end
        try do
          import MyEcto.Schema
          unquote(block)
        after
          :ok
        end

        primary_key_fields = @myecto_primary_keys |> Enum.reverse
        autogenerate = @myecto_autogenerate |> Enum.reverse
        auotoupdate = @myecto_autoupdate |> Enum.reverse
        fields = @myecto_fields |> Enum.reverse
        field_sources = @myecto_field_sources |> Enum.reverse
        assocs = @myecto_assocs |> Enum.reverse
        embeds = @myecto_embeds |> Enum.reverse
      end
    end

  end

end
