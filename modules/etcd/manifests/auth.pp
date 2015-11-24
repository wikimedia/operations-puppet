# === Class etcd::auth
# Enables authentication and ACLs on an etcd cluster.
# Should be applied to a single host, as there is no need
# for redundance of this class.
#
#
class etcd::auth {
    require ::etcd::auth::common

    file { '/etc/etcd/local/':
        ensure => directory,
        owner  => 'root',
        group  => 'root'
    }

    # Overrides the global config to run locally
    # as auth should be enabled on every node of the cluster
    etcd::client::config { '/etc/etcd/local/etcdrc':
        settings => {
            host       => $::fqdn,
            srv_domain => '',
        },
    }

    $cmd_base = '/usr/local/bin/etcd-manage --configdir /etc/etcdrc/local'
    if $::etcd::auth::common::active {
        # Enable auth locally
        # Note: this will fail until someone applies etcd::auth:users somewhere
        exec { 'Etcd enable auth':
            command => "${cmd_base} user get root && ${cmd_base} auth enable",
            unless  => "${cmd_base} auth status | grep -q true",
        }
    } else {
        exec { 'Etcd disable auth':
            cmd    => "${cmd_base} auth disable",
            unless => "${cmd_base} auth status | grep -q false",
        }
    }
}
