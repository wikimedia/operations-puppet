#!/bin/bash
cd /srv/images/production-images \
   && .venv/bin/python ./build -c /etc/production-images/config.yaml images
