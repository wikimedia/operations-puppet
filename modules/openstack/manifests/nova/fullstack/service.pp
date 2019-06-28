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
    $max_pool = 11,
    $creation_timeout = 900,
    $ssh_timeout = 900,
    $puppet_timeout = 900,
    $keyfile = '/var/lib/osstackcanary/osstackcanary_id',
    $network = '',
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

    $ensure = $active ? {
        true    => 'present',
        default => 'absent',
    }

    file { '/usr/local/bin/nova-fullstack':
        ensure  => 'present',
        mode    => '0544',
        owner   => 'root',
        group   => 'root',
        content => template('openstack/initscripts/nova-fullstack.erb'),
    }

    systemd::service { 'nova-fullstack':
        ensure  => $ensure,
        content => systemd_template('nova-fullstack'),
        restart => true,
        require => [
                    File['/usr/local/bin/nova-fullstack'],
                    ],
    }
}
