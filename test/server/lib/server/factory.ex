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
      name: Keyword.get(opts, :name, "Test User")
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
      push_notifications_token: Keyword.get(opts, :push_notifications_token, "valid-token"),
      push_notifications_enabled: Keyword.get(opts, :push_notifications_enabled, true),
      updated_at: timestamp()
    }
  end

  def message(opts \\ []) do
    %{
      html: "<p>hello!</p>",
      id: Keyword.get(opts, :id, 1),
      inserted_at: timestamp(),
      room_id: Keyword.get(opts, :room_id, 1),
      text: Keyword.get(opts, :text, "hello!"),
      type: Keyword.get(opts, :type, :text),
      updated_at: timestamp(),
      upload: Keyword.get(opts, :upload, nil),
      user: user()
    }
  end

  def marker(opts \\ []) do
    %{
      message_id: Keyword.get(opts, :message_id, 1),
      room_id: Keyword.get(opts, :room_id, 1),
      updated_at: timestamp(),
      user_id: Keyword.get(opts, :user_id, 1)
    }
  end

  def inbox_item(opts \\ []) do
    %{
      marked_by: [1, 2],
      message: Keyword.get(opts, :message, message()),
      room: %{
        hub: hub(),
        id: Keyword.get(opts, :room_id, 1)
      }
    }
  end

  def room_join(opts \\ []) do
    %{
      attributes: %{},
      id: Keyword.get(opts, :id, 1),
      markers: Keyword.get(opts, :markers, [nil, nil]),
      messages: Keyword.get(opts, :messages, []),
      user: user()
    }
  end
end
