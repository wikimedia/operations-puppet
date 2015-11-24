# === Class etcd::auth
# Creates the basic root user and turns on auth if not present
#
class etcd::auth(
    $root_password,
    $active = true,
    ) {
    require_package 'etcd'

    file { '/usr/local/bin/etcdctl-manage':
        ensure => present,
        owner  => 'root',
        group  => 'ops',
        mode   => '0550',
        source => 'puppet:///modules/etcd/etcd-manage',
    }

    if $active {
        etcd_user { 'root':
            password => $root_password,
            roles    => ['root'],
        }

        exec { 'Etcd enable auth':
            cmd         => "/usr/local/bin/etcdctl-manage auth enable",
            refreshonly => true,
            subscribe   => User['etcd root']
        }
    } else {
        exec { 'Etcd disable auth':
            cmd    => "/usr/local/bin/etcdctl-manage auth disable",
            unless => "/usr/local/bin/etcdctl-manage  user list | grep -q root"
        }

        etcd_user { 'etcd root':
            ensure   => absent,
            name     => 'root',
            params   => $etcdctl_args,
        }
    }
}
