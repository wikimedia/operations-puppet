#!/bin/sh

SSH_AUTH_SOCK=/run/keyholder/proxy.sock PATH="/srv/deployment/homer/venv/bin:${PATH}" PYTHONWARNINGS="ignore::UserWarning:paramiko.transport" exec homer "${@}"
