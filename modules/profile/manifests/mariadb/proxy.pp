# base profile to have a manually-managed haproxy installation, pointing to
# to nowere by default. Check ::profile::mariadb::proxy::{master,replica} for
# it to do something useful (failover or load balancing)
class profile::mariadb::proxy (
    $pid    = hiera('::profile::mariadb::proxy::pid', '/run/haproxy/haproxy.pid'),
    $socket = hiera('::profile::mariadb::proxy::socket', '/run/haproxy/haproxy.sock'),
    ){

    class { 'haproxy':
        template => 'profile/mariadb/proxy/db.cfg.erb',
        pid      => $pid,
        socket   => $socket,
    }

    if $socket == '/run/haproxy/haproxy.sock' or $socket == '/run/haproxy/haproxy.pid' {
        file { '/run/mysqld':
            ensure => directory,
            mode   => '0775',
            owner  => 'root',
            group  => 'haproxy',
        }
    }

    package { [
        'mysql-client',
        'percona-toolkit',
    ]:
        ensure => present,
    }
}
