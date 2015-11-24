# === Class etcd::auth
# Enables authentication and ACLs on an etcd cluster.
# Should be applied to a single host, as there is no need
# for redundance of this class.
#
#
class etcd::auth {
    require ::etcd::auth::common

    if $::etcd::auth::common::active {
        exec { 'Etcd enable auth':
            command     => '/usr/local/bin/etcd-manage user get root && /usr/local/bin/etcd-manage auth enable',
            unless      => '/usr/local/bin/etcd-manage auth status | grep -q enabled',
        }
    } else {
        exec { 'Etcd disable auth':
            cmd    => '/usr/local/bin/etcd-manage auth disable',
            unless => '/usr/local/bin/etcd-manage auth status | grep -q disabled',
        }
    }
}
