FROM alpine:3.13

# Install curl, jq, bash and semver tool
# Semver tool: https://github.com/fsaintjacques/semver-tool
RUN apk --no-cache add curl bash && \
    curl -fSL "https://raw.githubusercontent.com/fsaintjacques/semver-tool/master/src/semver" -o "/usr/local/bin/semver" && \
    if [ "$(echo "d5055fc17cf00a1d56107746a991ba0b6ef817fcfc063459c1eacedbb277bbd5  /usr/local/bin/semver" | sha256sum -c -)" != "/usr/local/bin/semver: OK" ]; then exit 1; fi && \
    chmod a+x "/usr/local/bin/semver" && \
    apk --no-cache del curl

# Setup CI CD tool
COPY "../../scripts/lib" "/usr/local/lib/ci_cd_lib"
COPY "../../scripts/ci_cd_tool" "/usr/local/bin/ci_cd_tool"

RUN chmod a+x "/usr/local/bin/ci_cd_tool"
