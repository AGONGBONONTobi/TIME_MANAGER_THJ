ARG ELIXIR_VERSION=1.16.3
ARG OTP_VERSION=26.2.5
ARG DEBIAN_VERSION=bookworm-20240513-slim
ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

# ============ STAGE 1 : BUILDER ============
FROM ${BUILDER_IMAGE} as builder

RUN apt-get update -y && apt-get install -y build-essential git \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

ENV MIX_ENV="prod"

# Copier les fichiers de dépendances (cache Docker)
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# Copier la config AVANT de compiler les deps
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

# Copier le code source
COPY priv priv
COPY lib lib

# Si vous avez assets/, décommentez ces 2 lignes :
# COPY assets assets
# RUN mix assets.deploy

# Compiler l'app + générer le release
RUN mix compile
RUN mix release

# ============ STAGE 2 : RUNNER ============
FROM ${RUNNER_IMAGE}

RUN apt-get update -y && \
    apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

WORKDIR "/app"
RUN chown nobody /app

ENV MIX_ENV="prod"

# Copier UNIQUEMENT le release depuis le builder
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/time_manager ./

# Ajouter l'entrypoint
COPY --chown=nobody:root entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

USER nobody

ENTRYPOINT ["/app/entrypoint.sh"]