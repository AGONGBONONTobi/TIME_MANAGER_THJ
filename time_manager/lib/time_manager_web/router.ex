defmodule TimeManagerWeb.Router do
  use TimeManagerWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/api", TimeManagerWeb do
    pipe_through(:api)

    scope "/users" do
      get("/", UserController, :index)
      post("/", UserController, :create)
      get("/:userID", UserController, :show)
      put("/:userID", UserController, :update)
      delete("/:userID", UserController, :delete)
    end

    scope "/workingtime" do
      get("/:userID", WorkingTimeController, :index)
      get("/:userID/:id", WorkingTimeController, :show)
      post("/:userID", WorkingTimeController, :create)
      put("/:id", WorkingTimeController, :update)
      delete("/:id", WorkingTimeController, :delete)
    end
    scope "/clocks" do
      get "/:userID", ClockController, :index
      post "/:userID", ClockController, :create
     end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:time_manager, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through([:fetch_session, :protect_from_forgery])

      live_dashboard("/dashboard", metrics: TimeManagerWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end
end
