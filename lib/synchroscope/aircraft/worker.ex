defmodule Synchroscope.Aircraft.Worker do
  require Logger

  def start_link(server) do 
    Task.start_link(fn -> run(server) end)
  end

  def run(server) do
    client = server
    |> Synchroscope.Hanger.server
    |> accept

    spawn_link(fn -> 
      loop(client)
      Synchroscope.Hanger.remove(client)
    end)

    run(server)
  end

  defp accept (server) do 
    with client <- Socket.Web.accept!(server),
      :ok <- Socket.Web.accept!(client)
    do
      Synchroscope.Hanger.accept(client)
    else
      e -> Logger.error("accept error: #{inspect e}")
    end
  end

  defp loop (client) do 
    case socket_message(client) do 
      {:ok, data} -> 
         Logger.info "message receive: #{inspect data}"
         message_send(client, {:ok, data})

         loop(client)
      {:error, n} -> Logger.error "finish: #{inspect n}"
    end
  end

  defp socket_message(client) do 
    case Socket.Web.recv! client do
      {:text, data} -> {:ok, data}
      {:error, reason} -> {:error, reason}
      n -> {:error, n}
    end
  end

  defp message_send(client, {:ok, data}) do
    Synchroscope.Hanger.broadcast(client, data)
  end

  defp message_send(_client, {:error, reason}) do
    Logger.error "message receive error: #{inspect reason}"
  end

  defp message_send(_client, msg) do
    Logger.error "unknown: #{inspect msg}"
  end
end