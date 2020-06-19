#!/bin/bash

docker run -it -p 3000:3000 \
  -v $(pwd)/provisioning:/etc/grafana/provisioning \
  -e GF_PATHS_PROVISIONING=/etc/grafana/provisioning \
  grafana/grafana
