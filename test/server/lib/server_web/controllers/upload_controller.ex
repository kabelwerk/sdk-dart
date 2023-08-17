defmodule ServerWeb.UploadController do
  use ServerWeb, :controller

  alias Server.Factory

  action_fallback ServerWeb.FallbackController

  @supported_mime_types ["application/pdf", "image/jpeg", "image/png"]

  def create(conn, %{"file" => %Plug.Upload{} = plug_upload}) do
    if Enum.member?(@supported_mime_types, plug_upload.content_type) do
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
