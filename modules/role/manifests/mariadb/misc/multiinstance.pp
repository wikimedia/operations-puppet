# miscellaneous services clusters
class role::mariadb::misc::multiinstance {

    system::role { 'mariadb::misc':
        description => 'Misc Services Multiinstance Databases',
    }

    include ::standard
    include ::profile::mariadb::monitor
    include ::profile::base::firewall

    include ::profile::mariadb::misc::multiinstance
}

