#!/bin/bash
# shortcut to clean stale (stopped) docker containers

docker rm -v $(docker ps -a -q -f status=exited)
