# SPDX-License-Identifier: Apache-2.0
class cinderutils {
    file { '/usr/local/sbin/wmcs-prepare-cinder-volume':
        ensure => present,
        source => 'puppet:///modules/cinderutils/wmcs-prepare-cinder-volume.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    # compat
    file { '/usr/local/sbin/prepare_cinder_volume':
        ensure => link,
        target => '/usr/local/sbin/wmcs-prepare-cinder-volume',
    }
}
