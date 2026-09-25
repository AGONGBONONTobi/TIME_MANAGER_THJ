defmodule TimeManagerWeb.ApiSpec do
  alias OpenApiSpex.{Info, OpenApi, Paths, Components}
  alias TimeManagerWeb.Router

  @behaviour OpenApi

  def spec do
    %OpenApi{
      info: %Info{
        title: "Time Manager API",
        version: "1.0.0"
      },
      paths: Paths.from_router(Router),
      components: %Components{}
    }
  end
end
