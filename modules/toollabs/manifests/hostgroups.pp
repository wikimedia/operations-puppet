# Manage hostgroup lists on NFS

class toollabs::hostgroups($groups = undef) {

    gridengine::join { "hostgroups-${::fqdn}":
        sourcedir => "${toollabs::collectors}/hostgroups",
    }
}
