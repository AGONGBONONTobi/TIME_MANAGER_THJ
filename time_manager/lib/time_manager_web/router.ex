defmodule TimeManagerWeb.Router do
  use TimeManagerWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
    plug(:fetch_session)
    plug OpenApiSpex.Plug.PutApiSpec, module: TimeManagerWeb.ApiSpec
  end

  pipeline :require_auth do
    plug TimeManagerWeb.Plugs.RequireAuth
  end

  pipeline :require_csrf do
    plug TimeManagerWeb.Plugs.ValidateCsrf
  end

  scope "/api", TimeManagerWeb do
    pipe_through(:api)

    scope "/auth" do
      post "/sign_up", AuthController, :sign_up
      post "/sign_in", AuthController, :sign_in
    end

    scope "/auth" do
      pipe_through [:require_auth, :require_csrf]
      post "/sign_out", AuthController, :sign_out
    end

    scope "/users" do
      pipe_through [:require_auth]

      get("/", UserController, :index)
      post("/", UserController, :create)
      get("/:userID", UserController, :show)
      put("/:userID", UserController, :update)
      delete("/:userID", UserController, :delete)
    end

    scope "/workingtime" do
      pipe_through [:require_auth]

      get("/:userID", WorkingTimeController, :index)
      get("/:userID/:id", WorkingTimeController, :show)
      post("/:userID", WorkingTimeController, :create)
      put("/:id", WorkingTimeController, :update)
      delete("/:id", WorkingTimeController, :delete)
    end

    scope "/clocks" do
      pipe_through [:require_auth]

      get("/:userID", ClockController, :index)
      post("/:userID", ClockController, :create)
    end
  end

  scope "/" do
    pipe_through :api

    get "/api/openapi", OpenApiSpex.Plug.RenderSpec, []

    forward "/swagger", OpenApiSpex.Plug.SwaggerUI,
      path: "/api/openapi"
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
