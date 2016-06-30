defmodule Synchroscope.Hanger do
  use GenServer
  require Logger

  @port Application.get_env(:synchroscope, :port)

  def start_link(state \\ []) do 
      GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(_opt) do 
    socket = Socket.Web.listen! @port
    state = %{server: socket, clients: []}

    {:ok, state}
  end

  def server(_state) do 
    GenServer.call(__MODULE__, :server)
  end

  def clients() do 
    GenServer.call(__MODULE__, :clients)
  end

  def accept(client) do 
    GenServer.cast(__MODULE__, {:accept, client})
    client
  end

  def remove(client) do 
    GenServer.cast(__MODULE__, {:remove, client})
  end

  def broadcast(sender, data) do 
    clients()
    |> Enum.filter_map(fn cl -> sender.key != cl.key end, &(Socket.Web.send!(&1, {:text, data})))
  end

  def handle_cast({:accept, client}, state) do 
    new_clients = [client | state.clients]
    {:noreply, %{state | clients: new_clients}}
  end

  def handle_cast({:remove, client}, state) do 
    new_clients = 
      Enum.filter(state.clients, fn cl -> client.key != cl.key end)
    {:noreply, %{state | clients: new_clients}}
  end

  def handle_call(:server, _sender, state) do 
    {:reply, state.server, state}
  end

  def handle_call(:clients, _sender, state) do 
    {:reply, state.clients, state}
  end

  def terminate(reason, _state) do
    Logger.info "hanger teminate: #{inspect reason}"
  end
end
