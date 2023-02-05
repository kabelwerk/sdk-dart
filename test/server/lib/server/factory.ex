defmodule Server.Factory do
  def timestamp() do
    DateTime.utc_now() |> DateTime.truncate(:second)
  end

  def hub() do
    %{
      id: 1,
      name: "Test Hub",
      slug: "test_hub"
    }
  end

  def user(opts \\ []) do
    %{
      id: 1,
      key: "test_user",
      name: opts[:name] || "Test User"
    }
  end

  def connected_user(opts \\ []) do
    Map.merge(user(opts), %{
      hub_id: nil,
      inserted_at: timestamp(),
      updated_at: timestamp()
    })
  end

  def device(opts \\ []) do
    %{
      id: 1,
      inserted_at: timestamp(),
      push_notifications_token: opts[:push_notifications_token] || "valid-token",
      push_notifications_enabled: opts[:push_notifications_enabled] || true,
      updated_at: timestamp()
    }
  end

  def message() do
    %{
      html: "<p>hello!</p>",
      id: 1,
      inserted_at: timestamp(),
      room_id: 1,
      text: "hello!",
      type: :text,
      updated_at: timestamp(),
      upload: nil,
      user: user()
    }
  end

  def inbox_item() do
    %{
      marked_by: [1, 2],
      message: message(),
      room: %{
        hub: hub(),
        id: 1
      }
    }
  end
end
