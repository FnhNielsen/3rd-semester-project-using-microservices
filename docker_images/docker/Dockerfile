FROM docker:20.10

# Install curl and Docker registry v2
# Docker registry v2: https://gitlab.com/gitlab-org/gitlab-foss/-/issues/40096
RUN apk --no-cache add curl && \
    curl -fSL "https://github.com/genuinetools/reg/releases/download/v0.13.0/reg-linux-amd64" -o "/usr/local/bin/reg" && \
    if [ "$(echo "d6096b30d8b0eefe3ba57895769ca5bfdade5c7105dc5995e3029e8d70877e06 /usr/local/bin/reg" | sha256sum -c -)" == "/usr/local/bin/reg: OK" ]; then echo "ERROR: reg has wrong check sum"; exit 1; fi && \
    chmod a+x "/usr/local/bin/reg"
