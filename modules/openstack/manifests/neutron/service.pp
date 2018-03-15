class openstack::neutron::service(
    $version,
    ) {

    package {'neutron-server':
        ensure => 'present',
    }

    # Needed for setup and schema changes via neutron-db-manage
    file { '/etc/neutron/plugins/ml2/ml2_conf.ini':
        content => template("openstack/${version}/neutron/plugins/ml2/ml2_conf.ini.erb"),
        owner   => 'root',
        group   => 'root',
        mode    => '0744',
        require => Package['neutron-linuxbridge-agent'];
    }
}
