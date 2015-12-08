# Class: shinken::receiver
#
#    receiver_name   <%= @receiver_name %>
#    address         <%= @listen_address %>
#
#    timeout             3   ; Ping timeout
#    data_timeout        120 ; Data send timeout
#    max_check_attempts  3   ; If ping fails N or more, then the node is dead
#    check_interval      60  ; Ping node every N seconds
# Install, configure and ensure running for shinken receiver daemon
class shinken::receiver(
    $receiver_name       = $::fqdn,
    $listen_address      = $::ipaddress,
    $spare               = 0,
    $realm               = 'All',
    $timeout             = 3,
    $data_timeout        = 120,
    $max_check_attempts  = 3,
    $check_interval      = 60,
    $modules             = [],
){
    shinken::daemon { "receiver-${::fqdn}":
        daemon      => 'receiver',
        port        => 7773,
        conf_file   => '/etc/shinken/daemons/receiverd.ini',
    }
}
