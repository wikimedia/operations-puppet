#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
export PYTHONPATH=/etc/bitu/:$PYTHONPATH
export DJANGO_SETTINGS_MODULE=settings

cd /srv/idm/bitu/src/bitu || exit
/usr/bin/python3 manage.py "$@"
