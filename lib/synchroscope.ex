
defmodule Synchroscope do
  use Application
  require Logger

  # EP
  def start(_type, _args) do
    Synchroscope.Supervisor.start_link()
  end

  def start(_opts \\ []) do 
    Synchroscope.Supervisor.start_link()
  end
end
