# [*password*]
#  password for fullstack test user (same across backends)
#
# [*interval*]
#  seconds between fullstack test runs

class openstack::nova::fullstack::service(
    $active,
    $password,
    $region,
    $interval = 300,
    $max_pool = 7,
    $creation_timeout = 900,
    $ssh_timeout = 900,
    $puppet_timeout = 900,
    $keyfile = '/var/lib/osstackcanary/osstackcanary_id',
    ) {

    group { 'osstackcanary':
        ensure => 'present',
        name   => 'osstackcanary',
    }

    user { 'osstackcanary':
        ensure     => 'present',
        gid        => 'osstackcanary',
        shell      => '/bin/false',
        home       => '/var/lib/osstackcanary',
        managehome => true,
        system     => true,
        require    => Group['osstackcanary'],
    }

    file { '/usr/local/sbin/nova-fullstack':
        ensure => 'present',
        mode   => '0755',
        owner  => 'osstackcanary',
        group  => 'osstackcanary',
        source => 'puppet:///modules/openstack/nova/fullstack/nova_fullstack_test.py',
    }

    file { $keyfile:
        ensure    => 'present',
        mode      => '0600',
        owner     => 'osstackcanary',
        group     => 'osstackcanary',
        content   => secret('nova/osstackcanary'),
        show_diff => false,
    }

    file { '/etc/init/nova-fullstack.conf':
        ensure  => 'present',
        mode    => '0544',
        owner   => 'root',
        group   => 'root',
        content => template('openstack/initscripts/nova-fullstack.upstart.erb'),
    }

    service { 'nova-fullstack':
        ensure  => $active,
        require => File['/etc/init/nova-fullstack.conf'],
    }
}
