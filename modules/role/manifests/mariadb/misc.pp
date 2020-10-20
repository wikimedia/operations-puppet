# miscellaneous services clusters
class role::mariadb::misc {

    system::role { 'mariadb::core':
        description => 'Misc DB Server',
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::mariadb::misc
}
