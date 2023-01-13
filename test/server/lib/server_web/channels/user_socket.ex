defmodule ServerWeb.UserSocket do
  use Phoenix.Socket

  channel "private", ServerWeb.PrivateChannel

  def connect(%{"token" => token}, socket, _connect_info) do
    case token do
      "valid-token" ->
        {:ok, socket}

      _ ->
        :error
    end
  end

  def id(_socket), do: nil
end
