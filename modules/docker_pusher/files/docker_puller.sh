#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# docker-puller is meant as a wrapper to protect credentials inside
# /etc/docker-pusher/config.json.
/usr/bin/docker --config /etc/docker-pusher pull "$@"
