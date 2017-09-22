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

    end
  end
end
