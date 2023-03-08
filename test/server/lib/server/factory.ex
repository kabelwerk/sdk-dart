defmodule Server.Factory do
  alias ServerWeb.Endpoint

  #
  # base objects
  #

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

  #
  # private channel
  #

  @doc """
  Generate a payload for an update_user response or an user_updated event.
  """
  def connected_user(opts \\ []) do
    Map.merge(user(opts), %{
      hub_id: nil,
      inserted_at: timestamp(),
      updated_at: timestamp()
    })
  end

  @doc """
  Generate a payload for an update_device response.
  """
  def device(opts \\ []) do
    %{
      id: 1,
      inserted_at: timestamp(),
      push_notifications_token: Keyword.get(opts, :push_notifications_token, "valid-token"),
      push_notifications_enabled: Keyword.get(opts, :push_notifications_enabled, true),
      updated_at: timestamp()
    }
  end

  @doc """
  Generate a payload for a create_room response.
  """
  def newly_created_room() do
    %{
      id: 1,
      hub_id: 1,
      user_id: 1
    }
  end

  @doc """
  Generate a payload for a private channel join response.
  """
  def private_join(opts \\ []) do
    %{
      room_ids: Keyword.get(opts, :room_ids, []),
      user: Keyword.get(opts, :user, connected_user())
    }
  end

  #
  # room channel
  #

  @doc """
  Generate a payload for a post_message or a delete_message response — or a
  message_posted or a message_deleted event.
  """
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

  @doc """
  Generate a payload for a post_upload response.
  """
  def upload(opts \\ []) do
    %{
      id: 1,
      mime_type: Keyword.get(opts, :mime_type, "image/png"),
      name: Keyword.get(opts, :name, "image.png"),
      original: %{
        height: Keyword.get(opts, :original_height, 512),
        url: Endpoint.url() <> "/media/uploads/original",
        width: Keyword.get(opts, :original_width, 512)
      },
      preview: %{
        height: Keyword.get(opts, :preview_height, 256),
        url: Endpoint.url() <> "/media/uploads/preview",
        width: Keyword.get(opts, :preview_width, 256)
      }
    }
  end

  @doc """
  Generate a payload for a move_marker response or a marker_moved event.
  """
  def marker(opts \\ []) do
    %{
      message_id: Keyword.get(opts, :message_id, 1),
      room_id: Keyword.get(opts, :room_id, 1),
      updated_at: timestamp(),
      user_id: Keyword.get(opts, :user_id, 1)
    }
  end

  @doc """
  Generate a payload for a list_messages response.
  """
  def messages_list(opts \\ []) do
    %{
      messages: Keyword.get(opts, :messages, [])
    }
  end

  @doc """
  Generate a payload for a set_attributes response.
  """
  def room_details(opts \\ []) do
    %{
      attributes: Keyword.get(opts, :attributes, %{}),
      id: Keyword.get(opts, :id, 1),
      user: user()
    }
  end

  @doc """
  Generate a payload for a room channel join response.
  """
  def room_join(opts \\ []) do
    Map.merge(room_details(opts), %{
      markers: Keyword.get(opts, :markers, [nil, nil]),
      messages: Keyword.get(opts, :messages, [])
    })
  end

  #
  # inbox channel
  #

  @doc """
  Generate a payload for an inbox_updated event.
  """
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

  @doc """
  Generate a payload for a list_rooms response.
  """
  def inbox_items_list(opts \\ []) do
    %{
      items: Keyword.get(opts, :items, [])
    }
  end

  #
  # notifier channel
  #

  @doc """
  Generate a payload for a notifier channel join response.
  """
  def notifier_join(opts \\ []) do
    %{
      messages: Keyword.get(opts, :messages, [])
    }
  end

  @doc """
  Generate a payload for a message_posted event on the notifier channel.
  """
  def notifier_message(opts \\ []) do
    %{
      message: message(opts)
    }
  end
end
