# === Class etcd::auth
# Enables authentication and ACLs on an etcd cluster.
# Should be applied to a single host, as there is no need
# for redundance of this class.
#
#
class etcd::auth(
    $root_password,
    $active = true,
    ) {

    # Require the global etcd config file
    require ::etcd::client::globalconfig

    file { '/usr/local/bin/etcdctl-manage':
        ensure => present,
        owner  => 'root',
        group  => 'ops',
        mode   => '0550',
        source => 'puppet:///modules/etcd/etcd-manage',
    }

    # specific configuration for the root user, basically
    # just the credentials.
    etcd::client_config { '/root/.etcdrc':
        settings => {
            username => 'root',
            password => $root_password,
        }
    }

    if $active {
        etcd_user { 'root':
            password => $root_password,
            roles    => ['root'],
            require  => Etcd::Client::Config['/root/.etcdrc']
        }

        # Guests should be read-only
        etcd_role { 'guest':
            ensure => present,
            acls   => {
                '*' => 'R',
            },
        }


        exec { 'Etcd enable auth':
            cmd         => '/usr/local/bin/etcd-manage auth enable',
            unless      => '/usr/local/bin/etcd-manage auth status | grep -q enabled',
            refreshonly => true,
            subscribe   => User['etcd root']
        }
    } else {
        exec { 'Etcd disable auth':
            cmd    => '/usr/local/bin/etcd-manage auth disable',
            unless => '/usr/local/bin/etcd-manage auth status | grep -q disabled',
        }

        etcd_user { 'root':
            ensure  => absent,
            require => Exec['Etcd disable auth'],
        }
    }

}
