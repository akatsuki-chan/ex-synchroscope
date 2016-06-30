defmodule Synchroscope.Aircraft.Supervisor do
  use Supervisor

  @supervisor_name Synchroscope.Aircraft.Supervisor

  def start_link(_state \\ []) do 
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do 
    children = [
      worker(Synchroscope.Aircraft.Worker, [@supervisor_name])
    ]
    supervise(children, strategy: :one_for_one)
  end
end