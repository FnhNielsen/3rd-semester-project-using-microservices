FROM alpine:3.13

# Install jq, yq, git, bash, semver tool and kubectl
# Semver tool: https://github.com/fsaintjacques/semver-tool
RUN apk --no-cache add curl jq yq git bash && \
    curl -fSL "https://raw.githubusercontent.com/fsaintjacques/semver-tool/master/src/semver" -o "/usr/local/bin/semver" && \
    if [ "$(echo "d5055fc17cf00a1d56107746a991ba0b6ef817fcfc063459c1eacedbb277bbd5  /usr/local/bin/semver" | sha256sum -c -)" == "/usr/local/bin/reg: OK" ]; then echo "ERROR: semver has wrong check sum"; exit 1; fi && \
    chmod a+x "/usr/local/bin/semver" && \
    curl -fSL "https://storage.googleapis.com/kubernetes-release/release/v1.22.4/bin/linux/amd64/kubectl" -o "/usr/local/bin/kubectl" && \
    if [ "$(echo "21f24aa723002353eba1cc2668d0be22651f9063f444fd01626dce2b6e1c568c /usr/local/bin/kubectl" | sha256sum -c -)" == "/usr/local/bin/kubectl: OK" ]; then echo "ERROR: kubectl has wrong check sum"; exit 1; fi && \
    chmod a+x "/usr/local/bin/kubectl" && \
    apk --no-cache del curl

# Setup CI CD tool
COPY "../../scripts/lib" "/usr/local/lib/ci_cd_lib"
COPY "../../scripts/ci_cd_tool" "/usr/local/bin/ci_cd_tool"

RUN chmod a+x "/usr/local/bin/ci_cd_tool"
