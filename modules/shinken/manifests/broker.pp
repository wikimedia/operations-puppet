# Class: shinken::broker
#
# Install, configure and ensure running for shinken broker daemon
#
# Parameters:
#   $broker_name
#       Name of the daemon. Defaults to fqdn
#   $listen_address
#       The address this daemon should be listening on
class shinken::broker(
    $broker_name    = $::fqdn,
    $listen_address = $::ipaddress,
) {
    shinken::daemon { "broker-${broker_name}":
        daemon         => 'broker',
        port           => 7772,
        listen_address => $listen_address,
        conf_file      => '/etc/shinken/daemons/brokerd.ini',
    }
}
