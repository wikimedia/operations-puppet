# @summary grid-specific bastion stuff
# SPDX-License-Identifier: Apache-2.0
class profile::toolforge::grid::bastion (
    Stdlib::Host $active_cronrunner = lookup('profile::toolforge::active_cronrunner'),
) {
    include profile::toolforge::grid::exec_environ

    file { [
        '/etc/toollabs-cronhost',
        '/usr/local/bin/crontab',
        '/usr/local/bin/qstat-full',
    ]:
        ensure => absent,
    }

    file { '/etc/ssh/ssh_config':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/profile/toolforge/grid/bastion/ssh_config',
    }
}
