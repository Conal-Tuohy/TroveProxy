#!/bin/sh
docker exec -it $(docker ps | grep trove-proxy | cut -d ' ' -f 1) bash

