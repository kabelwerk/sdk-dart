defmodule ServerWeb.CableController do
  use ServerWeb, :controller

  action_fallback ServerWeb.FallbackController

  def get(conn, %{"id" => id}) do
    case id do
      "200" ->
        conn
        |> json(%{bool: false, int: 0, str: "", list: []})

      "204" ->
        conn
        |> send_resp(204, "")

      "400" ->
        conn
        |> put_status(400)
        |> json(%{reason: "Error!"})
    end
  end

  def post(conn, %{"file" => %Plug.Upload{} = plug_upload}) do
    conn
    |> json(%{mime_type: plug_upload.content_type, name: plug_upload.filename})
  end

  def post(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{errors: %{}})
  end
end
