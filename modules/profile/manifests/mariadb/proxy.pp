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
    String $pid                                                            = lookup('profile::mariadb::proxy::pid', {'default_value' => '/run/haproxy/haproxy.pid'}),
    String $socket                                                         = lookup('profile::mariadb::proxy::socket', {'default_value' => '/run/haproxy/haproxy.sock'}),
    Enum['internal', 'misc', 'cloud', 'cloud+lists', 'disabled'] $firewall = lookup('profile::mariadb::proxy::firewall', {'default_value' => 'internal'})
    ){

    class { 'haproxy':
        template => 'profile/mariadb/proxy/db.cfg.erb',
        pid      => $pid,
        socket   => $socket,
    }

    if $firewall == 'internal' {
        include ::profile::firewall
        ::profile::mariadb::firewall { 'dbproxy': }
    } elsif $firewall == 'misc' {
        include ::profile::firewall
        ::profile::mariadb::firewall { 'dbproxy': }
        include ::profile::mariadb::ferm_misc
    } elsif $firewall == 'cloud' {
        include ::profile::firewall
        ::profile::mariadb::firewall { 'dbproxy': }
        include ::profile::mariadb::ferm_wmcs
    } elsif $firewall == 'cloud+lists' {
        include ::profile::firewall
        ::profile::mariadb::firewall { 'dbproxy': }
        include ::profile::mariadb::ferm_wmcs
        include ::profile::mariadb::ferm_lists
        include ::profile::mariadb::ferm_idm
    }
}
