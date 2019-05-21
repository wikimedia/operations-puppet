# base profile to have a manually-managed haproxy installation, pointing to
# to nowere by default. Check ::profile::mariadb::proxy::{master,replica} for
# it to do something useful (failover or load balancing)
# * pid: full path of the pid passed to haproxy to control running process
# * socket: full path of the socket passed to haproxy to connect without tcp
# * firewall: controls the firewall, the options are:
#   - 'disabled': no firewall is setup
#   - 'cloud': firewall with holes to cloud network for cloud production services
#   - 'misc': firewall with holes to misc services: rt, librenms, gerrit
#   - 'internal': firewall only to the internal network (10.x hosts)
class profile::mariadb::proxy (
    $pid      = hiera('profile::mariadb::proxy::pid', '/run/haproxy/haproxy.pid'),
    $socket   = hiera('profile::mariadb::proxy::socket', '/run/haproxy/haproxy.sock'),
    $firewall = hiera('profile::mariadb::proxy::firewall', 'internal')
    ){

    class { 'haproxy':
        template => 'profile/mariadb/proxy/db.cfg.erb',
        pid      => $pid,
        socket   => $socket,
    }

    if $firewall == 'internal' {
        include ::profile::base::firewall
        include ::profile::base::firewall::log
        ::profile::mariadb::ferm { 'dbproxy': }
    } elsif $firewall == 'misc' {
        include ::profile::base::firewall
        include ::profile::base::firewall::log
        ::profile::mariadb::ferm { 'dbproxy': }
        include ::profile::mariadb::ferm_misc
    } elsif $firewall == 'cloud' {
        include ::profile::base::firewall
        include ::profile::base::firewall::log
        ::profile::mariadb::ferm { 'dbproxy': }
        include ::profile::mariadb::ferm_wmcs
    } elsif $firewall != 'disabled' {
        fail('profile::mariadb::proxy::firewall can only be internal, misc, cloud or disabled.')
    }
}
