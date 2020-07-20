# Zarcillo db (tendril replacement)
class role::mariadb::misc::zarcillo {

    system::role { 'mariadb::zarcillo':
        description => 'zarcillo database server',
    }

    $section = 'zarcillo'

    include ::profile::standard
    include ::profile::base::firewall
    ::profile::mariadb::ferm { $section: }

    include ::profile::mariadb::misc::tendril
    ::profile::mariadb::section { $section: }
    ::profile::mariadb::replication_lag { $section: }
}
