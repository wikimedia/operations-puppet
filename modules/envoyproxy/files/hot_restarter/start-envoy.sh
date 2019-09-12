#!/bin/bash
ENVOY_CONFIG=${ENVOY_CONFIG:-/etc/envoy/envoy.yaml}
exec /usr/bin/envoy -c "$ENVOY_CONFIG" --restart-epoch "$RESTART_EPOCH" --service-zone "$SERVICE_ZONE" --service-cluster "$SERVICE_CULSTER" --service-node "$SERVICE_NODE"
