# [*password*]
#  password for fullstack test user (same across backends)
#
# [*interval*]
#  seconds between fullstack test runs

class openstack::nova::fullstack::service(
    Boolean $active,
    String[1] $password,
    String[1] $region,
    String[1] $puppetmaster,
    Stdlib::IP::Address $bastion_ip,
    Integer[1] $interval = 300,
    Integer[1] $max_pool = 11,
    Integer[1] $creation_timeout = 900,
    Integer[1] $ssh_timeout = 900,
    Integer[1] $puppet_timeout = 900,
    Stdlib::Unixpath $keyfile = '/var/lib/osstackcanary/osstackcanary_id',
    String $network = '',
    String $deployment = '',
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

    # Cleanup outfile only on acvive=false, since on active=true the file gets created by the nova-fullstack service.
    if !$active {
      file {'/var/lib/prometheus/node.d/novafullstack.prom':
          ensure => absent
      }
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
        ensure    => $ensure,
        content   => systemd_template('nova-fullstack'),
        restart   => true,
        require   => [
            File['/usr/local/bin/nova-fullstack'],
            File['/usr/local/sbin/nova-fullstack'],
        ],
        subscribe => [
            File['/usr/local/bin/nova-fullstack'],
            File['/usr/local/sbin/nova-fullstack'],
        ],
    }
}
