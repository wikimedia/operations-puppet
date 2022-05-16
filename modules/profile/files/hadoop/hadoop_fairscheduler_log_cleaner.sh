#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
test -d /var/log/hadoop-yarn/fairscheduler && /usr/bin/find /var/log/hadoop-yarn/fairscheduler -type f -mtime +14 -delete