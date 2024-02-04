defmodule Plaza.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      PlazaWeb.Telemetry,
      # Start the Ecto repository
      Plaza.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Plaza.PubSub},
      # Start Finch
      {Finch, name: Plaza.Finch},
      # Start the Endpoint (http/https)
      PlazaWeb.Endpoint,
      # Start the Cron Scheduler 
      Plaza.Scheduler,
      # Start the Top Products GenServer
      %{
        id: PlazaWeb.TopProducts,
        start: {
          PlazaWeb.TopProducts,
          :start_link,
          [
            %{
              first: 1,
              second: 2,
              third: 3
            }
          ]
        }
      },
      # Dynamic Task Supervisor 
      {Task.Supervisor, name: Plaza.TaskSupervisor}
      # Start a worker by calling: Plaza.Worker.start_link(arg)
      # {Plaza.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Plaza.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PlazaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
