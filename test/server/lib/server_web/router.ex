defmodule ServerWeb.Router do
  use ServerWeb, :router

  import ServerWeb.Plugs

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", ServerWeb do
    pipe_through [:api, :authenticate]

    get "/cables/:id", CableController, :show
    post "/rooms/:room_id/uploads", UploadController, :create
  end
end
