defmodule ServerWeb.CableController do
  use ServerWeb, :controller

  action_fallback ServerWeb.FallbackController

  def show(conn, %{"id" => id}) do
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
end
