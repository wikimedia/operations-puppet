#!/bin/sh
# SPDX-License-Identifier: Apache-2.0

set -x

disable-puppet "Puppet stopped to depool"
systemctl stop gitlab-runner