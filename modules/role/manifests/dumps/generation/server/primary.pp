class role::dumps::generation::server::primary {
    system::role { 'dumps::generation::server': description => 'Primary NFS server of dumps generation filesystem to dumps producer hosts' }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::dumps::generation::server::primary
    include ::profile::dumps::generation::server::rsync
    include ::profile::dumps::rsyncer_peer
    include ::profile::dumps::nfs
    include ::profile::dumps::generation::server::cleanup
    include ::profile::dumps::generation::server::jobswatcher
}
