defmodule Gecko.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Gecko.Repo,
      # Start the Telemetry supervisor
      GeckoWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Gecko.PubSub},
      # Start the Endpoint (http/https)
      GeckoWeb.Endpoint
      # Start a worker by calling: Gecko.Worker.start_link(arg)
      # {Gecko.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Gecko.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GeckoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
