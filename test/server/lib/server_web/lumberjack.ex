defmodule ServerWeb.Lumberjack do
  @moduledoc """
  A GenServer that broadcasts loudly to sever connections.
  """
  use GenServer

  alias ServerWeb.Endpoint

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_info({:disconnect, topic}, state) do
    Endpoint.broadcast!(topic, "disconnect", %{})

    {:noreply, state}
  end

  def disconnect_after(topic, milliseconds) do
    Process.send_after(__MODULE__, {:disconnect, topic}, milliseconds)
  end
end
