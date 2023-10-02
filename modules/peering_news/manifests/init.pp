# SPDX-License-Identifier: Apache-2.0
# == Class: peering_news
#
# This class installs & manages Peering News
#
# == Parameters

# [*emailto*]
#   Peering News emails recipient.
#
# [*proxy*]
#   Proxy to reach the Internet. In URL format.
#
# [*config*]
#   Path to API-KEY.
#
class peering_news(
    Stdlib::Email              $emailto = "root@${facts['networking']['fqdn']}",
    Optional[Stdlib::Unixpath] $config  = undef,
    Optional[Stdlib::HTTPUrl]  $proxy   = undef,
) {
    file { '/usr/local/sbin/pnews':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/peering_news/pnews.py',
    }
    $config_cmd = $config.then |$x| { "--config ${x}" }
    $proxy_cmd = $proxy.then |$x| { "--proxy ${x}" }
    $command = "/bin/bash -c '/usr/local/sbin/pnews ${config_cmd} ${proxy_cmd} | mail -a \"Auto-Submitted: auto-generated\" -E -s \"Peering News\" ${emailto}'"
    systemd::timer::job {'peering_news':
        user        => 'root',
        description => 'Weekly Peering News in your inbox',
        splay       => 3600,
        command     => $command,
        interval    => [{'start' => 'OnCalendar', 'interval' => 'Mon *-*-* 09:00:00'},
                        {'start' => 'OnBootSec', 'interval' => '1min'}],
    }
}
