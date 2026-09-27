FROM hexpm/elixir:1.15.8-erlang-25.3.2.21-debian-bookworm-20260918 AS build

RUN apt-get update && \
    apt-get install -y build-essential git && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV MIX_ENV=prod

RUN mix local.hex --force && \
    mix local.rebar --force

COPY mix.exs mix.lock ./

RUN mix deps.get --only prod
RUN mix deps.compile

COPY config config
COPY lib lib
COPY priv priv
COPY assets assets

RUN mix compile
RUN mix assets.deploy
RUN mix release


FROM debian:bookworm-slim AS app

RUN apt-get update && \
    apt-get install -y openssl libstdc++6 ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV MIX_ENV=prod
ENV PHX_SERVER=true

COPY --from=build /app/_build/prod/rel/time_manager ./

EXPOSE 4000

CMD ["bin/time_manager", "start"]