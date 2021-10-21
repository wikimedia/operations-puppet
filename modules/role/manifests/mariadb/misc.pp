# miscellaneous services clusters
class role::mariadb::misc {

    system::role { 'mariadb::core':
        description => 'Misc DB Server',
    }

    include ::profile::base::production
    include ::profile::base::firewall
    include ::profile::mariadb::misc
}
