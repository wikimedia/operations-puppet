#!/bin/bash

SSH_AUTH_SOCK=/run/keyholder/proxy.sock PATH="/srv/deployment/homer/venv/bin:${PATH}" exec homer "${@}"
