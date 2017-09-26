defmodule MyEcto.Repo do
  defmacro __using(opts) do
    quote bind_quoted: [opts: opts] do
      @behaviour MyEcto.Repo
      {otp_app, adapter, config} = MyEcto.Repo.Supervisor.compile_config(__MODULE__, opts)
      @otp_app otp_app
      @adapter adapter
      @config  config
      @before_compile adapter

      def __adapter__ do
        @adapter
      end

      def config do
        {:ok, config} = MyEcto.Repo.Supervisor.runtime_config(:dry_run, __MODULE__, @otp_app, [])
        config
      end

      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]},
          type: :supervisor
        }
      end

      def start_link(opts \\ []) do
        MyEcto.Repo.Supervisor.start_link(__MODULE__, @otp_app, @adapter, opts)
      end

      def stop(pid, timeout \\ 5000) do
        Supervisor.stop(pid, :normal, timeout)
      end

      if function_exported?(@adapter, :transaction, 3) do
        def transaction(fun_or_multi, opts \\ []) do
          MyEcto.Repo.Queryable.transaction(@adapter, __MODULE__, fun_of_multi, opts)
        end

        def in_transaction? do
          @adapter.in_transaction?(__MODULE__)
        end

        def rollback(value) do
          @adapter.rollback(__MODULE__, value)
        end
      end

      def all(queryable, opts \\ []) do
        MyEcto.Repo.Queryable.all(__MODULE__, @adapter, queryable, opts)
      end

      def stream(queryable, opts \\ []) do
        MyEcto.Repo.Queryable.stream(__MODULE__, @adapter, queryable, opts)
      end

      def get(queryable, id, opts \\ []) do
        MyEcto.Repo.Queryable.get(__MODULE__, @adapter, queryable, id, opts)
      end

      def get!(queryable, id, opts \\ []) do
        MyEcto.Repo.Queryable.get!(__MODULE__, @adapter, queryable, id, opts)
      end

      def get_by(queryable, clauses, opts \\ []) do
        MyEcto.Repo.Queryable.get_by(__MODULE__, @adapter, queryable, clauses, opts)
      end

      def get_by(queryable, clauses, opts \\ []) do
        MyEcto.Repo.Queryable.get_by(__MODULE__, @adapter, queryable, clauses, opts)
      end

      def one(queryable, opts \\ []) do
        MyEcto.Repo.Queryable.one(__MODULE__, @adapter, queryable, opts)
      end

      def one(queryable, opts \\ []) do
        MyEcto.Repo.Queryable.one(__MODULE__, @adapter, queryable, opts)
      end

      def aggregate(queryable, aggregate, field, opts \\ []) 
           when aggregate in [:count, :avg, :min, :sum] and is_atom(field) do

        MyEcto.Repo.Queryable.one(__MODULE__, @adapter, queryable, aggregate, field, opts)
      end

      def insert_all(schema_or_source, entries, opts \\ []) do
        MyEcto.Repo.Queryable.insert_all(__MODULE__, @adapter, schema_or_source, entries, opts)
      end

      def update_all(queryable, updates, opts \\ []) do
        MyEcto.Repo.Queryable.update_all(__MODULE__, @adapter, queryable, updates, opts)
      end

      def delete_all(queryable, opts \\ []) do
        MyEcto.Repo.Queryable.delete_all(__MODULE__, @adapter, queryable, opts)
      end

      def insert(struct, opts \\ []) do
        MyEcto.Repo.Schema.insert(__MODULE__, @adapter, struct, opts)
      end

      def update(struct, opts \\ []) do
        MyEcto.Repo.Schema.update(__MODULE__, @adapter, struct, opts)
      end

      def instert_or_update(changeset, opts \\ []) do
        MyEcto.Repo.Schema.insert_or_update(__MODULE__, @adapter, changeset, opts)
      end

      def delete(struct, opts \\ []) do
        MyEcto.Repo.Schema.delete(__MODULE__, @adapter, struct, opts)
      end

      def insert!(struct, opts \\ []) do
        MyEcto.Repo.Schema.insert!(__MODULE__, @adapter, struct, opts)
      end

      def update!(struct, opts \\ []) do
        MyEcto.Repo.Schema.update!(__MODULE__, @adapter, struct, opts)
      end

      def insert_or_update!(changeset, opts \\ []) do
        MyEcto.Repo.Schema.insert_or_update!(__MODULE__, @adapter, changeset, opts)
      end

      def delete!(struct, opts \\ []) do
        MyEcto.Repo.Schema.delete!(__MODULE__, @adapter, struct, opts)
      end

      def preload(struct_or_structs_or_nil, preloads, opts \\ []) do
        MyEcto.Repo.Preloader.preload(struct_or_structs_or_nil, __MODULE__, preloads, opts)
      end

      def load(schema_or_types, data) do
        MyEcto.Repo.Schema.load(@adapter, schema_or_types, data)
      end

      defoverridable child_spec: 1

    end
  end

  @optional_callbacks init: 2 

  @callback __adapter__ :: MyEcto.Adapter.t

  @callback __log__(entry :: MyEcto.LogEntry.t) :: MyEcto.LogEntry.t

  @doc """
  Returns the adapter configuration stored in the `:otp_app` environment.
  If the `c:init/2` callback is implemented in the repository,
  it will be invoked with the first argument set to `:dry_run`.
  """
  @callback config() :: Keyword.t

  @doc """
  Starts any connection pooling or supervision and return `{:ok, pid}`
  or just `:ok` if nothing needs to be done.
  """
  @callback start_link(opts :: Keyword.t) :: {:ok, pid} |
                                             {:error, {:already_started, pid}} |
                                             {:error, term}
  @callback init(:supervisor | :dry_run, config :: Keyword.t) :: {:ok, Keyword.t} | :ignore 
  @callback stop(pid, timeout) :: :ok
  @callback get(queryable :: MyEcto.Queryable.t, id ::term, opts :: Keyword.t) :: MyEcto.Schema.t | nil | no_return
  @callback get!(queryable :: MyEcto.Queryable.t, id ::term, opts :: Keyword.t) :: MyEcto.Schema.t | nil | no_return
  @callback get_by(queryable :: MyEcto.Queryable.t, clauses :: Keyword.t | map, opts :: Keyword.t) :: MyEcto.Schema.t | nil | no_return

  @callback get_by!(queryable :: MyEcto.Queryable.t, clauses :: Keyword.t | map, opts :: Keyword.t) :: MyEcto.Schema.t | nil | no_return

  @doc """
  Calculate the given `aggregate` over the given `field`.
  If the query has a limit, offset or distinct set, it will be
  automatically wrapped in a subquery in order to return the
  proper result.
  Any preload or select in the query will be ignored in favor of
  the column being aggregated.
  The aggregation will fail if any `group_by` field is set.
  ## Options
 
  See the "Shared options" section at the module documentation.

  ## Examples
  
      # Returns the number of visits per blog post
      Repo.aggregate(Post, :count, :visits)

      # Returns the average number of visits for the top 10
      query = from Post, limit: 10
      Repo.aggregate(query, :avg, :visits)
  """
  @callback aggregate(queryable :: MyEcto.Queryable.t, aggregate :: :avg | :count | :max | :min | :sum,
                      field :: atom, opts :: Keyword.t) :: term | nil

  @callback one(queryable :: MyEcto.Queryable.t, opts :: Keyword.t) :: MyEcto.Schema.t | nil | no_return

  @callback one!(queryable :: MyEcto.Queryable.t, opts :: Keyword.t) :: MyEcto.Schema.t | nil | no_return


  @callback preload(struct_or_structs_or_nil, preloads :: term, opts :: Keyword.t) ::
                    struct_or_structs_or_nil when struct_or_structs_or_nil: [MyEcto.Schema.t] | MyEcto.Schema.t | nil

  @callback all(queryable :: MyEcto.Query.t, opts :: Keyword.t) :: [MyEcto.Schema.t] | no_return

  @callback stream(queryable :: MyEcto.Query.t, opts :: Keyword.t) :: Enum.t

  @callback inert_all(schema_or_source :: binary | {binary, MyEcto.Schema.t} | MyEcto.Schema.t,
                      entries :: [map | Keyword.t], opts :: Keyword.t) :: {integer, nil | [term]} | no_return
  

  @doc """                     
      ## Examples

      MyRepo.update_all(Post, set: [title: "New title"])

      MyRepo.update_all(Post, inc: [visits: 1])

      from(p in Post, where: p.id < 10)
      |> MyRepo.update_all(set: [title: "New title"])

      from(p in Post, where: p.id < 10, update: [set: [title: "New title"]])
      |> MyRepo.update_all([])

      from(p in Post, where: p.id < 10, update: [set: [title: ^new_title]])
      |> MyRepo.update_all([])

      from(p in Post, where: p.id < 10, update: [set: [title: fragment("upper(?)", ^new_title)]])
      |> MyRepo.update_all([])
  """
  @callback update_all(queryable :: MyEcto.Queryable.t, updates :: Keyword.t, opts :: Keyword.t) ::
                       {integer, nil | [term]} | no_return

  @callback delete_all(queryable :: MyEcto.Queryable.t, updates :: Keyword.t, opts :: Keyword.t) ::
                       {integer, nil | [term]} | no_return


  @callback insert(struct_or_changeset :: MyEcto.Schema.t | MyEcto.Changeset.t, opts :: Keyword.t) ::
                   {:ok, MyEcto.Schema.t} | {:error, MyEcto.Changeset.t}

  @callback update(changeset :: MyEcto.Changesett, opts :: Keyword.t) ::
                   {:ok, MyEcto.Schema.t} | {:error, MyEcto.Changeset.t}

  @callback insert_or_update(changeset :: MyEcto.Changeset.t, opts :: Keyword.t) ::
                    {:ok, MyEcto.Schema.t} | {:error, MyEcto.Changest.t}
  @callback delete(struct_or_changeset :: MyEcto.Schema.t | MyEcto.Changeset.t, opts :: Keyword.t) ::
                    {:ok, MyEcto.Schema.t} | {:error, MyEcto.Changeset.t}

  @callback insert!(struct_or_changeset :: MyEcto.Schema.t | MyEcto.Changeset.t, opts :: Keyword.t) ::
                   {:ok, MyEcto.Schema.t} | {:error, MyEcto.Changeset.t}
  @callback update!(changeset :: MyEcto.Changesett, opts :: Keyword.t) ::
                   {:ok, MyEcto.Schema.t} | {:error, MyEcto.Changeset.t}
  @callback insert_or_update!(changeset :: MyEcto.Changeset.t, opts :: Keyword.t) ::
                    {:ok, MyEcto.Schema.t} | {:error, MyEcto.Changest.t}
  @callback delete!(struct_or_changeset :: MyEcto.Schema.t | MyEcto.Changeset.t, opts :: Keyword.t) ::
                    {:ok, MyEcto.Schema.t} | {:error, MyEcto.Changeset.t}

  @callback transaction(fun_or_multi :: fun | MyEcto.Muti.t, opts :: Keyword.t) ::
                        {:ok, any} | {:error, any} | {:error, atom, any, %{atom => any}}
  @optional_callbacks [transaction: 2]
  @callback in_transaction?() :: boolean
  @optional_callbacks [in_transaction?: 0]

  @callback rollback(value :: any) :: no_return
  @optional_callbacks [rollback: 1]
  @callback load(MyEcto.Schema.t | map(), map() | Keyword.t | {list, list}) :: MyEcto.Schema.t | map()
end

