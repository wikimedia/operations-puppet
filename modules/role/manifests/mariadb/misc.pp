# miscellaneous services clusters
class role::mariadb::misc {

    system::role { 'mariadb::core':
        description => 'Misc DB Server',
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::passwords::misc::scripts
    include ::profile::mariadb::misc
}
