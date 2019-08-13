#!/bin/bash
ENVOY_CONFIG=${ENVOY_CONFIG:-/etc/envoy/envoy.yaml}
exec /usr/sbin/envoy -c "$ENVOY_CONFIG" --restart-epoch "$RESTART_EPOCH"
