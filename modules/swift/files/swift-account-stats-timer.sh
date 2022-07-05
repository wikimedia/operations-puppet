#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

set -e
set -u

account_file=${1:?}
account_statsd_prefix=${2:?}
statsd_host=${3:?}
statsd_port=${4:?}

. ${account_file}
/usr/local/bin/swift-account-stats --prefix ${account_statsd_prefix} --statsd-host ${statsd_host} --statsd-port ${statsd_port}
