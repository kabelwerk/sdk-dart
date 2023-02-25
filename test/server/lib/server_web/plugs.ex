defmodule ServerWeb.Plugs do
  import Plug.Conn

  def authenticate(conn, _opts) do
    case get_req_header(conn, "kabelwerk-token") do
      ["valid-token"] ->
        conn

      _ ->
        conn
        |> send_resp(401, "")
        |> halt()
    end
  end
end
