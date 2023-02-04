defmodule ServerWeb.UserInboxChannel do
  use ServerWeb, :channel

  def join("user_inbox:" <> user_id, _payload, socket) do
    case user_id do
      "1" ->
        {:ok, socket}

      _ ->
        {:error, %{reason: "Unauthorized."}}
    end
  end

  def handle_in("list_rooms", %{} = payload, socket) do
    output = %{items: []}

    {:reply, {:ok, output}, socket}
  end
end
