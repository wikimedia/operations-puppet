# sets up the ping offload servers - T190090
class role::ping_offload {

    system::role { 'ping_offload': description => 'Ping offload server' }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::ping_offload
}
