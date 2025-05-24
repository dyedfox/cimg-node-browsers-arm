# cimg-node-browsers-arm
ARM64-compatible Docker image of cimg/node:browsers 

## BASE IMAGES

Browsers
https://github.com/CircleCI-Public/cimg-node/tree/main/14.21/browsers

Node base image
https://github.com/CircleCI-Public/cimg-node/tree/main/14.21

CIMG-BASE image
https://github.com/CircleCI-Public/cimg-base


## Build
```bash
# All in one - multistage build
cd 14.21.3
docker buildx build --platform linux/arm64 \
-t cimg-node-browsers-arm64:latest 
--load . -f Dockerfile
```