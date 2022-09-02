# SPDX-License-Identifier: Apache-2.0
# == Class: webperf
#
# This base class provides a user, group, and working directory for
# webperf processes.
#
class webperf {
    systemd::sysuser { 'webperf': }

    file { '/srv/webperf':
        ensure => directory,
    }
}
