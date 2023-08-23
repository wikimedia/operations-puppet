# SPDX-License-Identifier: Apache-2.0
# Firewall logging class when using the ferm provider
# @param log_burst configure log burst
# @param log_rate the logging rate to use
# @param separate_file if true log to a seperate file
class profile::firewall::log::ferm (
    Integer                                  $log_burst     = lookup('profile::firewall::log::log_burst'),
    Pattern[/\d+\/(second|minute|hour|day)/] $log_rate      = lookup('profile::firewall::log::log_rate'),
    Boolean                                  $separate_file = lookup('profile::firewall::log::separate_file')
) {
    class { 'ulogd': }

    # Explicitly drop pxe/dhcp packets packets so they dont hit the log
    ferm::filter_log { 'filter-bootp':
        proto => 'udp',
        daddr => '255.255.255.255',
        sport => 67,
        dport => 68,
    }

    ferm::rule { 'log-everything':
        rule => "NFLOG mod limit limit ${log_rate} limit-burst ${log_burst} nflog-prefix \"[fw-in-drop]\";",
        prio => '98',
    }

    if $separate_file {
        systemd::syslog {'ulogd':
            ensure      => present,
            owner       => 'root',
            group       => 'root',
            readable_by => 'user',
            force_stop  => true,
        }
    }

}
