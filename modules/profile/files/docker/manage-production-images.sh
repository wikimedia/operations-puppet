#!/bin/bash
cd /srv/images/production-images \
   && /srv/deployment/docker-pkg/venv/bin/docker-pkg -c /etc/production-images/config.yaml "$@" images \
   && /srv/deployment/docker-pkg/venv/bin/docker-pkg -c /etc/production-images/config-istio.yaml "$@" istio
