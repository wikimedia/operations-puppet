# miscellaneous services clusters
class role::mariadb::misc::multiinstance {

    system::role { 'mariadb::misc::multiinstance':
        description => 'Misc Services Multiinstance Databases',
    }

    include ::profile::base::production
    include ::profile::base::firewall

    include ::profile::mariadb::misc::multiinstance
}

