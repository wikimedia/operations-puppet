# SPDX-License-Identifier: Apache-2.0
class profile::mirrors {
    include profile::mirrors::serve

    file { '/srv/mirrors':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
}
