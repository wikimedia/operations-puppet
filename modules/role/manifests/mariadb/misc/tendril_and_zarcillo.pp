# tendril.wikimedia.org db
class role::mariadb::misc::tendril_and_zarcillo {

    system::role { 'mariadb::tendril':
        description => 'tendril and zarcillo database server',
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::base::firewall::log
    ::profile::mariadb::ferm { 'tendril': }

    include ::profile::mariadb::misc::tendril
    include ::profile::mariadb::backup::check
}
