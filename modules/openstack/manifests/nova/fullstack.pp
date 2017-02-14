class openstack::nova::fullstack {

    include passwords::openstack::nova
    $fullstack_pass = $passwords::openstack::nova::osstackcanary_pass

    group { 'osstackcanary':
        ensure => present,
        name   => 'osstackcanary',
    }

    user { 'osstackcanary':
        ensure     => present,
        gid        => 'osstackcanary',
        shell      => '/bin/false',
        home       => '/var/lib/osstackcanary',
        managehome => true,
        system     => true,
        require    => Group['osstackcanary'],
    }

    file { '/usr/local/sbin/nova-fullstack':
        ensure => present,
        mode   => '0755',
        owner  => 'osstackcanary',
        group  => 'osstackcanary',
        source => 'puppet:///modules/openstack/nova_fullstack_test.py',
    }

    file { '/var/lib/osstackcanary/osstackcanary_id':
        ensure => present,
        mode   => '0600',
        owner  => 'osstackcanary',
        group  => 'osstackcanary',
        content => secret('nova/osstackcanary'),
    }

    file { '/etc/init/nova-fullstack.conf':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        content => template('openstack/initscripts/nova-fullstack.upstart.erb'),
    }

    base::service_unit { 'nova-fullstack':
        ensure    => present,
        upstart   => true,
        subscribe => File['/etc/init/nova-fullstack.conf'],
    }
}
