defmodule ServerWeb.RoomChannel do
  use ServerWeb, :channel

  alias Server.Factory

  def join("room:" <> room_id, %{} = _payload, socket) do
    {room_id, ""} = Integer.parse(room_id)

    if room_id >= 0 do
      messages = Enum.map(Range.new(1, room_id, 1), fn i -> Factory.message(id: i) end)

      output = %{
        attributes: %{},
        id: room_id,
        messages: messages,
        user: Factory.user()
      }

      {:ok, output, socket}
    else
      {:error, %{reason: "Unauthorized."}}
    end
  end

  def handle_in("post_message", %{} = payload, socket) do
    case payload do
      %{"text" => text} when text != "" ->
        message = Factory.message(text: text)

        push(socket, "message_posted", message)

        {:reply, {:ok, message}, socket}

      _ ->
        {:reply, :error, socket}
    end
  end

  def handle_in("set_attributes", %{"attributes" => attributes}, socket) do
    case attributes do
      %{"valid" => true} ->
        output = %{
          attributes: attributes
        }

        {:reply, {:ok, output}, socket}

      _ ->
        {:reply, :error, socket}
    end
  end
end
