# Class: shinken::reactionner
#
# Install, configure and ensure running for shinken reactionner daemon
#
# Parameters:
#   $reactionner_name
#       Name of the daemon. Defaults to fqdn
#   $listen_address
#       The address this daemon should be listening on
class shinken::reactionner(
    $reactionner_name = $::fqdn,
    $listen_address   = $::ipaddress,
) {
    shinken::daemon { "reactionner-${reactionner_name}":
        daemon         => 'reactionner',
        port           => 7769,
        listen_address => $listen_address,
        conf_file      => '/etc/shinken/daemons/reactionnerd.ini',
    }
}
