# sets up the ping offload servers - T190090
class role::ping_offload {
    include profile::base::production
    include profile::firewall
    include profile::ping_offload
}
