# === Class role::cluster::unprivmanagement
#
# This role sets up a host to be a cluster manager for unprivileged
# users
#
class role::cluster::unprivmanagement {

    system::role { 'unpriv-cluster-management':
        description => 'Unprivileged cluster management',
    }

    include profile::standard
    include profile::base::firewall

    include profile::cumin::unprivmaster
}
