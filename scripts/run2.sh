#!/bin/bash
# usage: run.sh net|nonet <cmd...>   — runs cmd in project dir at Sutherland path
NET=$1; shift
[ "$NET" = net ] && NETFLAG="--network host" || NETFLAG="--network none"
exec docker run --rm -i $NETFLAG --read-only --tmpfs /tmp:rw,size=16g \
  --user $(id -u):$(id -g) --security-opt no-new-privileges --cap-drop all \
  --ulimit nofile=65536:65536 --memory 12g \
  -v $WORK:/home/ubuntu:rw \
  -v $HOME/.elan/toolchains/leanprover--lean4---v4.33.1:/opt/lean:ro \
  -e HOME=/home/ubuntu -e PATH=/opt/lean/bin:/usr/bin:/bin \
  -e LEAN_ABORT_ON_PANIC=1 \
  -w /home/ubuntu/$SUB rhcheck-sandbox:1 bash -c "$*"
