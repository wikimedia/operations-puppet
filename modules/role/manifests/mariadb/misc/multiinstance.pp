# miscellaneous services clusters
class role::mariadb::misc::multiinstance {
    include profile::base::production
    include profile::firewall

    include profile::mariadb::misc::multiinstance
}

