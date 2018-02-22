# tendril.wikimedia.org db
class role::mariadb::misc::tendril {

    system::role { 'mariadb::tendril':
        description => 'tendril database server',
    }

    include ::standard
    ::profile::base::firewall { 'tendril': }
    include ::profile::mariadb::ferm

    include ::profile::mariadb::misc::tendril
}
