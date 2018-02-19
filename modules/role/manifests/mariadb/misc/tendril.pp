# tendril.wikimedia.org db
class role::mariadb::misc::tendril {

    system::role { 'mariadb::tendril':
        description => 'tendril database server',
    }

    include ::standard
    include ::profile::base::firewal
    include ::profile::mariadb::ferm

    include ::profile::mariadb::misc::tendril
}
