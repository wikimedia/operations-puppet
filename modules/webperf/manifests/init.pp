# SPDX-License-Identifier: Apache-2.0
# == Class: webperf
#
# This base class provides a user, group, and working directory for
# webperf processes.
#
class webperf {
    group { 'webperf':
        ensure => present,
    }

    user { 'webperf':
        ensure     => present,
        gid        => 'webperf',
        shell      => '/bin/false',
        home       => '/nonexistent',
        system     => true,
        managehome => false,
    }

    file { '/srv/webperf':
        ensure => directory,
    }
}
