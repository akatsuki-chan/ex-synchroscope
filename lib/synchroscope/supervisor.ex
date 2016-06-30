defmodule Synchroscope.Supervisor do
  use Supervisor

  @backet_name Synchroscope.Hanger

  def start_link do 
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      worker(Synchroscope.Hanger, []),
      supervisor(Synchroscope.Aircraft.Supervisor, [])
    ]

    supervise(children, strategy: :one_for_one)
  end
end