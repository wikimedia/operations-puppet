# SPDX-License-Identifier: Apache-2.0
class openstack::cinder::bootstrap {
    file {'/etc/cinder/bootstrap':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0655',
    }

    file { '/etc/cinder/bootstrap/seed.sh':
        owner   => 'cinder',
        group   => 'cinder',
        mode    => '0544',
        content => template('openstack/bootstrap/cinder/cinder_seed.sh.erb'),
        require => File['/etc/cinder/bootstrap'],
    }
}
