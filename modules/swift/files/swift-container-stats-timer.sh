#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

set -e
set -u

account_file=${1:?}
statsd_prefix=${2:?}
statsd_host=${3:?}
statsd_port=${4:?}
container_set=${5:?}

. "${account_file}"
/usr/local/bin/swift-container-stats --prefix "${statsd_prefix}" --statsd-host "${statsd_host}" --statsd-port "${statsd_port}" --ignore-unknown --container-set "${container_set}"
