defmodule ServerWeb.UploadController do
  use ServerWeb, :controller

  alias Server.Factory

  action_fallback ServerWeb.FallbackController

  def create(conn, %{"room_id" => room_id, "file" => %Plug.Upload{} = plug_upload}) do
    {room_id, ""} = Integer.parse(room_id)

    if room_id > 0 do
      upload = Factory.upload(mime_type: plug_upload.content_type, name: plug_upload.filename)

      conn
      |> put_status(201)
      |> json(upload)
    else
      conn
      |> put_status(400)
      |> json(%{errors: %{}})
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{errors: %{}})
  end
end
