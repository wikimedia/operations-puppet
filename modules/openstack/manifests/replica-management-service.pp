class openstack::replica-management-service {

    file { '/usr/local/sbin/replica-addusers.pl':
        source => 'puppet:///modules/openstack/replica-addusers.pl',
               owner  => 'root',
               group  => 'root',
               mode   => '0550',
    }

    generic::upstart_job{ 'replica-addusers':
        install => true,
        start   => false,
        require => File['/usr/local/sbin/replica-addusers.pl'],
    }

    # There is no service {} stanza on purpose -- this service
    # must *only* be started by a manual operation
}

