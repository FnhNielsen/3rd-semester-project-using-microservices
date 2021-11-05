FROM alpine:3.13

# Install curl, jq and semver tool
# https://github.com/fsaintjacques/semver-tool
RUN apk --no-cache add curl jq wget && \
    wget -O /usr/local/bin/semver https://raw.githubusercontent.com/fsaintjacques/semver-tool/master/src/semver && \
    chmod +x /usr/local/bin/semver && \
    apk --no-cache del wget
