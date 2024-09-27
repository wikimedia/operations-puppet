# testreduce, nodejs-based - T257906
class role::parsoid::testreduce {
    include profile::base::production
    include profile::firewall

    include profile::nginx
    include profile::parsoid::testing
    include profile::parsoid::testreduce

    include profile::parsoid::rt_client
    include profile::parsoid::rt_server

    include profile::tlsproxy::envoy # TLS termination

    class { 'profile::mariadb::generic_server':
        datadir => '/srv/data/mysql',
    }
}
