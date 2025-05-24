# cimg-node-browsers-arm
ARM64-compatible Docker image of cimg/node:browsers 

## BASE IMAGES
Browsers
https://github.com/CircleCI-Public/cimg-node/blob/main/*/browsers/

Node base image
https://github.com/CircleCI-Public/cimg-node/blob/main/*/Dockerfile

CIMG-BASE image
https://github.com/CircleCI-Public/cimg-base/blob/main/*/Dockerfile


## Build
```bash
# All in one - multistage build
cd 14.21.3
docker buildx build --platform linux/arm64 \
-t cimg-node-browsers-arm64:latest 
--load . -f Dockerfile
```