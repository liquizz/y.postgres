FROM postgres:17

ARG INSTALL_PLRUST=false
ARG INSTALL_CRON=false
ARG INSTALL_HTTP=false
ARG INSTALL_JWT=false

ENV INSTALL_PLRUST=${INSTALL_PLRUST}
ENV INSTALL_CRON=${INSTALL_CRON}
ENV INSTALL_HTTP=${INSTALL_HTTP}
ENV INSTALL_JWT=${INSTALL_JWT}

USER root

# Base dependencies required for some installations
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates wget \
    && rm -rf /var/lib/apt/lists/*

# Install cron if enabled
RUN if [ "$INSTALL_CRON" = "true" ]; then \
    apt-get update && \
    apt-get install -y --no-install-recommends postgresql-15-cron && \
    rm -rf /var/lib/apt/lists/*; \
  fi

# Install http if enabled
RUN if [ "$INSTALL_HTTP" = "true" ]; then \
    apt-get update && \
    apt-get install -y --no-install-recommends postgresql-15-http && \
    rm -rf /var/lib/apt/lists/*; \
  fi

# Install JWT if enabled
RUN if [ "$INSTALL_JWT" = "true" ]; then \
    apt-get update && \
    apt-get install -y --no-install-recommends git make gcc pkg-config libssl-dev && \
    cd /tmp && \
    git clone https://github.com/michelp/pgjwt.git && \
    cd pgjwt && \
    make install && \
    cd / && \
    rm -rf /tmp/pgjwt && \
    apt-get remove -y git make gcc pkg-config libssl-dev && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*; \
  fi

USER postgres

USER root

# Copy initialization scripts
# ADD ./src /docker-entrypoint-initdb.d
# RUN chmod 755 /docker-entrypoint-initdb.d
# RUN chmod 644 /docker-entrypoint-initdb.d/*.sql

ADD ./postgresql.conf /etc/postgresql/postgresql.conf
RUN chown 999:999 /etc/postgresql/postgresql.conf && \
    chmod 644 /etc/postgresql/postgresql.conf

# ADD ./pg_hba.conf /etc/postgresql/pg_hba.conf
# RUN chown 999:999 /etc/postgresql/pg_hba.conf && \
#     chmod 644 /etc/postgresql/pg_hba.conf

# ADD ./plugin/plrust/allowed-dependencies.toml /etc/postgresql/allowed-dependencies.toml
# RUN chown 999:999 /etc/postgresql/allowed-dependencies.toml && \
#     chmod 644 /etc/postgresql/allowed-dependencies.toml

# Conditionally modify shared_preload_libraries based on INSTALL_CRON and INSTALL_PLRUST
# RUN if [ "$INSTALL_CRON" = "true" ] || [ "$INSTALL_PLRUST" = "true" ]; then \
#     CONFIG_FILE=/etc/postgresql/postgresql.conf && \
#     extensions="" && \
#     [ "$INSTALL_CRON" = "true" ] && extensions="$extensions pg_cron" && \
#     [ "$INSTALL_PLRUST" = "true" ] && extensions="$extensions plrust" && \
#     extensions=$(echo $extensions | xargs | sed 's/ /,/g') && \
#     if grep -q "^[^#]*shared_preload_libraries" "$CONFIG_FILE"; then \
#       current=$(grep "^[^#]*shared_preload_libraries" "$CONFIG_FILE" | sed -E "s/shared_preload_libraries\s*=\s*'([^']*)'.*/\1/") && \
#       new_libraries="$current" && \
#       # Iterate over each extension
#       for ext in $(echo "$extensions" | tr ',' ' '); do \
#         # Check if ext is already in current
#         echo "$current" | grep -wq "$ext" || { \
#           if [ -z "$new_libraries" ]; then \
#             new_libraries="$ext"; \
#           else \
#             new_libraries="$new_libraries,$ext"; \
#           fi; \
#         } \
#       done && \
#       sed -i "s/^[^#]*shared_preload_libraries\s*=.*/shared_preload_libraries = '${new_libraries}'/" "$CONFIG_FILE"; \
#     else \
#       if grep -q "^#.*shared_preload_libraries" "$CONFIG_FILE"; then \
#         sed -i "s/^#.*shared_preload_libraries\s*=.*/shared_preload_libraries = '${extensions}'/" "$CONFIG_FILE"; \
#       else \
#         echo "shared_preload_libraries = '${extensions}'" >> "$CONFIG_FILE"; \
#       fi; \
#     fi; \
#   fi

EXPOSE 5432
