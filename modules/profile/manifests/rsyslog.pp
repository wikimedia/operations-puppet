# SPDX-License-Identifier: Apache-2.0
# @summary manage rsyslog global file
# @param source The location of the source file for rsyslog
class profile::rsyslog (
    Stdlib::Filesource $logrotate_source = lookup('profile::rsyslog::logrotate_source'),
) {
    class { 'rsyslog': }

    logrotate::conf { 'rsyslog':
        ensure => present,
        source => $logrotate_source,
    }
}
