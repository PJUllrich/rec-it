defmodule Recit.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RecitWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:recit, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Recit.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Recit.Finch},
      # Start a worker by calling: Recit.Worker.start_link(arg)
      # {Recit.Worker, arg},
      # Start to serve requests, typically the last entry
      RecitWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Recit.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RecitWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
