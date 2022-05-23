# SPDX-License-Identifier: Apache-2.0
# Resolves https://phabricator.wikimedia.org/T167035
# Mitigate cronspam.  This fix is backported from acct-6.6.4-3.

class toil::acct_handle_wtmp_not_rotated () {
    file { '/etc/cron.monthly/acct':
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => 'puppet:///modules/toil/acct.sh',
        require => Package['acct']
    }
}
