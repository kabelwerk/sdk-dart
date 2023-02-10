defmodule ServerWeb.UserSocket do
  use Phoenix.Socket

  alias ServerWeb.Lumberjack

  channel "private", ServerWeb.PrivateChannel
  channel "user_inbox:*", ServerWeb.UserInboxChannel

  def connect(%{"token" => token}, socket, _connect_info) do
    socket = assign(socket, :id, System.unique_integer([:positive]))

    case token do
      "valid-token" ->
        {:ok, socket}

      "connect-then-disconnect" ->
        Lumberjack.disconnect_after(id(socket), 200)

        {:ok, socket}

      _ ->
        :error
    end
  end

  def id(socket), do: "socket:#{socket.assigns.id}"
end
