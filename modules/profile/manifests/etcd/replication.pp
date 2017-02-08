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
    $accounts = hiera('profile::etcd::tlsproxy::accounts')
) {
    # Replica is always from remote to local. This means only the local account
    # is needed.
    Etcdmirror::Instance {
        dst        => "https://root:${accounts['root']}@${::fqdn}:2379",
    }

    unless ($sources == {}) {
        $titles = keys($sources)
        etcdmirror::instance { $titles:
            sources => $sources,
        }
    }
}
