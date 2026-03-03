#!/bin/sh
set -e

cd "$(dirname "$0")"

TAG=$(git rev-parse --short HEAD)
IMAGE=onyxblade/didcomm-rails-demo-web

docker build -t "$IMAGE:latest" -t "$IMAGE:$TAG" web
docker push "$IMAGE:latest"
docker push "$IMAGE:$TAG"
