# Class: shinken::receiver
#
# Install, configure and ensure running for shinken receiver daemon
#
# Parameters:
#   $receiver_name
#       Name of the daemon. Defaults to fqdn
#   $listen_address
#       The address this daemon should be listening on
class shinken::receiver(
    $receiver_name       = $::fqdn,
    $listen_address      = $::ipaddress,
){
    shinken::daemon { "receiver-${receiver_name}":
        daemon         => 'receiver',
        port           => 7773,
        listen_address => $listen_address,
        conf_file      => '/etc/shinken/daemons/receiverd.ini',
    }
}
