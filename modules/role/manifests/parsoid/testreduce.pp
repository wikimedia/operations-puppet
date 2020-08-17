# testreduce, nodejs-based - T257906
class role::parsoid::testreduce {

    system::role { 'parsoid::testreduce':
        description => 'Parsoid visual diffing tests'
    }

    include ::profile::standard
    include ::profile::base::firewall

    include ::profile::parsoid::testing

    include ::profile::parsoid::vd_client
    include ::profile::parsoid::vd_server

    include ::profile::parsoid::rt_client
    include ::profile::parsoid::rt_server
}
