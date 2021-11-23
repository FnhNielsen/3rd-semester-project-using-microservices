FROM docker:20.10

# Install curl, jq, bash, Docker registry v2 and semver tool
# Docker registry v2: https://gitlab.com/gitlab-org/gitlab-foss/-/issues/40096
# Semver tool: https://github.com/fsaintjacques/semver-tool
RUN apk --no-cache add curl jq bash && \
    curl -fSL "https://github.com/genuinetools/reg/releases/download/v0.13.0/reg-linux-amd64" -o "/usr/local/bin/reg" && \
    if [ "$(echo "d6096b30d8b0eefe3ba57895769ca5bfdade5c7105dc5995e3029e8d70877e06 /usr/local/bin/reg" | sha256sum -c -)" == "/usr/local/bin/reg: OK" ]; then echo "ERROR: reg has wrong check sum"; exit 1; fi && \
    chmod a+x "/usr/local/bin/reg" &&  \
    curl -fSL "https://raw.githubusercontent.com/fsaintjacques/semver-tool/master/src/semver" -o "/usr/local/bin/semver" && \
    if [ "$(echo "d5055fc17cf00a1d56107746a991ba0b6ef817fcfc063459c1eacedbb277bbd5  /usr/local/bin/semver" | sha256sum -c -)" == "/usr/local/bin/reg: OK" ]; then echo "ERROR: semver has wrong check sum"; exit 1; fi && \
    chmod a+x "/usr/local/bin/semver"

# Setup CI CD tool
COPY "../../scripts/lib" "/usr/local/lib/ci_cd_lib"
COPY "../../scripts/ci_cd_tool" "/usr/local/bin/ci_cd_tool"
COPY "../../scripts/certs_check" "/usr/local/bin/certs_check"

RUN chmod a+x "/usr/local/bin/ci_cd_tool" && chmod a+x "/usr/local/bin/certs_check"

ENTRYPOINT ["certs_check"]