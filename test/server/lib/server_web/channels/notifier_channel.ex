defmodule ServerWeb.NotifierChannel do
  use ServerWeb, :channel

  alias Server.Factory

  def join("notifier:" <> user_id, %{} = payload, socket) do
    {user_id, ""} = Integer.parse(user_id)

    if user_id >= 0 do
      {:ok, join_output(user_id, payload), socket}
    else
      {:error, %{reason: "Unauthorized."}}
    end
  end

  # re-join
  defp join_output(user_id, %{"after" => after_message_id}) do
    messages =
      if rem(user_id, 2) == 0 do
        []
      else
        generate_messages(user_id, after_message_id)
      end

    Factory.notifier_join(messages: messages)
  end

  # initial join
  defp join_output(user_id, %{}) do
    Factory.notifier_join(messages: generate_messages(user_id))
  end

  defp generate_messages(num_messages, after_message_id \\ 0) do
    Range.new(1 + after_message_id, num_messages + after_message_id, 1)
    |> Enum.map(fn i -> Factory.message(id: i) end)
  end
end
