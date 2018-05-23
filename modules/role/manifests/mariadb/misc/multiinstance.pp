# miscellaneous services clusters
class role::mariadb::misc {

    system::role { 'mariadb::misc':
        description => "Misc Services Multiinstance Database",
    }

    include ::standard
    include ::profile::mariadb::monitor
    include ::passwords::misc::scripts
    include ::profile::base::firewall

    include ::profile::mariadb::misc::multiinstance
}

