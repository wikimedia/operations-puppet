# idp_test db
class role::mariadb::misc::idp_test {

    system::role { 'mariadb::misc::idp_test':
        description => 'ipd-test database server',
    }

    include profile::standard
    include profile::base::firewall

    include profile::mariadb::misc::idp_test
}
