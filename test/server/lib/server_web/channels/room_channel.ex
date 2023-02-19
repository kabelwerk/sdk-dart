defmodule ServerWeb.RoomChannel do
  use ServerWeb, :channel

  alias Server.Factory

  def join("room:" <> room_id, %{} = _payload, socket) do
    {room_id, ""} = Integer.parse(room_id)

    if room_id >= 0 do
      all_messages =
        Range.new(1, room_id, 1)
        |> Enum.map(fn i -> Factory.message(room_id: room_id, id: i) end)

      initial_messages =
        all_messages
        |> Enum.reverse()
        |> Enum.slice(0, 100)
        |> Enum.reverse()

      socket =
        socket
        |> assign(:room_id, room_id)
        |> assign(:messages, all_messages)

      output = Factory.room_join(id: room_id, messages: initial_messages)

      {:ok, output, socket}
    else
      {:error, %{reason: "Unauthorized."}}
    end
  end

  def handle_in("list_messages", %{"before" => before}, socket) when is_integer(before) do
    messages =
      socket.assigns.messages
      |> Enum.take_while(fn message -> message.id < before end)
      |> Enum.reverse()
      |> Enum.slice(0, 100)
      |> Enum.reverse()

    output = Factory.messages_list(messages: messages)

    {:reply, {:ok, output}, socket}
  end

  def handle_in("move_marker", %{"message" => message_id}, socket) when is_integer(message_id) do
    cond do
      message_id > 0 ->
        marker = Factory.marker(room_id: socket.assigns.room_id, message_id: message_id)

        push(socket, "marker_moved", marker)

        {:reply, {:ok, marker}, socket}

      true ->
        {:reply, :error, socket}
    end
  end

  def handle_in("post_message", %{} = payload, socket) do
    case payload do
      %{"text" => text} when text != "" ->
        message = Factory.message(room_id: socket.assigns.room_id, text: text)

        push(socket, "message_posted", message)

        {:reply, {:ok, message}, socket}

      _ ->
        {:reply, :error, socket}
    end
  end

  def handle_in("delete_message", %{"message" => message_id}, socket)
      when is_integer(message_id) do
    messages = socket.assigns.messages

    case Enum.find(messages, fn message -> message.id == message_id end) do
      nil ->
        {:reply, :error, socket}

      %{} = message ->
        messages = Enum.reject(messages, fn message -> message.id == message_id end)
        socket = assign(socket, :messages, messages)

        push(socket, "message_deleted", message)

        {:reply, {:ok, message}, socket}
    end
  end

  def handle_in("set_attributes", %{"attributes" => attributes}, socket) do
    case attributes do
      %{"valid" => true} ->
        output = Factory.room_details(attributes: attributes)

        {:reply, {:ok, output}, socket}

      _ ->
        {:reply, :error, socket}
    end
  end
end
