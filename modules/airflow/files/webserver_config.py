# SPDX-License-Identifier: Apache-2.0
# NOTE: This file is managed by puppet.

"""Default configuration for the Airflow webserver"""
import os
basedir = os.path.abspath(os.path.dirname(__file__))

# Flask-WTF flag for CSRF
WTF_CSRF_ENABLED = True

# ----------------------------------------------------
# AUTHENTICATION CONFIG
# ----------------------------------------------------
# For details on how to set up each of the following authentication, see
# http://flask-appbuilder.readthedocs.io/en/latest/security.html# authentication-methods
# for details.

# Uncomment to setup Public role name, no authentication needed
# https://airflow.apache.org/docs/apache-airflow/stable/security/webserver.html#web-authentication
# NOTE: Since WMF does not yet do user authentication for Airflow, access to the web UI
# is only available via ssh tunnels.  Anyone that can access the webserver UI port has Admin access.
AUTH_ROLE_PUBLIC = 'Admin'
