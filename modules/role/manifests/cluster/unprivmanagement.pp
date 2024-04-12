# === Class role::cluster::unprivmanagement
#
# This role sets up a host to be a cluster manager for unprivileged
# users
#
class role::cluster::unprivmanagement {
    include profile::base::production
    include profile::firewall

    include profile::cumin::unprivmaster
}
