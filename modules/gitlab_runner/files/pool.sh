#!/bin/sh
# SPDX-License-Identifier: Apache-2.0

set -x

enable-puppet "Puppet stopped to depool"
systemctl start gitlab-runner