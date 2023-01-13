defmodule ServerWeb.PrivateChannel do
  use ServerWeb, :channel

  def join("private", _payload, socket) do
    output = %{
      id: 1,
      key: "test_user",
      name: "Test User",
    }

    {:ok, output, socket}
  end
end
