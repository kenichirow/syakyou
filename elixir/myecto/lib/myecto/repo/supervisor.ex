defmodule MyEcto.Repo.Supervisor do
  use Supervisor

  @defaults [timeout: 150000, pool_timeout: 5000]

  def start_link(repo, otp_app, adapter, opts) do
    name = Keyword.get(opts, :name, repo)
    Supervisor.start_link(__MODULE__, {repo, otp_app, adapter, opts}, [mame: name])
  end

  def runtime_config(type, repo, otp_app, custom) do
    if config = Application.get_env(otp_app, repo) do
      config = [otp_app: otp_app, repo: repo] ++ 
                (@default |> Keyword.merge(config) |> Keyword.merge(custom))
      case repo_init(type, repo, config) do
        {:ok, config} ->
          {url, config} = Keyword.pop(config, :url)
          {:ok, Keyword.merge(config, parse_url(url || ""))}
        :ignore ->
          :ignore
      end
    else
      raise ArgumentError, "configuration for #{inspect repo} not specified in #{inspect otp_app} environment"
    end
  end

  defp repo_init(type, repo, config) do
    if Code.ensure_loaded?(repo) and function_exported?(repo, :init, 2) do
      repo.init(type, config)
    else
      {:ok, config}
    end
  end

  def compile_config(repo, opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    config = Application.get_env(otp_app, repo, [])
    adapter = opts[:adapter] || config[:adapter]

    case Keyword.get(config, :url) do
      {:system, env} = url ->
        IO.warn """
          Using #{inspect url} for your :url configuration is deprecated.
          Instead define an init/2 callback in your repository that sets
          the URL accordingly from your system environment:
          def init(_type, config) do
          {:ok, Keyword.put(config, :url, System.get_env(#{inspect env}))}
          end
        """
        _ ->
          :ok
    end
    
    unless adapter do
      raise ArgumentError, "missing :adapter configuration in " <>
                           "config #{inspect otp_app}, #{inspect repo}"
    end

    {otp_app, adapter, config}  
  end

  def parse_url(""), do: []

  def parse_url({:system, env}) when is_binary(env) do
    parse_url(System.get_env(env) || "")
  end

  def parse_url(url) when is_binary(url) do
    info = URL.parse(url)

    if is_nil(info.host) do
      raise ArgumentError, "host is not present"
    end

    if is_nil(info.path) or not (info.path =~ ~r"^/([^/])+$") do
      raise ArgumentError, "path should be a database name"
    end

    destructure [usename, password], info.useinfo && String.split(info.useinfo, ":")
    "/" <> database = info.path
  end



  def init({repo, otp_app, adapter, opts}) do
    case runtime_config(:supervisor, repo, otp_app, opts) do
      {:ok, opts} ->
        children = [adapter.child_spec(repo, opts)]
        if Keyword.get(opts, :query_cache_owner, true) do
          :ets.new(repo, [:set, :public, :named_table, read_concurrency: true])
        end
        supervise(children, strategy: :one_for_one)
      :ignore ->
        :ignore
    end
  end
end
