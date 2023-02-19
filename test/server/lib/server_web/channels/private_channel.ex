defmodule ServerWeb.PrivateChannel do
  use ServerWeb, :channel

  alias Server.Factory

  def join("private", _payload, socket) do
    {:ok, Factory.connected_user(), socket}
  end

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
