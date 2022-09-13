#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
cd /srv/images/production-images \
   && /srv/deployment/docker-pkg/venv/bin/docker-pkg -c /etc/production-images/config.yaml "$@" images \
   && /srv/deployment/docker-pkg/venv/bin/docker-pkg -c /etc/production-images/config-istio.yaml "$@" istio \
   && /srv/deployment/docker-pkg/venv/bin/docker-pkg -c /etc/production-images/config-cert-manager.yaml "$@" cert-manager
