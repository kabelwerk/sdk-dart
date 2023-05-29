defmodule ServerWeb.PrivateChannel do
  use ServerWeb, :channel

  alias Server.Factory

  def join("private", %{} = payload, socket) do
    case payload do
      %{"ensure_rooms" => ["error"]} ->
        {:error, %{reason: "Could not ensure the requested rooms."}}

      %{"ensure_rooms" => ["one", "two", "three"]} ->
        {:ok, Factory.private_join(room_ids: [1, 2, 3]), socket}

      _ ->
        {:ok, Factory.private_join(), socket}
    end
  end

  #
  # upstream events
  #

  def handle_in("update_user", %{} = payload, socket) do
    case payload do
      %{"name" => "Valid Name"} ->
        output = Factory.connected_user(name: "Valid Name")
        push(socket, "user_updated", output)

        {:reply, {:ok, output}, socket}

      _ ->
        {:reply, :error, socket}
    end
  end

  def handle_in("update_device", %{} = payload, socket) do
    case payload do
      %{"push_notifications_token" => "valid-token", "push_notifications_enabled" => true} ->
        output =
          Factory.device(
            push_notifications_token: "valid-token",
            push_notifications_enabled: true
          )

        {:reply, {:ok, output}, socket}

      _ ->
        {:reply, :error, socket}
    end
  end

  def handle_in("create_room", %{"hub" => hub_id}, socket) do
    case hub_id do
      1 ->
        output = Factory.newly_created_room()

        {:reply, {:ok, output}, socket}

      _ ->
        {:reply, :error, socket}
    end
  end
end
