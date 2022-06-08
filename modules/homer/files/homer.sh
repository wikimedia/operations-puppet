#!/bin/sh
# SPDX-License-Identifier: Apache-2.0

REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt SSH_AUTH_SOCK=/run/keyholder/proxy.sock PATH="/srv/deployment/homer/venv/bin:${PATH}" PYTHONWARNINGS="ignore::UserWarning:paramiko.transport" exec homer "${@}"
