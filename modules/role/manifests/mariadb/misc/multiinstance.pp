# miscellaneous services clusters
class role::mariadb::misc::multiinstance {

    system::role { 'mariadb::misc':
        description => 'Misc Services Multiinstance Databases',
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::base::firewall::log

    include ::profile::mariadb::misc::multiinstance
}

