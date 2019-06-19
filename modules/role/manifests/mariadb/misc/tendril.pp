# tendril.wikimedia.org db
class role::mariadb::misc::tendril {

    system::role { 'mariadb::tendril':
        description => 'tendril database server',
    }

    include ::profile::standard
    include ::profile::base::firewall
    ::profile::mariadb::ferm { 'tendril': }

    include ::profile::mariadb::misc::tendril
}
