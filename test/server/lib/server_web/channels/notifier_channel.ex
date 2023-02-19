defmodule ServerWeb.NotifierChannel do
  use ServerWeb, :channel

  alias Server.Factory

  def join("notifier:" <> user_id, %{} = payload, socket) do
    {user_id, ""} = Integer.parse(user_id)

    if user_id >= 0 do
      output = Factory.notifier_join(messages: messages_at_join(user_id, payload))

      Process.send_after(self(), {:after_join, user_id}, 200)

      {:ok, output, socket}
    else
      {:error, %{reason: "Unauthorized."}}
    end
  end

  # rejoin
  defp messages_at_join(user_id, %{"after" => after_message_id}) do
    if rem(user_id, 2) == 0 do
      []
    else
      Range.new(1 + after_message_id, user_id + after_message_id, 1)
      |> Enum.map(fn i -> Factory.message(id: i) end)
    end
  end

  # initial join
  defp messages_at_join(user_id, %{}) do
    Range.new(1, user_id, 1)
    |> Enum.map(fn i -> Factory.message(id: i) end)
  end

  def handle_info({:after_join, number}, socket) do
    if number == 41 do
      push(socket, "message_posted", Factory.notifier_message(id: 42))
    end

    {:noreply, socket}
  end
end
