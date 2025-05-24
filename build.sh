#!/bin/bash

docker buildx build \
  --platform linux/arm64 \
  -t cimg-base-arm64:latest \
  --load . -f Dockerfile.base

docker buildx build \
  --platform linux/arm64 \
  -t cimg-node-arm64:latest \
  --load . -f Dockerfile.node

docker buildx build \
--platform linux/arm64 \
-t cimg-node-browsers-arm64:latest \
--load . -f Dockerfile.browsers

# All in one - multistage build
docker buildx build \
--platform linux/arm64 \
-t cimg-node-browsers-arm64:latest \
--load . -f Dockerfile