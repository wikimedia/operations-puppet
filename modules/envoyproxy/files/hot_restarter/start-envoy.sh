#!/bin/bash
ENVOY_CONFIG=${ENVOY_CONFIG:-/etc/envoy/envoy.yaml}
exec /usr/bin/envoy -c "$ENVOY_CONFIG" --restart-epoch "$RESTART_EPOCH"
