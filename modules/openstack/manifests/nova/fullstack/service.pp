# [*password*]
#  password for fullstack test user (same across backends)
#
# [*interval*]
#  seconds between fullstack test runs

class openstack::nova::fullstack::service(
    Boolean                                 $active,
    String[1]                               $password,
    String[1]                               $region,
    Stdlib::IP::Address::V4::Nosubnet       $bastion_ip,
    String                                  $network,
    String[1]                               $deployment,
    Array[Stdlib::IP::Address::Nosubnet, 1] $resolvers,
    Integer[1]                              $interval = 300,
    Integer[1]                              $max_pool = 11,
    Integer[1]                              $creation_timeout = 900,
    Integer[1]                              $ssh_timeout = 900,
    Integer[1]                              $puppet_timeout = 900,
    Stdlib::Unixpath                        $keyfile = '/var/lib/osstackcanary/osstackcanary_id',
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

    $nova_fullstack_git_clone_dir = '/srv/git/nova_fullstack_test'
    wmflib::dir::mkdir_p($nova_fullstack_git_clone_dir)

    git::clone { 'nova_fullstack_git_clone':
        ensure    => latest,
        origin    => 'https://gitlab.wikimedia.org/repos/cloud/cloud-vps/nova_fullstack_test',
        directory => $nova_fullstack_git_clone_dir,
        branch    => 'main',
    }

    $nova_fullstack_file_src = "${nova_fullstack_git_clone_dir}/nova_fullstack_test/nova_fullstack_test.py"

    file { '/usr/local/sbin/nova-fullstack':
        ensure  => 'link',
        owner   => 'osstackcanary',
        group   => 'osstackcanary',
        source  => $nova_fullstack_file_src,
        require => Git::Clone['nova_fullstack_git_clone'],
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
            Git::Clone['nova_fullstack_git_clone'],
        ],
    }
}
