defmodule ServerWeb.UploadController do
  use ServerWeb, :controller

  action_fallback ServerWeb.FallbackController

  def create(conn, %{"room_id" => room_id, "file" => %Plug.Upload{} = _plug_upload}) do
    {room_id, ""} = Integer.parse(room_id)

    if room_id > 0 do
      conn
      |> put_status(201)
      |> json(%{})
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
