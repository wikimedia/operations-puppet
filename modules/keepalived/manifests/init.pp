# SPDX-License-Identifier: Apache-2.0
# @summary Manages a Keepalived installation
# @param config Keepalived config file
class keepalived(
    String[1] $config,
) {
    package { 'keepalived':
        ensure => present,
    }

    $conf_file = '/etc/keepalived/keepalived.conf'
    file { $conf_file :
        ensure    => present,
        mode      => '0444',
        content   => $config,
        show_diff => false,
        require   => Package['keepalived'],
    }

    service { 'keepalived':
        ensure    => running,
        subscribe => [
            Package['keepalived'],
            File[$conf_file],
        ],
    }
}
