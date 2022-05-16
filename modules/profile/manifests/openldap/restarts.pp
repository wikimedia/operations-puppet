# == Class profile::openldap::restarts
# SPDX-License-Identifier: Apache-2.0
#
# This profile installs a script and a systemd timer in order to restart
# slapd once it consumes 50% of available memory. This is due to a memory
# leak in slapd.
#
# See: T130593
#
class profile::openldap::restarts()
{
    file { '/usr/local/sbin/restart_openldap':
        source => 'puppet:///modules/ldap/restart_openldap',
        mode   => '0554',
        owner  => 'root',
        group  => 'root',
    }

    $minutes = fqdn_rand(60, $title)
    systemd::timer::job { 'restart_slapd':
        ensure      => 'present',
        user        => 'root',
        description => 'Restart slapd when using more than 50% of memory',
        command     => '/usr/local/sbin/restart_openldap',
        interval    => {'start' => 'OnCalendar', 'interval' => "*-*-* *:0/${minutes}:00"},
    }

    cron { 'restart_slapd':
        ensure => 'absent',
    }
}
