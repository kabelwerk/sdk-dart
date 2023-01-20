defmodule ServerWeb.PrivateChannel do
  use ServerWeb, :channel

  def join("private", _payload, socket) do
    output = %{
      id: 1,
      key: "test_user",
      name: "Test User"
    }

    {:ok, output, socket}
  end

  def handle_in("update_user", %{} = payload, socket) do
    case payload do
      %{"name" => "Valid Name"} ->
        output = %{id: 1, key: "test_user", name: "Valid Name"}
        push(socket, "user_updated", output)

        {:reply, {:ok, output}, socket}

      _ ->
        {:reply, :error, socket}
    end
  end
end
