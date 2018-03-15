class openstack::neutron::bootstrap {

    file {'/etc/neutron/bootstrap':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0655',
    }

    file { '/etc/neutron/bootstrap/seed.sh':
        owner   => 'neutron',
        group   => 'neutron',
        mode    => '0544',
        content => template('openstack/bootstrap/neutron/neutron_seed.sh.erb'),
        require => File['/etc/neutron/bootstrap'],
    }
}
