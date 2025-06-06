# syntax=docker/dockerfile:1

# Build image
FROM docker.io/swift:6.1 AS build
WORKDIR /workspace

COPY ./Package.swift ./Package.resolved /workspace/
RUN --mount=type=cache,target=/workspace/.spm-cache,id=spm-cache \
    swift package \
        --cache-path /workspace/.spm-cache \
        --only-use-versions-from-resolved-file \
        resolve

COPY . /workspace/
RUN --mount=type=cache,target=/workspace/.build,id=build \
    --mount=type=cache,target=/workspace/.spm-cache,id=spm-cache \
    swift build --product Verbose --configuration release && \
    mkdir dist && \
    cp .build/release/Verbose dist/

# Run image
FROM docker.io/swift:6.1 AS release
EXPOSE 8080
COPY --from=build /workspace/dist/Verbose /usr/local/bin/Verbose
ENTRYPOINT ["/usr/local/bin/Verbose", "--hostname", "0.0.0.0"]
