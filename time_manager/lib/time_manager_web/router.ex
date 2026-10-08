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

  pipeline :require_user_access do
    plug TimeManagerWeb.Plugs.RequireUserAccess
  end

  pipeline :require_manager do
    plug TimeManagerWeb.Plugs.RequireRole, roles: ["manager", "admin"]
  end

  pipeline :require_admin do
    plug TimeManagerWeb.Plugs.RequireRole, roles: ["admin"]
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

    scope "/auth" do
      pipe_through [:require_auth]
      get "/me", AuthController, :me
    end

    scope "/users" do
      pipe_through [:require_auth]

      get("/", UserController, :index)
      post("/", UserController, :create)
      get("/:userID", UserController, :show)
      put("/:userID", UserController, :update)
      delete("/:userID", UserController, :delete)
    end

    scope "/users" do
      pipe_through [:require_auth, :require_admin]

      patch("/:userID/role", UserController, :update_role)
    end

    scope "/manager" do
      pipe_through [:require_auth, :require_manager]

      get("/team", ManagerController, :team)
      post("/users/:userID/reminders", ManagerController, :remind)
      post("/teams/:team_id/clock", ManagerController, :team_clock)
      get("/users/:userID/payroll", ManagerController, :payroll_summary)
    end

    scope "/bat-signal" do
      pipe_through [:require_auth]

      get "/status", BatSignalController, :status
    end

    scope "/bat-signal" do
      pipe_through [:require_auth, :require_admin]

      post "/trigger", BatSignalController, :trigger
      delete "/trigger", BatSignalController, :clear
    end

    scope "/notifications" do
      pipe_through [:require_auth]

      get "/", NotificationController, :index
      patch "/:id/read", NotificationController, :read
    end

    scope "/teams" do
      pipe_through [:require_auth, :require_manager]

      get "/", TeamController, :index
      get "/:id", TeamController, :show
      get "/:team_id/tasks", TeamTaskController, :index
      post "/:team_id/tasks", TeamTaskController, :create
      patch "/:team_id/tasks/:id/status", TeamTaskController, :update_status
      post "/:id/members/:user_id", TeamController, :add_member
      delete "/:id/members/:user_id", TeamController, :remove_member
    end

    scope "/teams" do
      pipe_through [:require_auth, :require_admin]

      post "/", TeamController, :create
      put "/:id", TeamController, :update
      delete "/:id", TeamController, :delete
    end

    scope "/leave-requests" do
      pipe_through [:require_auth]

      get "/", LeaveRequestController, :index
      post "/", LeaveRequestController, :create
    end

    scope "/leave-requests" do
      pipe_through [:require_auth, :require_manager]

      post "/:id/approve", LeaveRequestController, :approve
      post "/:id/reject", LeaveRequestController, :reject
    end

    scope "/payroll-rules" do
      pipe_through [:require_auth, :require_admin]

      get "/", PayrollRuleController, :index
      post "/", PayrollRuleController, :create
      put "/:id", PayrollRuleController, :update
      delete "/:id", PayrollRuleController, :delete
    end

    scope "/work-policies" do
      pipe_through [:require_auth, :require_admin]

      get "/", WorkPolicyController, :index
      post "/", WorkPolicyController, :create
      put "/:id", WorkPolicyController, :update
      post "/assignments", WorkPolicyController, :assign
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

    scope "/clock-corrections" do
      pipe_through [:require_auth]

      get "/", ClockCorrectionController, :index
      post "/", ClockCorrectionController, :create
    end

    scope "/clock-corrections" do
      pipe_through [:require_auth, :require_manager]

      get "/pending", ClockCorrectionController, :index_for_manager
      post "/:id/approve", ClockCorrectionController, :approve
      post "/:id/reject", ClockCorrectionController, :reject
    end

    scope "/users/:userID" do
      pipe_through [:require_auth, :require_user_access]

      get "/work-policy", WorkPolicyController, :show_for_user
      get "/clocks", ClockController, :index
      post "/clocks", ClockController, :create
      get "/working-times", WorkingTimeController, :index
      post "/working-times", WorkingTimeController, :create
      get "/working-times/:id", WorkingTimeController, :show
      put "/working-times/:id", WorkingTimeController, :update_for_user
      delete "/working-times/:id", WorkingTimeController, :delete_for_user
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
