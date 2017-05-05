# Manage queues lists on NFS

class toollabs::queues($queues = undef) {

    gridengine::join { "queues-${::fqdn}":
        sourcedir => "${toollabs::collectors}/queues",
    }
}
