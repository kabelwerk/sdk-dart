defmodule ServerWeb.UserInboxChannel do
  use ServerWeb, :channel

  alias Server.Factory

  def join("user_inbox:" <> number, _payload, socket) do
    {number, ""} = Integer.parse(number)

    if number >= 0 do
      inbox_items =
        Range.new(1, number, 1)
        |> Enum.map(fn i -> Factory.inbox_item(room_id: i) end)

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
end
