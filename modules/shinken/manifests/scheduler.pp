# Class: shinken::scheduler
#
# Install, configure and ensure running for shinken scheduler daemon
#
# Parameters:
#   $scheduler_name
#       Name of the daemon. Defaults to fqdn
#   $listen_address
#       The address this daemon should be listening on
class shinken::scheduler(
    $scheduler_name = $::fqdn,
    $listen_address = $::ipaddress,
){
    shinken::daemon { "scheduler-${scheduler_name}":
        daemon         => 'scheduler',
        port           => 7768,
        listen_address => $listen_address,
        conf_file      => '/etc/shinken/daemons/schedulerd.ini'
    }
}
