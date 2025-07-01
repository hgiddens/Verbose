# syntax=docker/dockerfile:1

# Build image
FROM docker.io/hgiddens/swift-static:6.1.2 AS build
WORKDIR /workspace

COPY ./Package.swift ./Package.resolved /workspace/
RUN --mount=type=cache,target=/workspace/.spm-cache,id=spm-cache \
    swift package \
        --swift-sdk aarch64-swift-linux-musl \
        --cache-path /workspace/.spm-cache \
        --only-use-versions-from-resolved-file \
        resolve

COPY . /workspace/

RUN --mount=type=cache,target=/workspace/.build,id=build \
    --mount=type=cache,target=/workspace/.spm-cache,id=spm-cache \
    swift build \
        --swift-sdk aarch64-swift-linux-musl \
        --product Verbose --configuration release && \
    mkdir -p dist && \
    cp -r .build/release/Verbose .build/release/Verbose_Verbose.resources dist/

# Run image
FROM scratch AS release
EXPOSE 8080
COPY --from=build /workspace/dist /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/Verbose", "--hostname", "0.0.0.0", "--languages=en_NZ", "--languages=de_CH"]
