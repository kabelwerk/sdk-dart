defmodule ServerWeb.UploadController do
  use ServerWeb, :controller

  action_fallback ServerWeb.FallbackController

  def create(conn, %{"room_id" => _room_id, "file" => %Plug.Upload{} = _plug_upload}) do
    conn
    |> put_status(201)
    |> json(%{})
  end

  def create(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{errors: %{}})
  end
end
