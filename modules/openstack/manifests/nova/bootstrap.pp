class openstack::nova::bootstrap {

    file {'/etc/nova/bootstrap':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0655',
    }

    file { '/etc/nova/bootstrap/seed.sh':
        owner   => 'nova',
        group   => 'nova',
        mode    => '0544',
        content => template('openstack/bootstrap/nova/nova_seed.sh.erb'),
        require => File['/etc/nova/bootstrap'],
    }
}
