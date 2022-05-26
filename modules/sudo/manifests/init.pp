# SPDX-License-Identifier: Apache-2.0
# @summary manage sudoers
# param purge_sudoers_d if true purge unmanaged resources from /etc/sudoers.d
class sudo (
    Boolean $purge_sudoers_d = false,
) {
    package { 'sudo':
        ensure => installed,
    }

    file { '/etc/sudoers':
        ensure       => present,
        mode         => '0440',
        owner        => 'root',
        group        => 'root',
        source       => 'puppet:///modules/sudo/sudoers',
        require      => Package[sudo],
        validate_cmd => '/usr/sbin/visudo -c -f %'
    }

    file {'/etc/sudoers.d':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        purge   => $purge_sudoers_d,
        recurse => $purge_sudoers_d,
    }

    file { '/etc/sudoers.d/README':
        ensure => absent,
    }
}
