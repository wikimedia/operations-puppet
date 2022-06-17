#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
#
# A minimal flask app to return health checks for a Galera node.
#
# This expects to run as the 'prometheus' user and will use its credentials,
#  found in /var/lib/prometheus/.my.cnf
#
# Logs are written to /var/log/nodecheck/nodecheck.log
#
from flask import Flask
import logging
from os.path import exists
import subprocess


logging.basicConfig(filename='/var/log/nodecheck/nodecheck.log',
                    encoding='utf-8', level=logging.WARNING)

# no need to log every single healthcheck request
werklog = logging.getLogger('werkzeug')
werklog.disabled = True


app = Flask(__name__)


@app.route("/")
def healthcheck():
    timeout = 10
    mysql_defaults = '/var/lib/prometheus/.my.cnf'

    if exists('/tmp/galera.disabled'):
        return "Galera node is manually disabled", 404

    if not exists(mysql_defaults):
        logging.error("failed to open /var/lib/prometheus/.my.cnf. "
                      "Returning 500")
        return "Unable to locate mysql credentials", 500

    mysql_args = ['/usr/bin/mysql',
                  '--defaults-file=%s' % mysql_defaults,
                  '-nNE',
                  '--connect-timeout=%d' % timeout]
    wsrep_args = mysql_args + ['-e', "SHOW STATUS LIKE 'wsrep_ready';"]

    logging.debug("Checking wsrep_ready with %s", wsrep_args)
    proc = subprocess.Popen(wsrep_args,
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE)
    stdout, stderr = proc.communicate()
    logging.debug("stdout=%s", stdout)
    if stderr:
        logging.warning("After wsrep check, stderr=%s", stderr)

    if stdout.rstrip().endswith('ON'.encode('utf8')):
        ro_args = mysql_args + ['-e', "SHOW GLOBAL VARIABLES LIKE 'read_only';"]
        logging.debug("Checking wsrep_ready with %s", ro_args)
        proc = subprocess.Popen(ro_args,
                                stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE)
        stdout, stderr = proc.communicate()
        logging.debug("stdout=%s", stdout)
        if stderr:
            logging.warning("After RO check, stderr=%s", stderr)

        if stdout.rstrip().endswith('ON'.encode('utf8')):
            return "Galera node is set to read-only, do not use", 503
        else:
            return "Galera node is ready", 200
    else:
        return "Galera node is not ready, do not use", 503


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=9990, debug=False)
