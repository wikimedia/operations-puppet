# == Class profile::etcd::replication
#
# Run replication from remote clusters to the local one.
#
# == Parameters
#
# [*sources*] Hash with information on the destination in the form:
#   { path@clustername => "https://hostname.example.com:2379"}
class profile::etcd::replication(
    $sources = hiera('profile::etcd::replication::sources'),
) {
    # Replica is always from remote to local
    Etcdmirror::Instance {
        dst        => "https://${::fqdn}:2379",
    }

    if $sources != {} {
        etcd::instance { keys($sources):
            sources => $sources,
        }
    }
}
