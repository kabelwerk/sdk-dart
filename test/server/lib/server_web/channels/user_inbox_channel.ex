defmodule ServerWeb.UserInboxChannel do
  use ServerWeb, :channel

  alias Server.Factory

  def join("user_inbox:" <> number, _payload, socket) do
    {number, ""} = Integer.parse(number)

    if number >= 0 do
      inbox_items =
        Enum.map(
          Range.new(1, number, 1),
          fn i ->
            Factory.inbox_item(
              room_id: i,
              message: if(rem(i, 2) != 0, do: Factory.message(), else: nil)
            )
          end
        )

      Process.send_after(self(), {:after_join, number}, 200)

      {:ok, assign(socket, :inbox_items, inbox_items)}
    else
      {:error, %{reason: "Unauthorized."}}
    end
  end

  def handle_in("list_rooms", %{} = payload, socket) do
    offset = Map.get(payload, "offset", 0)
    limit = Map.get(payload, "limit", 10)

    slice = Enum.slice(socket.assigns.inbox_items, offset, limit)
    output = %{items: slice}

    {:reply, {:ok, output}, socket}
  end

  def handle_info({:after_join, number}, socket) do
    if number == 41 do
      push(socket, "inbox_updated", Factory.inbox_item(room_id: 42))
    end

    {:noreply, socket}
  end
end
