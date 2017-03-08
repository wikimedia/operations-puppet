# For deploying the basic software config without participating in the full
# role for e.g. public addrs, monitoring, authdns-update, etc.
class role::authdns::testns {
    include role::authdns::data
    class { 'authdns::ns':
        gitrepo            => $role::authdns::data::gitrepo,
        monitoring         => false,
    }
}
