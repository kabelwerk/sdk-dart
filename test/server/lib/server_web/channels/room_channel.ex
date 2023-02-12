defmodule ServerWeb.RoomChannel do
  use ServerWeb, :channel

  alias Server.Factory

  def join("room:" <> room_id, %{} = payload, socket) do
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
end
