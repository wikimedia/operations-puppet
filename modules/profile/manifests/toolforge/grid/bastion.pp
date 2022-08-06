# @summary grid-specific bastion stuff
# SPDX-License-Identifier: Apache-2.0
class profile::toolforge::grid::bastion (
    Stdlib::Host $active_cronrunner = lookup('profile::toolforge::active_cronrunner'),
) {
    include profile::toolforge::grid::exec_environ

    file { '/etc/toollabs-cronhost':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => $active_cronrunner,
    }

    file { '/usr/local/bin/crontab':
        ensure  => 'link',
        target  => '/usr/bin/oge-crontab',
        require => Package['misctools'],
    }

    file { '/usr/local/bin/qstat-full':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0655',
        source => 'puppet:///modules/profile/toolforge/qstat-full',
    }

    # TODO: why is this not in ::submithost?
    file { "${profile::toolforge::grid::base::store}/submithost-${facts['fqdn']}":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File[$profile::toolforge::grid::base::store],
        content => "${::ipaddress}\n",
    }
}
